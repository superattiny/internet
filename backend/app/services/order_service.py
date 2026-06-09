# ================================================
# services/order_service.py — Zakazlar biznes logikasi
#
# Tarkib:
#   1. Zakaz yaratish (mijoz ham avtomatik yaratiladi)
#   2. Zakaz o'qish (bitta / ro'yxat / filter)
#   3. Zakaz ma'lumotlarini yangilash
#   4. Status o'zgartirish + tarix yozish (MAJBURIY)
#   5. To'lov qabul qilish
#   6. Deadline alert — muddati o'tgan/yaqinlashgan zakazlar
#   7. Statistika (dashboard uchun)
# ================================================

from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func, and_, or_
from sqlalchemy.orm import selectinload

from app.database.models import (
    Order, OrderStatus, OrderSource, PaymentMethod,
    OrderStatusHistory, Client, User, ShopSettings,
    FinanceTransaction, TransactionType,
)
from app.schemas.order import (
    OrderCreateRequest,
    OrderUpdateRequest,
    OrderStatusUpdateRequest,
    OrderPaymentRequest,
    OrderResponse,
    OrderListResponse,
    OrderDeadlineAlertResponse,
    OrderStatsResponse,
    ClientShortResponse,
    WorkerShortResponse,
    StatusHistoryResponse,
)
from app.utils.helpers import (
    generate_order_number,
    get_deadline_info,
    is_overdue,
    hours_until_deadline,
    utc_now,
    make_aware,
)
from app.utils.logger import logger


# ================================================================
#  YORDAMCHI: Order → OrderResponse (deadline ma'lumoti bilan)
# ================================================================

def _build_order_response(order: Order) -> OrderResponse:
    """
    SQLAlchemy Order ob'ektini OrderResponse Pydantic modeliga
    o'tkazadi va deadline hisob-kitoblarini qo'shadi.
    """
    deadline_aware = make_aware(order.deadline)
    d_info = get_deadline_info(deadline_aware)

    # Status tarixini yig'amiz
    history = [
        StatusHistoryResponse(
            id=h.id,
            old_status=h.old_status,
            new_status=h.new_status,
            comment=h.comment,
            changed_by=(
                WorkerShortResponse(
                    id=h.changed_by.id,
                    full_name=h.changed_by.full_name,
                    role=h.changed_by.role.value,
                )
                if h.changed_by else None
            ),
            created_at=h.created_at,
        )
        for h in (order.status_history or [])
    ]

    return OrderResponse(
        id=order.id,
        order_number=order.order_number,
        client=ClientShortResponse(
            id=order.client.id,
            full_name=order.client.full_name,
            phone=order.client.phone,
        ),
        operator=(
            WorkerShortResponse(
                id=order.operator.id,
                full_name=order.operator.full_name,
                role=order.operator.role.value,
            ) if order.operator else None
        ),
        master=(
            WorkerShortResponse(
                id=order.master.id,
                full_name=order.master.full_name,
                role=order.master.role.value,
            ) if order.master else None
        ),
        tv_brand=order.tv_brand,
        tv_model=order.tv_model,
        tv_diagonal=order.tv_diagonal,
        tv_serial_number=order.tv_serial_number,
        problem_description=order.problem_description,
        ai_diagnosis=order.ai_diagnosis,
        master_diagnosis=order.master_diagnosis,
        work_done=order.work_done,
        status=order.status,
        source=order.source,
        estimated_price=order.estimated_price,
        final_price=order.final_price,
        parts_cost=order.parts_cost,
        is_paid=order.is_paid,
        payment_method=order.payment_method,
        master_commission=order.master_commission,
        deadline=deadline_aware,
        created_at=order.created_at,
        updated_at=order.updated_at,
        accepted_at=order.accepted_at,
        completed_at=order.completed_at,
        delivered_at=order.delivered_at,
        is_archived=order.is_archived,
        cancel_reason=order.cancel_reason,
        is_overdue=d_info["is_overdue"],
        hours_until_deadline=d_info["hours_remaining"],
        status_history=history,
    )


