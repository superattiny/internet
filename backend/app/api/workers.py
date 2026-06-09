# ================================================
# api/workers.py — Ishchilar API Router
#
# Endpoint'lar ro'yxati:
#   POST   /api/v1/workers/                          → Yangi ishchi yaratish [Admin]
#   GET    /api/v1/workers/                          → Ro'yxat (filter bilan)
#   GET    /api/v1/workers/summary                   → Moliyaviy xulosa [Admin]
#   GET    /api/v1/workers/{worker_id}               → Bitta ishchi
#   PATCH  /api/v1/workers/{worker_id}               → Ma'lumot yangilash [Admin]
#   DELETE /api/v1/workers/{worker_id}               → Bloklash [Admin]
#   POST   /api/v1/workers/{worker_id}/activate      → Qayta faollashtirish [Admin]
#   GET    /api/v1/workers/{worker_id}/balance       → Balans tarixi
#   POST   /api/v1/workers/{worker_id}/salary        → Ish haqi to'lash [Admin]
#   POST   /api/v1/workers/{worker_id}/balance/adjust → Balans tuzatish [Admin]
#   GET    /api/v1/workers/me/balance                → O'z balansi (Usta uchun)
# ================================================

from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status

from app.database.models import UserRole
from app.schemas.worker import (
    WorkerCreateRequest,
    WorkerUpdateRequest,
    SalaryPaymentRequest,
    BalanceAdjustRequest,
    WorkerResponse,
    WorkerListResponse,
    WorkerBalanceHistoryResponse,
    SalaryPaymentResponse,
)
from app.services.worker_service import (
    create_worker,
    get_worker_by_id,
    get_workers_list,
    update_worker,
    pay_salary,
    adjust_balance,
    get_worker_balance_history,
    get_workers_finance_summary,
)
from app.utils.dependencies import (
    CurrentUser,
    AdminUser,
    OperatorOrAdminUser,
    DBSession,
)
from app.utils.logger import logger


# ================================================================
#  ROUTER
# ================================================================

router = APIRouter(
    prefix="/workers",
    tags=["👷 Workers — Ishchilar va Balanslar"],
    responses={
        401: {"description": "Avtorizatsiya talab qilinadi"},
        403: {"description": "Bu amal uchun ruxsat yo'q"},
        404: {"description": "Ishchi topilmadi"},
    },
)


# ================================================================
#  YORDAMCHI: Ishchini topish yoki 404
# ================================================================

async def _get_worker_or_404(worker_id: int, db: DBSession) -> WorkerResponse:
    worker = await get_worker_by_id(db, worker_id)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ishchi topilmadi: id={worker_id}",
        )
    return worker


# ================================================================
#  1. YANGI ISHCHI YARATISH  [Admin only]
# ================================================================

