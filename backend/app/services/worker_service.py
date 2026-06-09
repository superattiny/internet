# ================================================
# services/worker_service.py — Ishchilar biznes logikasi
#
# Tarkib:
#   1. Ishchi yaratish (Admin only)
#   2. Ishchi o'qish — bitta / ro'yxat
#   3. Ishchi ma'lumotlarini yangilash
#   4. Ishchini faolsizlantirish (o'chirmasdan bloklash)
#   5. Komisyon hisoblash + usta balansiga qo'shish
#      + kassadan chiqim yozish  ← 3-qoida
#   6. Ish haqi to'lash + balansdan ayirish + kassaga chiqim
#   7. Balansni qo'lda to'g'irlash (bonus/jarima)
#   8. Ishchi balans tarixi (komisyon + to'lovlar)
#   9. Barcha ustalar umumiy statistikasi
# ================================================

import math
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func, and_

from app.database.models import (
    User, UserRole,
    Order, OrderStatus,
    SalaryPayment, PaymentMethod,
    FinanceTransaction, TransactionType,
    ShopSettings,
)
from app.schemas.worker import (
    WorkerCreateRequest,
    WorkerUpdateRequest,
    SalaryPaymentRequest,
    BalanceAdjustRequest,
    WorkerResponse,
    WorkerListResponse,
    CommissionDetailResponse,
    SalaryPaymentHistoryResponse,
    WorkerBalanceHistoryResponse,
    SalaryPaymentResponse,
    CommissionEventResponse,
)
from app.utils.auth import hash_password
from app.utils.logger import logger


# ================================================================
#  YORDAMCHI: User → WorkerResponse (statistika bilan)
# ================================================================