# ================================================================
#  YORDAMCHI: Order ni eager load bilan yuklash
# ================================================================

def _order_query_with_relations():
    """
    Order'ni barcha bog'liq jadvallar bilan birga yuklash.
    N+1 muammosini oldini oladi.
    """
    return (
        select(Order)
        .options(
            selectinload(Order.client),
            selectinload(Order.operator),
            selectinload(Order.master),
            selectinload(Order.status_history).selectinload(
                OrderStatusHistory.changed_by
            ),
        )
    )


# ================================================================
#  1. ZAKAZ YARATISH
# ================================================================

async def create_order(
    db: AsyncSession,
    data: OrderCreateRequest,
    created_by: User,
) -> OrderResponse:
    """
    Yangi zakaz yaratadi.

    Mantiq:
      1. Mijozni topadi yoki yangi yaratadi
      2. ShopSettings.order_counter ni oshiradi
      3. Zakaz raqamini generatsiya qiladi (TV-2025-XXXX)
      4. Order saqlaydi
      5. Birinchi status_history yozuvini qo'shadi (new → new)
    """

    # ── 1. Mijoz ──────────────────────────────────────────────
    if data.client_id:
        client_result = await db.execute(
            select(Client).where(Client.id == data.client_id)
        )
        client = client_result.scalar_one_or_none()
        if not client:
            raise ValueError(f"Mijoz topilmadi: id={data.client_id}")
    else:
        # Telefon bo'yicha mavjud mijozni tekshirish
        if data.client_phone:
            existing = await db.execute(
                select(Client).where(Client.phone == data.client_phone)
            )
            client = existing.scalar_one_or_none()
        else:
            client = None

        if not client:
            # Yangi mijoz yaratish
            client = Client(
                full_name=data.client_name,
                phone=data.client_phone,
            )
            db.add(client)
            await db.flush()   # ID olish uchun
            logger.info(f"👤 Yangi mijoz yaratildi: {client.full_name} ({client.phone})")

    # ── 2. Zakaz raqami ───────────────────────────────────────
    settings_result = await db.execute(select(ShopSettings))
    shop = settings_result.scalar_one_or_none()

    if not shop:
        # Sozlamalar yo'q bo'lsa — yaratamiz
        shop = ShopSettings()
        db.add(shop)
        await db.flush()

    shop.order_counter += 1
    order_number = generate_order_number(
        counter=shop.order_counter,
        year=utc_now().year,
    )

    # ── 3. Zakaz yaratish ─────────────────────────────────────
    deadline = make_aware(data.deadline)

    order = Order(
        order_number=order_number,
        client_id=client.id,
        operator_id=data.operator_id or created_by.id,
        master_id=data.master_id,
        tv_brand=data.tv_brand,
        tv_model=data.tv_model,
        tv_diagonal=data.tv_diagonal,
        tv_serial_number=data.tv_serial_number,
        problem_description=data.problem_description,
        source=data.source,
        estimated_price=data.estimated_price,
        final_price=0.0,
        parts_cost=0.0,
        status=OrderStatus.NEW,
        deadline=deadline,
        is_paid=False,
        is_archived=False,
    )
    db.add(order)
    await db.flush()   # order.id olish uchun

    # ── 4. Birinchi status tarixi ─────────────────────────────
    history = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=created_by.id,
        old_status=None,
        new_status=OrderStatus.NEW,
        comment="Zakaz ochildi",
    )
    db.add(history)

    # ── 5. Mijoz statistikasini yangilash ─────────────────────
    client.total_orders += 1

    await db.commit()

    # Refresh with relations
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order.id)
    )
    fresh_order = result.scalar_one()

    logger.info(
        f"✅ Zakaz yaratildi: {order_number} | "
        f"Mijoz: {client.full_name} | "
        f"Deadline: {deadline.strftime('%d.%m.%Y %H:%M')} | "
        f"Operator: {created_by.username}"
    )

    return _build_order_response(fresh_order)