@router.post(
    "/",
    response_model=WorkerResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Yangi ishchi yaratish [Admin]",
    description="""
    Yangi usta yoki operator yaratadi. **Faqat Admin** bajarishi mumkin.

    **Muhim qoidalar:**
    - `username` noyob bo'lishi shart (band bo'lsa `409` xato)
    - `role` faqat `master` yoki `operator` bo'lishi mumkin
    - `commission_percent` — har zakaz topshirilganda avtomatik
      hisoblanadigankulushfoizi (0–100%)
    - `salary_rate` — oylik stavka (ixtiyoriy, komisyon bilan birga ishlatilishi mumkin)

    **Boshlang'ich balans:** 0 so'm (komisyon hisoblanganda oshib boradi).
    """,
)
async def create_new_worker(
    data: WorkerCreateRequest,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await create_worker(db, data, admin)
    if error:
        status_code = (
            status.HTTP_409_CONFLICT
            if "band" in error
            else status.HTTP_422_UNPROCESSABLE_ENTITY
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result


# ================================================================
#  2. ISHCHILAR RO'YXATI
# ================================================================

@router.get(
    "/",
    response_model=WorkerListResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchilar ro'yxati",
    description="""
    Barcha ishchilar ro'yxati.

    **Ruxsatlar:**
    - **Admin** — hammani ko'radi (faol + bloklangan)
    - **Operator** — faqat faol ustalarni ko'radi

    **Filtrlar:**
    - `role` — `master` yoki `operator`
    - `is_active` — `true` (faol) yoki `false` (bloklangan)
    """,
)
async def list_workers(
    current_user: CurrentUser,
    db: DBSession,
    role: Optional[UserRole] = Query(
        default=None,
        description="Rol bo'yicha filter: master yoki operator"
    ),
    is_active: Optional[bool] = Query(
        default=None,
        description="Holat: true=faol, false=bloklangan"
    ),
    page:      int = Query(default=1,  ge=1),
    page_size: int = Query(default=50, ge=1, le=100),
) -> WorkerListResponse:
    # Operator faqat ustalarni ko'ra oladi
    effective_role = role
    if current_user.role == UserRole.OPERATOR:
        effective_role = UserRole.MASTER
        is_active = True   # Operator bloklangan ustalarni ko'rmaydi

    return await get_workers_list(
        db=db,
        role=effective_role,
        is_active=is_active,
        page=page,
        page_size=page_size,
    )


# ================================================================
#  3. MOLIYAVIY XULOSA  [Admin only]
# ================================================================

@router.get(
    "/summary",
    status_code=status.HTTP_200_OK,
    summary="Ishchilar moliyaviy xulosasi [Admin]",
    description="""
    Barcha ishchilar bo'yicha moliyaviy umumiy hisobot.

    **Qaytaradi:**
    - Jami faol ishchilar soni
    - Barcha balanslarda turib-turgan umumiy summa
    - Jami hisoblangan komisyonlar
    - Jami to'lab berilgan ish haqlar
    - Hali to'lanmagan qoldiq
    - Har bir ishchining qisqacha holati
    """,
)
async def workers_finance_summary(
    admin: AdminUser,
    db: DBSession,
) -> dict:
    return await get_workers_finance_summary(db)


# ================================================================
#  4. O'Z BALANSI — USTA UCHUN  (/{worker_id} dan OLDIN bo'lishi shart)
# ================================================================

@router.get(
    "/me/balance",
    response_model=WorkerBalanceHistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Mening balansim va tarixim",
    description="""
    Tizimga kirgan usta o'z balansini va barcha moliyaviy
    tarixini ko'radi.

    **Ko'rsatiladi:**
    - Joriy balans
    - Har bir zakazdan hisoblangan komisyonlar
    - To'lab berilgan ish haq tarixi
    - Jami ishlab topilgan va jami to'langan summalar
    """,
)
async def my_balance(
    current_user: CurrentUser,
    db: DBSession,
) -> WorkerBalanceHistoryResponse:
    history = await get_worker_balance_history(db, current_user.id)
    if not history:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ma'lumot topilmadi",
        )
    return history


# ================================================================
#  5. BITTA ISHCHI MA'LUMOTI
# ================================================================

@router.get(
    "/{worker_id}",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Bitta ishchi ma'lumoti",
    description="""
    ID bo'yicha ishchining to'liq ma'lumoti va statistikasi.

    **Statistika:**
    - Jami bitirgan zakazlari soni
    - Jami ishlab topgani (komisyon yig'indisi)
    - Jami to'lab berilgani
    - Joriy balans (hali to'lanmagan qoldiq)
    """,
)
async def get_worker(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> WorkerResponse:
    return await _get_worker_or_404(worker_id, db)


# ================================================================
#  6. ISHCHI MA'LUMOTLARINI YANGILASH  [Admin only]
# ================================================================

@router.patch(
    "/{worker_id}",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchi ma'lumotlarini yangilash [Admin]",
    description="""
    Ishchi ma'lumotlarini yangilaydi. **Faqat yuborilgan maydonlar o'zgaradi.**

    **Yangilanishi mumkin:**
    - `full_name` — ismi-familiyasi
    - `phone` — telefon raqami
    - `commission_percent` — komisyon foizi (o'zgarish log ga yoziladi)
    - `salary_rate` — oylik stavka
    - `is_active` — `false` qilib bloklash mumkin

    **E'tibor:** komisyon foizi o'zgarsa, **yangi foiz faqat keyingi
    zakazlarga** qo'llaniladi. Allaqachon hisoblangan komisyonlar o'zgarmaydi.
    """,
)
async def update_worker_info(
    worker_id: int,
    data: WorkerUpdateRequest,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await update_worker(db, worker_id, data, admin)
    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result


# ================================================================
#  7. ISHCHINI BLOKLASH  [Admin only]
# ================================================================

@router.delete(
    "/{worker_id}",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchini bloklash [Admin]",
    description="""
    Ishchini tizimdan **o'chirmaydi** — faqat `is_active = false` qiladi.

    Bloklangan ishchi:
    - Tizimga kira olmaydi
    - Yangi zakazlarga tayinlanmaydi
    - Ma'lumotlari va tarixi saqlanib qoladi

    Qayta faollashtirish uchun: `POST /{worker_id}/activate`
    """,
)
async def deactivate_worker(
    worker_id: int,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    # O'zini bloklay olmasligi kerak
    if worker_id == admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O'zingizni bloklay olmaysiz",
        )

    result, error = await update_worker(
        db, worker_id,
        WorkerUpdateRequest(is_active=False),
        admin,
    )
    if error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST,
            detail=error,
        )

    logger.info(f"🔒 Ishchi bloklandi: id={worker_id} | Admin: {admin.username}")
    return result


# ================================================================
#  8. ISHCHINI QAYTA FAOLLASHTIRISH  [Admin only]
# ================================================================

@router.post(
    "/{worker_id}/activate",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchini qayta faollashtirish [Admin]",
    description="Bloklangan ishchini yana faol holatga qaytaradi.",
)
async def activate_worker(
    worker_id: int,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await update_worker(
        db, worker_id,
        WorkerUpdateRequest(is_active=True),
        admin,
    )
    if error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST,
            detail=error,
        )

    logger.info(f"🔓 Ishchi faollashtirildi: id={worker_id} | Admin: {admin.username}")
    return result


# ================================================================
#  9. ISHCHI BALANS TARIXI
# ================================================================

@router.get(
    "/{worker_id}/balance",
    response_model=WorkerBalanceHistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchi balans tarixi",
    description="""
    Ishchining to'liq moliyaviy tarixi:

    **Kirimlar (komisyonlar):**
    - Har bir zakaz bo'yicha hisoblangan komisyon
    - Zakaz raqami, mijoz, TV ma'lumotlari, summa, foiz

    **Chiqimlar (ish haqlar):**
    - To'lab berilgan barcha to'lovlar
    - Kim to'ladi, qachon, qanday usulda

    **Joriy holat:**
    - Hozirgi balans = jami komisyon − jami to'lovlar
    """,
)
async def worker_balance_history(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> WorkerBalanceHistoryResponse:
    history = await get_worker_balance_history(db, worker_id)
    if not history:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ishchi topilmadi: id={worker_id}",
        )
    return history


# ================================================================
#  10. ISH HAQI TO'LASH  [Admin only]
# ================================================================

@router.post(
    "/{worker_id}/salary",
    response_model=SalaryPaymentResponse,
    status_code=status.HTTP_200_OK,
    summary="Ish haqi to'lash [Admin]",
    description="""
    Ishchiga ish haqi to'laydi.

    **Avtomatik bajariladi:**
    1. Ishchi balansidan to'lov summasi **ayiriladi**
    2. `SalaryPayment` jadvaliga to'lov tarixi **yoziladi**
    3. `FinanceTransaction` jadvaliga kassa **chiqimi yoziladi**

    **Shartlar:**
    - Ishchi faol bo'lishi shart
    - To'lov summasi joriy balansdan oshmasligi kerak
      (balans manfiyga tushmaydi)
    """,
)
async def pay_worker_salary(
    worker_id: int,
    data: SalaryPaymentRequest,
    admin: AdminUser,
    db: DBSession,
) -> SalaryPaymentResponse:
    result, error = await pay_salary(db, worker_id, data, admin)
    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND  if "topilmadi" in error else
            status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result


# ================================================================
#  11. BALANSNI QO'LDA TO'G'IRLASH  [Admin only]
# ================================================================

@router.post(
    "/{worker_id}/balance/adjust",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Balansni qo'lda to'g'irlash [Admin]",
    description="""
    Admin ishchi balansini qo'lda o'zgartiradi.

    **Ishlatilish holatlari:**
    - Bonus qo'shish (musbat `amount`)
    - Noto'g'ri hisoblangan komisyonni tuzatish (manfiy `amount`)
    - Avans berish

    **`reason` maydoni MAJBURIY** — audit izi uchun barcha
    o'zgarishlar `FinanceTransaction` jadvaliga yoziladi.

    **Cheklov:** Balans manfiyga tushishi mumkin emas.
    """,
)
async def adjust_worker_balance(
    worker_id: int,
    data: BalanceAdjustRequest,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await adjust_balance(db, worker_id, data, admin)
    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND  if "topilmadi" in error else
            status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result