async def _build_worker_response(
    db: AsyncSession,
    user: User,
) -> WorkerResponse:
    """
    User ob'ektini WorkerResponse ga o'giradi.
    Qo'shimcha: DB dan statistika hisoblanadi.
    """
    # Jami bitirgan zakazlar soni (DELIVERED holati, ushbu usta)
    done_result = await db.execute(
        select(func.count(Order.id)).where(
            and_(
                Order.master_id == user.id,
                Order.status == OrderStatus.DELIVERED,
            )
        )
    )
    total_orders_done = done_result.scalar_one() or 0

    # Jami ishlab topilgan komisyon (barcha zakazlardan)
    earned_result = await db.execute(
        select(func.coalesce(func.sum(Order.master_commission), 0.0)).where(
            and_(
                Order.master_id == user.id,
                Order.master_commission > 0,
            )
        )
    )
    total_earned = float(earned_result.scalar_one())

    # Jami to'lab berilgan (SalaryPayment jadvali)
    paid_result = await db.execute(
        select(func.coalesce(func.sum(SalaryPayment.amount), 0.0)).where(
            SalaryPayment.worker_id == user.id
        )
    )
    total_paid_out = float(paid_result.scalar_one())

    return WorkerResponse(
        id=user.id,
        full_name=user.full_name,
        username=user.username,
        phone=user.phone,
        role=user.role,
        is_active=user.is_active,
        balance=user.balance,
        commission_percent=user.commission_percent,
        salary_rate=user.salary_rate,
        total_orders_done=total_orders_done,
        total_earned=total_earned,
        total_paid_out=total_paid_out,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


# ================================================================
#  YORDAMCHI: Kassa (ShopSettings) balansini yangilash
# ================================================================

async def _get_or_create_shop(db: AsyncSession) -> ShopSettings:
    """ShopSettings ni qaytaradi, yo'q bo'lsa yaratadi"""
    result = await db.execute(select(ShopSettings))
    shop = result.scalar_one_or_none()
    if not shop:
        shop = ShopSettings()
        db.add(shop)
        await db.flush()
    return shop


# ================================================================
#  1. ISHCHI YARATISH
# ================================================================

async def create_worker(
    db: AsyncSession,
    data: WorkerCreateRequest,
    created_by: User,
) -> tuple[Optional[WorkerResponse], Optional[str]]:
    """
    Yangi usta yoki operator yaratadi.

    Tekshiruvlar:
      - Username band emasligini tekshiradi
      - Admin rolini yaratishga yo'l qo'ymaydi (schema'da ham tekshiriladi)

    Returns:
        (WorkerResponse, None)   — muvaffaqiyatli
        (None, "xato sababi")    — xatolik
    """
    # Username band emasligini tekshirish
    existing = await db.execute(
        select(User).where(User.username == data.username)
    )
    if existing.scalar_one_or_none():
        return None, f"'{data.username}' username allaqachon band"

    worker = User(
        full_name=data.full_name,
        username=data.username,
        hashed_password=hash_password(data.password),
        phone=data.phone,
        role=data.role,
        commission_percent=data.commission_percent,
        salary_rate=data.salary_rate,
        balance=0.0,
        is_active=True,
    )
    db.add(worker)
    await db.commit()
    await db.refresh(worker)

    logger.info(
        f"👤 Yangi ishchi yaratildi: {worker.full_name} "
        f"(username={worker.username}, rol={worker.role.value}, "
        f"komisyon={worker.commission_percent}%) | "
        f"Kim yaratdi: {created_by.username}"
    )

    return await _build_worker_response(db, worker), None


# ================================================================
#  2. ISHCHI O'QISH — BITTA
# ================================================================

async def get_worker_by_id(
    db: AsyncSession,
    worker_id: int,
) -> Optional[WorkerResponse]:
    """ID bo'yicha ishchini topadi (statistika bilan)"""
    result = await db.execute(
        select(User).where(User.id == worker_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        return None
    return await _build_worker_response(db, user)


# ================================================================
#  3. ISHCHILAR RO'YXATI
# ================================================================

async def get_workers_list(
    db: AsyncSession,
    role: Optional[UserRole] = None,
    is_active: Optional[bool] = None,
    page: int = 1,
    page_size: int = 50,
) -> WorkerListResponse:
    """
    Ishchilar ro'yxati — filtrlash bilan.
    Admin ko'radi: barcha ishchilar
    Operator ko'radi: faqat ustalar ro'yxati

    Filtrlar:
      role      — master / operator
      is_active — faol / bloklangan
    """
    base_q = select(User).where(User.role != UserRole.ADMIN)

    if role:
        base_q = base_q.where(User.role == role)
    if is_active is not None:
        base_q = base_q.where(User.is_active == is_active)

    # Jami soni
    count_result = await db.execute(
        select(func.count()).select_from(base_q.subquery())
    )
    total = count_result.scalar_one()

    # Sahifalash
    offset = (page - 1) * page_size
    paginated = base_q.order_by(User.full_name.asc()).offset(offset).limit(page_size)
    result = await db.execute(paginated)
    users = result.scalars().all()

    # Ustalar va operatorlar sonini alohida hisoblaymiz
    masters_r = await db.execute(
        select(func.count(User.id)).where(
            and_(User.role == UserRole.MASTER, User.is_active == True)
        )
    )
    operators_r = await db.execute(
        select(func.count(User.id)).where(
            and_(User.role == UserRole.OPERATOR, User.is_active == True)
        )
    )

    items = [await _build_worker_response(db, u) for u in users]

    return WorkerListResponse(
        items=items,
        total=total,
        masters=masters_r.scalar_one(),
        operators=operators_r.scalar_one(),
    )


# ================================================================
#  4. ISHCHI MA'LUMOTLARINI YANGILASH
# ================================================================

async def update_worker(
    db: AsyncSession,
    worker_id: int,
    data: WorkerUpdateRequest,
    updated_by: User,
) -> tuple[Optional[WorkerResponse], Optional[str]]:
    """
    Ishchi ma'lumotlarini yangilaydi (PATCH).
    commission_percent o'zgarganda log yoziladi.
    """
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()

    if not worker:
        return None, "Ishchi topilmadi"

    if worker.role == UserRole.ADMIN:
        return None, "Admin ma'lumotlarini bu endpoint orqali o'zgartirish mumkin emas"

    update_data = data.model_dump(exclude_unset=True)

    # Komisyon foizi o'zgarsa — alohida log
    if "commission_percent" in update_data:
        old_pct = worker.commission_percent
        new_pct = update_data["commission_percent"]
        logger.info(
            f"💱 Komisyon foizi o'zgardi: {worker.full_name} | "
            f"{old_pct}% → {new_pct}% | "
            f"Kim o'zgartirdi: {updated_by.username}"
        )

    for field, value in update_data.items():
        setattr(worker, field, value)

    await db.commit()
    await db.refresh(worker)

    logger.info(
        f"✏️  Ishchi yangilandi: {worker.full_name} | "
        f"Maydonlar: {list(update_data.keys())} | "
        f"Kim: {updated_by.username}"
    )

    return await _build_worker_response(db, worker), None


# ================================================================
#  5. KOMISYON HISOBLASH
#     Zakaz DELIVERED bo'lganda chaqiriladi (order_service ham chaqiradi)
#     Bu yerda: kassa chiqimi ham yoziladi
# ================================================================

async def apply_commission(
    db: AsyncSession,
    order: Order,
) -> Optional[CommissionEventResponse]:
    """
    Zakaz topshirilganda (DELIVERED) ustaga komisyon hisoblaydi.

    Mantiq (3-qoida):
      1. Ustaning commission_percent ni oladi
      2. Komisyon = final_price × commission_percent / 100
      3. Komisyon summasi → Ustaning balance ga QO'SHILADI
      4. Kassadan (ShopSettings.total_balance) AYIRILADI
      5. FinanceTransaction ga CHIQIM yoziladi (audit uchun)
      6. Barcha amallar commit qilinadi

    Bu funksiya order_service.process_payment ichida chaqiriladi,
    lekin worker_service orqali ham to'g'ridan-to'g'ri chaqirish mumkin.

    Returns:
        CommissionEventResponse — muvaffaqiyatli
        None                    — usta yo'q yoki komisyon 0
    """
    if not order.master_id:
        return None

    # Ustani DB dan yangi o'qiymiz (cache emas)
    master_result = await db.execute(
        select(User).where(User.id == order.master_id)
    )
    master = master_result.scalar_one_or_none()

    if not master:
        logger.warning(f"⚠️  Zakaz {order.order_number}: usta id={order.master_id} topilmadi")
        return None

    if master.commission_percent <= 0 or order.final_price <= 0:
        logger.debug(
            f"Komisyon hisoblanmadi: {order.order_number} | "
            f"foiz={master.commission_percent}% | "
            f"narx={order.final_price}"
        )
        return None

    # ── Komisyon hisoblash ────────────────────────────────────
    commission = round(order.final_price * master.commission_percent / 100, 2)

    # Eski qiymatlar (log uchun)
    old_balance = master.balance

    # ── 3a. Usta balansiga QO'SHISH ──────────────────────────
    master.balance += commission
    order.master_commission = commission

    # ── 3b. Kassadan AYIRISH ──────────────────────────────────
    shop = await _get_or_create_shop(db)
    shop.total_balance -= commission

    # ── 3c. FinanceTransaction — CHIQIM yozuvi ───────────────
    finance_entry = FinanceTransaction(
        transaction_type=TransactionType.SALARY,
        amount=commission,
        description=(
            f"Komisyon: {master.full_name} — "
            f"zakaz {order.order_number} "
            f"({master.commission_percent}% × {order.final_price:,.0f} so'm)"
        ),
        notes=f"Avtomatik hisoblangan komisyon. Zakaz: {order.order_number}",
        performed_by_id=master.id,
        order_id=order.id,
        payment_method=PaymentMethod.TRANSFER,
    )
    db.add(finance_entry)

    # ── Commit ────────────────────────────────────────────────
    await db.commit()

    logger.info(
        f"💰 Komisyon hisoblandi:\n"
        f"   Usta    : {master.full_name} (id={master.id})\n"
        f"   Zakaz   : {order.order_number}\n"
        f"   Narx    : {order.final_price:,.0f} so'm\n"
        f"   Foiz    : {master.commission_percent}%\n"
        f"   Komisyon: {commission:,.0f} so'm\n"
        f"   Balans  : {old_balance:,.0f} → {master.balance:,.0f} so'm\n"
        f"   Kassa   : -{commission:,.0f} so'm"
    )

    return CommissionEventResponse(
        worker_id=master.id,
        worker_name=master.full_name,
        order_number=order.order_number,
        final_price=order.final_price,
        commission_percent=master.commission_percent,
        commission_amount=commission,
        new_balance=master.balance,
        kassa_deducted=commission,
    )


# ================================================================
#  6. ISH HAQI TO'LASH
# ================================================================

async def pay_salary(
    db: AsyncSession,
    worker_id: int,
    data: SalaryPaymentRequest,
    paid_by: User,
) -> tuple[Optional[SalaryPaymentResponse], Optional[str]]:
    """
    Ishchiga ish haqi to'laydi.

    Mantiq:
      1. Ishchini topadi va faolligini tekshiradi
      2. To'lov summasi balansdan ko'p bo'lmasligi tekshiriladi
         (manfiy balansga yo'l qo'ymaydi)
      3. Ishchining balance dan AYIRADI
      4. SalaryPayment jadvaliga yozadi (to'lov tarixi)
      5. Kassaga CHIQIM yozadi (FinanceTransaction)

    Returns:
        (SalaryPaymentResponse, None)  — muvaffaqiyatli
        (None, "xato sababi")          — xatolik
    """
    # Ishchini topish
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()

    if not worker:
        return None, "Ishchi topilmadi"

    if not worker.is_active:
        return None, f"'{worker.full_name}' hisobi bloklangan, to'lov amalga oshirib bo'lmaydi"

    # Balans yetarliligini tekshirish
    if data.amount > worker.balance:
        return None, (
            f"Balans yetarli emas. "
            f"Joriy balans: {worker.balance:,.0f} so'm, "
            f"So'ralgan: {data.amount:,.0f} so'm"
        )

    old_balance = worker.balance

    # ── Balansdan ayirish ─────────────────────────────────────
    worker.balance -= data.amount

    # ── SalaryPayment tarixi ──────────────────────────────────
    salary_record = SalaryPayment(
        worker_id=worker.id,
        amount=data.amount,
        payment_method=data.payment_method,
        notes=data.notes,
        paid_by_id=paid_by.id,
    )
    db.add(salary_record)

    # ── Kassaga chiqim yozish ─────────────────────────────────
    finance_entry = FinanceTransaction(
        transaction_type=TransactionType.SALARY,
        amount=data.amount,
        description=f"Ish haqi: {worker.full_name}",
        notes=data.notes or f"Ish haqi to'lovi. {worker.role.value}: {worker.full_name}",
        performed_by_id=paid_by.id,
        payment_method=data.payment_method,
    )
    db.add(finance_entry)

    await db.commit()

    logger.info(
        f"💳 Ish haqi to'landi:\n"
        f"   Ishchi : {worker.full_name} (id={worker.id})\n"
        f"   Summa  : {data.amount:,.0f} so'm ({data.payment_method.value})\n"
        f"   Balans : {old_balance:,.0f} → {worker.balance:,.0f} so'm\n"
        f"   Kim to'ladi: {paid_by.username}\n"
        f"   Izoh   : {data.notes or '-'}"
    )

    return SalaryPaymentResponse(
        success=True,
        message=f"{worker.full_name}ga {data.amount:,.0f} so'm muvaffaqiyatli to'landi",
        worker_name=worker.full_name,
        amount_paid=data.amount,
        new_balance=worker.balance,
        payment_method=data.payment_method,
    ), None


# ================================================================
#  7. BALANSNI QO'LDA TO'G'IRLASH (ADMIN)
# ================================================================

async def adjust_balance(
    db: AsyncSession,
    worker_id: int,
    data: BalanceAdjustRequest,
    adjusted_by: User,
) -> tuple[Optional[WorkerResponse], Optional[str]]:
    """
    Admin ishchi balansini qo'lda o'zgartiradi (bonus / tuzatish).

    Manfiy miqdor — balansdan ayiradi (jarima / tuzatish).
    Musbat miqdor — balansga qo'shadi (bonus / to'ldirish).

    Har qanday o'zgarish FinanceTransaction ga yoziladi (audit).
    """
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()

    if not worker:
        return None, "Ishchi topilmadi"

    # Manfiy miqdor: natija balans 0 dan past bo'lmasligi tekshiriladi
    if data.amount < 0 and (worker.balance + data.amount) < 0:
        return None, (
            f"Balans manfiyga tushmaydi. "
            f"Joriy: {worker.balance:,.0f} so'm, "
            f"Ayirilmoqchi: {abs(data.amount):,.0f} so'm"
        )

    old_balance = worker.balance
    worker.balance += data.amount

    # Audit izi uchun FinanceTransaction
    t_type = TransactionType.INCOME if data.amount > 0 else TransactionType.EXPENSE
    finance_entry = FinanceTransaction(
        transaction_type=t_type,
        amount=abs(data.amount),
        description=f"Balans tuzatish: {worker.full_name} — {data.reason}",
        notes=f"Admin tomonidan qo'lda amalga oshirildi. Sabab: {data.reason}",
        performed_by_id=adjusted_by.id,
        payment_method=PaymentMethod.TRANSFER,
    )
    db.add(finance_entry)

    await db.commit()
    await db.refresh(worker)

    sign = "+" if data.amount >= 0 else ""
    logger.info(
        f"🔧 Balans tuzatildi: {worker.full_name} | "
        f"{old_balance:,.0f} → {worker.balance:,.0f} so'm "
        f"({sign}{data.amount:,.0f}) | "
        f"Sabab: {data.reason} | "
        f"Admin: {adjusted_by.username}"
    )

    return await _build_worker_response(db, worker), None


# ================================================================
#  8. ISHCHI BALANS TARIXI
# ================================================================

async def get_worker_balance_history(
    db: AsyncSession,
    worker_id: int,
) -> Optional[WorkerBalanceHistoryResponse]:
    """
    Ishchining to'liq moliyaviy tarixi:
      - Hisoblangan komisyonlar (zakaz bo'yicha)
      - To'langan ish haqlar

    Dashboard'dagi "Mening balansim" va
    Admin panelida "Ishchi hisoboti" uchun ishlatiladi.
    """
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()
    if not worker:
        return None

    # ── Komisyon tarixi ───────────────────────────────────────
    from sqlalchemy.orm import selectinload
    orders_result = await db.execute(
        select(Order)
        .options(selectinload(Order.client))
        .where(
            and_(
                Order.master_id == worker_id,
                Order.master_commission > 0,
            )
        )
        .order_by(Order.delivered_at.desc().nulls_last())
    )
    orders = orders_result.scalars().all()

    commissions = []
    total_earned = 0.0
    for o in orders:
        tv_parts = filter(None, [o.tv_brand, o.tv_model, o.tv_diagonal])
        tv_info  = " | ".join(tv_parts) or "TV ma'lumoti yo'q"

        commissions.append(CommissionDetailResponse(
            order_id=o.id,
            order_number=o.order_number,
            order_date=o.delivered_at or o.updated_at,
            final_price=o.final_price,
            commission_percent=o.master_commission / o.final_price * 100
                               if o.final_price > 0 else worker.commission_percent,
            commission_amount=o.master_commission,
            client_name=o.client.full_name if o.client else "—",
            tv_info=tv_info,
        ))
        total_earned += o.master_commission

    # ── Ish haqi tarixi ───────────────────────────────────────
    salary_result = await db.execute(
        select(SalaryPayment)
        .where(SalaryPayment.worker_id == worker_id)
        .order_by(SalaryPayment.created_at.desc())
    )
    salary_records = salary_result.scalars().all()

    salary_payments = []
    total_paid_out = 0.0

    # paid_by nomlarini bir so'rovda olamiz
    paid_by_ids = {s.paid_by_id for s in salary_records if s.paid_by_id}
    paid_by_map: dict[int, str] = {}
    if paid_by_ids:
        pb_result = await db.execute(
            select(User.id, User.full_name).where(User.id.in_(paid_by_ids))
        )
        paid_by_map = {row[0]: row[1] for row in pb_result.all()}

    for s in salary_records:
        salary_payments.append(SalaryPaymentHistoryResponse(
            id=s.id,
            amount=s.amount,
            payment_method=s.payment_method,
            notes=s.notes,
            paid_by=paid_by_map.get(s.paid_by_id) if s.paid_by_id else None,
            created_at=s.created_at,
        ))
        total_paid_out += s.amount

    return WorkerBalanceHistoryResponse(
        worker_id=worker.id,
        worker_name=worker.full_name,
        balance=worker.balance,
        commissions=commissions,
        total_earned=round(total_earned, 2),
        salary_payments=salary_payments,
        total_paid_out=round(total_paid_out, 2),
    )


# ================================================================
#  9. UMUMIY STATISTIKA (Admin dashboard uchun)
# ================================================================

async def get_workers_finance_summary(db: AsyncSession) -> dict:
    """
    Barcha ishchilar moliyaviy xulosasi.
    Admin dashboard'ining "Ishchilar" kartasida ko'rsatiladi.

    Qaytaradi:
      - total_workers    : jami faol ishchilar
      - total_balance    : barcha ishchilar balanslari yig'indisi
                           (to'lanmagan komisyon qoldig'i)
      - total_earned     : jami hisoblangan komisyonlar
      - total_paid_out   : jami to'langan ish haqlar
      - pending_payout   : hali to'lanmagan (balansda turibdi)
      - workers_detail   : har bir ishchining qisqacha holati
    """
    # Faol ishchilar (admin bundan mustasno)
    workers_result = await db.execute(
        select(User).where(
            and_(
                User.role != UserRole.ADMIN,
                User.is_active == True,
            )
        ).order_by(User.full_name)
    )
    workers = workers_result.scalars().all()

    # Yig'ma ko'rsatkichlar
    total_balance  = sum(w.balance for w in workers)

    earned_r = await db.execute(
        select(func.coalesce(func.sum(Order.master_commission), 0.0)).where(
            Order.master_commission > 0
        )
    )
    total_earned = float(earned_r.scalar_one())

    paid_r = await db.execute(
        select(func.coalesce(func.sum(SalaryPayment.amount), 0.0))
    )
    total_paid_out = float(paid_r.scalar_one())

    # Har bir ishchining qisqacha holati
    workers_detail = []
    for w in workers:
        w_done_r = await db.execute(
            select(func.count(Order.id)).where(
                and_(
                    Order.master_id == w.id,
                    Order.status == OrderStatus.DELIVERED,
                )
            )
        )
        workers_detail.append({
            "id":                 w.id,
            "full_name":          w.full_name,
            "role":               w.role.value,
            "balance":            w.balance,
            "commission_percent": w.commission_percent,
            "orders_done":        w_done_r.scalar_one(),
        })

    return {
        "total_workers":  len(workers),
        "total_balance":  round(total_balance, 2),
        "total_earned":   round(total_earned, 2),
        "total_paid_out": round(total_paid_out, 2),
        "pending_payout": round(total_balance, 2),
        "workers_detail": workers_detail,
    }