# ================================================================
#  2. ZAKAZ O'QISH — BITTA
# ================================================================

async def get_order_by_id(
    db: AsyncSession,
    order_id: int,
) -> Optional[OrderResponse]:
    """ID bo'yicha bitta zakazni qaytaradi"""
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None
    return _build_order_response(order)


async def get_order_by_number(
    db: AsyncSession,
    order_number: str,
) -> Optional[OrderResponse]:
    """Zakaz raqami bo'yicha topadi (masalan: TV-2025-0001)"""
    result = await db.execute(
        _order_query_with_relations().where(
            Order.order_number == order_number.upper()
        )
    )
    order = result.scalar_one_or_none()
    if not order:
        return None
    return _build_order_response(order)


# ================================================================
#  3. ZAKAZLAR RO'YXATI (filter + pagination)
# ================================================================

async def get_orders_list(
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
    status: Optional[OrderStatus] = None,
    master_id: Optional[int] = None,
    client_id: Optional[int] = None,
    search: Optional[str] = None,
    is_archived: bool = False,
    only_overdue: bool = False,
) -> OrderListResponse:
    """
    Zakazlar ro'yxati — filtrlash va sahifalash bilan.

    Filtrlar:
      status      — holat bo'yicha
      master_id   — usta bo'yicha
      client_id   — mijoz bo'yicha
      search      — zakaz raqami yoki mijoz nomi bo'yicha
      is_archived — arxivlangan zakazlar
      only_overdue — faqat muddati o'tganlar
    """
    # Asosiy so'rov
    base_q = (
        _order_query_with_relations()
        .where(Order.is_archived == is_archived)
    )

    # Filtrlar
    if status:
        base_q = base_q.where(Order.status == status)

    if master_id:
        base_q = base_q.where(Order.master_id == master_id)

    if client_id:
        base_q = base_q.where(Order.client_id == client_id)

    if search:
        base_q = base_q.join(Client).where(
            or_(
                Order.order_number.ilike(f"%{search}%"),
                Client.full_name.ilike(f"%{search}%"),
                Client.phone.ilike(f"%{search}%"),
            )
        )

    if only_overdue:
        now = utc_now()
        # Aktiv (arxivlanmagan) va muddati o'tgan
        base_q = base_q.where(
            and_(
                Order.deadline < now,
                Order.status.notin_([
                    OrderStatus.DELIVERED,
                    OrderStatus.CANCELLED,
                ]),
            )
        )

    # Jami soni (pagination uchun)
    count_q = select(func.count()).select_from(
        base_q.subquery()
    )
    total_result = await db.execute(count_q)
    total = total_result.scalar_one()

    # Sahifalash
    offset = (page - 1) * page_size
    paginated_q = (
        base_q
        .order_by(Order.created_at.desc())
        .offset(offset)
        .limit(page_size)
    )
    result = await db.execute(paginated_q)
    orders = result.scalars().all()

    # Muddati o'tgan zakazlar soni (umumiy)
    now = utc_now()
    overdue_count_q = select(func.count(Order.id)).where(
        and_(
            Order.is_archived == False,
            Order.deadline < now,
            Order.status.notin_([
                OrderStatus.DELIVERED,
                OrderStatus.CANCELLED,
            ]),
        )
    )
    overdue_result = await db.execute(overdue_count_q)
    overdue_count = overdue_result.scalar_one()

    import math
    return OrderListResponse(
        items=[_build_order_response(o) for o in orders],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=max(1, math.ceil(total / page_size)),
        overdue_count=overdue_count,
    )


# ================================================================
#  4. ZAKAZ MA'LUMOTLARINI YANGILASH
# ================================================================

async def update_order(
    db: AsyncSession,
    order_id: int,
    data: OrderUpdateRequest,
    updated_by: User,
) -> Optional[OrderResponse]:
    """
    Zakaz maydonlarini yangilaydi (PATCH — faqat yuborilgan maydonlar).
    Status o'zgarmaydi — buning uchun update_order_status ishlatiladi.
    """
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None

    # Faqat yuborilgan maydonlarni yangilaymiz
    update_data = data.model_dump(exclude_unset=True)

    # Deadline kelgan bo'lsa, timezone-aware qilamiz
    if "deadline" in update_data and update_data["deadline"]:
        update_data["deadline"] = make_aware(update_data["deadline"])

    for field, value in update_data.items():
        setattr(order, field, value)

    await db.commit()
    await db.refresh(order)

    # Qayta yuklash (relation'lar uchun)
    fresh_result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    fresh_order = fresh_result.scalar_one()

    logger.info(
        f"✏️  Zakaz yangilandi: {order.order_number} | "
        f"Kim: {updated_by.username} | "
        f"Maydonlar: {list(update_data.keys())}"
    )
    return _build_order_response(fresh_order)


# ================================================================
#  5. STATUS O'ZGARTIRISH + TARIX YOZISH (MAJBURIY)
# ================================================================

# Ruxsat etilgan status o'tishlar jadvali
# Kalit: joriy holat → Qiymat: o'tish mumkin bo'lgan holatlari
#
# on_the_way holati location_service orqali avtomatik boshqariladi:
#   POST /locations/visit/start → on_the_way
#   POST /locations/visit/end   → in_repair
# Lekin order_service orqali ham qo'lda o'zgartirish ruxsat etiladi
# (masalan: usta vizitdan bekor qilsa).
ALLOWED_TRANSITIONS: dict[OrderStatus, list[OrderStatus]] = {
    OrderStatus.NEW: [
        OrderStatus.ACCEPTED,
        OrderStatus.CANCELLED,
    ],
    OrderStatus.ACCEPTED: [
        OrderStatus.DIAGNOSING,
        OrderStatus.ON_THE_WAY,   # ← Bevosita vizitga chiqish (qo'lda)
        OrderStatus.CANCELLED,
    ],
    OrderStatus.DIAGNOSING: [
        OrderStatus.WAITING,
        OrderStatus.IN_REPAIR,
        OrderStatus.ON_THE_WAY,   # ← Diagnostika keyin vizitga
        OrderStatus.CANCELLED,
    ],
    OrderStatus.WAITING: [
        OrderStatus.IN_REPAIR,
        OrderStatus.ON_THE_WAY,   # ← Zapchast olib ketish uchun vizit
        OrderStatus.CANCELLED,
    ],
    OrderStatus.ON_THE_WAY: [
        OrderStatus.IN_REPAIR,    # ← Yetib keldi (odatda visit/end orqali)
        OrderStatus.ACCEPTED,     # ← Vizit bekor qilindi, qaytdi
        OrderStatus.DIAGNOSING,   # ← Qaytib diagnostikaga
        OrderStatus.CANCELLED,
    ],
    OrderStatus.IN_REPAIR: [
        OrderStatus.DONE,
        OrderStatus.WAITING,
        OrderStatus.ON_THE_WAY,   # ← Qo'shimcha detal uchun qayta vizit
        OrderStatus.CANCELLED,
    ],
    OrderStatus.DONE: [
        OrderStatus.DELIVERED,
        OrderStatus.CANCELLED,
    ],
    OrderStatus.DELIVERED: [],    # Yakuniy holat — o'zgartirib bo'lmaydi
    OrderStatus.CANCELLED: [],    # Yakuniy holat — o'zgartirib bo'lmaydi
}

# Status o'zgarganda qaysi vaqt maydonini yangilash kerak
STATUS_TIMESTAMP_MAP: dict[OrderStatus, str] = {
    OrderStatus.ACCEPTED:   "accepted_at",
    OrderStatus.DONE:       "completed_at",
    OrderStatus.DELIVERED:  "delivered_at",
}


async def update_order_status(
    db: AsyncSession,
    order_id: int,
    data: OrderStatusUpdateRequest,
    changed_by: User,
) -> tuple[Optional[OrderResponse], Optional[str]]:
    """
    Zakaz statusini o'zgartiradi va tarixga yozadi.

    Returns:
        (OrderResponse, None)     — muvaffaqiyatli
        (None, "xato sababi")     — xatolik

    Mantiq:
      1. Zakazni topadi
      2. Transition ruxsat etilganini tekshiradi
      3. Statusni yangilaydi
      4. Vaqt stampini yangilaydi (accepted_at, completed_at, ...)
      5. OrderStatusHistory ga MAJBURIY yozadi
      6. DELIVERED bo'lsa ustaga komisyon hisoblaydi
    """
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None, "Zakaz topilmadi"

    old_status = order.status
    new_status = data.new_status

    # Bir xil status — keraksiz
    if old_status == new_status:
        return None, f"Zakaz allaqachon '{new_status.value}' holatida"

    # Transition tekshiruvi
    allowed = ALLOWED_TRANSITIONS.get(old_status, [])
    if new_status not in allowed:
        allowed_names = [s.value for s in allowed]
        return None, (
            f"'{old_status.value}' holatidan '{new_status.value}' holatiga "
            f"o'tish mumkin emas. Ruxsat etilganlar: {allowed_names}"
        )

    # Statusni yangilash
    order.status = new_status

    # Vaqt stampini yangilash
    if new_status in STATUS_TIMESTAMP_MAP:
        ts_field = STATUS_TIMESTAMP_MAP[new_status]
        setattr(order, ts_field, utc_now())

    # ── Status tarixi — MAJBURIY ──────────────────────────────
    history_entry = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=changed_by.id,
        old_status=old_status,
        new_status=new_status,
        comment=data.comment,
    )
    db.add(history_entry)

    # ── DELIVERED: ustaga komisyon hisoblash ─────────────────
    if new_status == OrderStatus.DELIVERED and order.master_id:
        await _calculate_master_commission(db, order)

    # ── CANCELLED: arxivga o'tkazish ─────────────────────────
    if new_status == OrderStatus.CANCELLED:
        order.is_archived = True
        order.cancel_reason = data.comment

    await db.commit()

    # Qayta yuklash
    fresh_result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    fresh_order = fresh_result.scalar_one()

    logger.info(
        f"🔄 Status o'zgardi: {order.order_number} | "
        f"{old_status.value} → {new_status.value} | "
        f"Kim: {changed_by.username} | "
        f"Izoh: {data.comment or '-'}"
    )

    return _build_order_response(fresh_order), None


async def _calculate_master_commission(
    db: AsyncSession,
    order: Order,
) -> None:
    """
    Zakaz topshirilganda ustaning komisyon ulushini hisoblaydi va balansiga qo'shadi.
    Faqat final_price > 0 bo'lsa ishlaydi.
    """
    if not order.master_id or order.final_price <= 0:
        return

    master_result = await db.execute(
        select(User).where(User.id == order.master_id)
    )
    master = master_result.scalar_one_or_none()
    if not master or master.commission_percent <= 0:
        return

    commission = round(order.final_price * master.commission_percent / 100, 2)
    order.master_commission = commission
    master.balance += commission

    logger.info(
        f"💰 Komisyon hisoblandi: usta={master.full_name} | "
        f"summa={commission:,.0f} so'm ({master.commission_percent}%) | "
        f"zakaz={order.order_number}"
    )


# ================================================================
#  6. TO'LOV QABUL QILISH
# ================================================================

async def process_payment(
    db: AsyncSession,
    order_id: int,
    data: OrderPaymentRequest,
    received_by: User,
) -> tuple[Optional[OrderResponse], Optional[str]]:
    """
    Zakaz to'lovini qabul qiladi.

    Mantiq:
      1. Zakaz DONE holatida bo'lishi kerak
      2. Allaqachon to'lanmagan bo'lishi kerak
      3. final_price ni saqlaydi
      4. is_paid = True qiladi
      5. Kassa jadvaliga kirim yozadi
      6. Statusni DELIVERED ga o'tkazadi
    """
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None, "Zakaz topilmadi"

    if order.is_paid:
        return None, "Bu zakaz allaqachon to'langan"

    if order.status != OrderStatus.DONE:
        return None, (
            f"To'lov faqat 'done' holatidagi zakaz uchun qabul qilinadi. "
            f"Hozirgi holat: '{order.status.value}'"
        )

    # To'lov ma'lumotlarini saqlash
    order.final_price    = data.final_price
    order.is_paid        = True
    order.payment_method = data.payment_method

    # Kassaga kirim yozish
    transaction = FinanceTransaction(
        transaction_type=TransactionType.INCOME,
        amount=data.final_price,
        description=f"Zakaz to'lovi: {order.order_number}",
        notes=data.comment,
        performed_by_id=received_by.id,
        order_id=order.id,
        payment_method=data.payment_method,
    )
    db.add(transaction)

    # Statusni DELIVERED ga o'tkazish + tarix
    order.status       = OrderStatus.DELIVERED
    order.delivered_at = utc_now()

    history = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=received_by.id,
        old_status=OrderStatus.DONE,
        new_status=OrderStatus.DELIVERED,
        comment=f"To'lov qabul qilindi: {data.final_price:,.0f} so'm ({data.payment_method.value})",
    )
    db.add(history)

    # Ustaga komisyon
    await _calculate_master_commission(db, order)

    # Mijoz umumiy xarajatini yangilash
    client_result = await db.execute(
        select(Client).where(Client.id == order.client_id)
    )
    client = client_result.scalar_one_or_none()
    if client:
        client.total_spent += data.final_price

    await db.commit()

    fresh_result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    fresh_order = fresh_result.scalar_one()

    logger.info(
        f"💳 To'lov qabul qilindi: {order.order_number} | "
        f"{data.final_price:,.0f} so'm | "
        f"{data.payment_method.value} | "
        f"Kim: {received_by.username}"
    )

    return _build_order_response(fresh_order), None


# ================================================================
#  7. DEADLINE ALERT — OGOHLANTIRISH TIZIMI
# ================================================================

async def get_deadline_alerts(
    db: AsyncSession,
    warning_hours: float = 24.0,
) -> list[OrderDeadlineAlertResponse]:
    """
    Muddati o'tgan YOKI yaqinlashgan zakazlar ro'yxatini qaytaradi.

    Kimlar kiradi:
      - Muddati o'tgan (overdue) — har qanday aktiv status
      - warning_hours ichida muddati yetadigan zakazlar

    Yakuniy holatlardagilar (DELIVERED, CANCELLED) kirmaydi.

    Args:
        warning_hours: Necha soat qolganda ogohlantirish beriladi (default: 24)

    Returns:
        Ogohlantirish ro'yxati — eng kritiklari birinchi
    """
    now = utc_now()
    alert_threshold = now + timedelta(hours=warning_hours)

    # Aktiv zakazlardan deadline yaqinlashganlarini topish
    active_statuses = [
        OrderStatus.NEW,
        OrderStatus.ACCEPTED,
        OrderStatus.DIAGNOSING,
        OrderStatus.WAITING,
        OrderStatus.ON_THE_WAY,   # ← Yo'ldagi zakazlar ham nazoratda
        OrderStatus.IN_REPAIR,
        OrderStatus.DONE,
    ]

    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.client),
            selectinload(Order.master),
        )
        .where(
            and_(
                Order.status.in_(active_statuses),
                Order.is_archived == False,
                Order.deadline <= alert_threshold,   # Yaqinlashgan yoki o'tib ketgan
            )
        )
        .order_by(Order.deadline.asc())   # Eng kritiklari birinchi
    )
    orders = result.scalars().all()

    alerts = []
    for order in orders:
        deadline_aware = make_aware(order.deadline)
        d_info = get_deadline_info(deadline_aware)

        tv_parts = filter(None, [order.tv_brand, order.tv_model, order.tv_diagonal])
        tv_info  = " | ".join(tv_parts) or "TV ma'lumoti yo'q"

        alerts.append(
            OrderDeadlineAlertResponse(
                order_id=order.id,
                order_number=order.order_number,
                client_name=order.client.full_name,
                tv_info=tv_info,
                status=order.status,
                deadline=deadline_aware,
                is_overdue=d_info["is_overdue"],
                hours_remaining=d_info["hours_remaining"],
                master_name=order.master.full_name if order.master else None,
            )
        )

    overdue  = [a for a in alerts if a.is_overdue]
    upcoming = [a for a in alerts if not a.is_overdue]

    logger.debug(
        f"🔔 Deadline alertlar: {len(overdue)} muddati o'tgan, "
        f"{len(upcoming)} yaqinlashgan"
    )

    # Avval muddati o'tganlar, keyin yaqinlashganlar
    return overdue + upcoming


# ================================================================
#  8. STATISTIKA (Dashboard uchun)
# ================================================================

async def get_order_stats(db: AsyncSession) -> OrderStatsResponse:
    """
    Dashboard uchun bugungi va umumiy zakaz statistikasi.
    """
    now  = utc_now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

    async def count_by_status(status: OrderStatus, archived: bool = False) -> int:
        r = await db.execute(
            select(func.count(Order.id)).where(
                and_(Order.status == status, Order.is_archived == archived)
            )
        )
        return r.scalar_one()

    async def count_today_by_status(status: OrderStatus) -> int:
        r = await db.execute(
            select(func.count(Order.id)).where(
                and_(
                    Order.status == status,
                    Order.updated_at >= today_start,
                )
            )
        )
        return r.scalar_one()

    # Umumiy
    total   = await db.execute(select(func.count(Order.id)).where(Order.is_archived == False))
    new_cnt = await count_by_status(OrderStatus.NEW)

    in_progress = 0
    for s in [OrderStatus.ACCEPTED, OrderStatus.DIAGNOSING,
              OrderStatus.WAITING, OrderStatus.ON_THE_WAY,
              OrderStatus.IN_REPAIR]:
        in_progress += await count_by_status(s)

    # Bugun
    completed_today = await count_today_by_status(OrderStatus.DONE)
    delivered_today = await count_today_by_status(OrderStatus.DELIVERED)
    cancelled_today = await count_today_by_status(OrderStatus.CANCELLED)

    # Muddati o'tgan
    overdue_r = await db.execute(
        select(func.count(Order.id)).where(
            and_(
                Order.is_archived == False,
                Order.deadline < now,
                Order.status.notin_([
                    OrderStatus.DELIVERED,
                    OrderStatus.CANCELLED,
                ]),
            )
        )
    )
    overdue_count = overdue_r.scalar_one()

    # Bugungi daromad
    revenue_r = await db.execute(
        select(func.coalesce(func.sum(Order.final_price), 0.0)).where(
            and_(
                Order.is_paid == True,
                Order.delivered_at >= today_start,
            )
        )
    )
    revenue_today = revenue_r.scalar_one()

    return OrderStatsResponse(
        total_orders=total.scalar_one(),
        new_orders=new_cnt,
        in_progress=in_progress,
        completed_today=completed_today,
        delivered_today=delivered_today,
        cancelled_today=cancelled_today,
        overdue_count=overdue_count,
        total_revenue_today=float(revenue_today),
    )
