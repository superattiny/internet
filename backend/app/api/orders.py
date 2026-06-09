# ================================================
# api/orders.py — Zakazlar API Router
#
# Endpoint'lar ro'yxati:
#   POST   /api/v1/orders/                    → Yangi zakaz ochish
#   GET    /api/v1/orders/                    → Ro'yxat (filter + pagination)
#   GET    /api/v1/orders/stats               → Dashboard statistikasi
#   GET    /api/v1/orders/alerts/deadline     → Deadline ogohlantirishlari
#   GET    /api/v1/orders/{order_id}          → Bitta zakaz (ID bo'yicha)
#   GET    /api/v1/orders/by-number/{number}  → Bitta zakaz (raqam bo'yicha)
#   PATCH  /api/v1/orders/{order_id}          → Ma'lumotlarni yangilash
#   POST   /api/v1/orders/{order_id}/status   → Status o'zgartirish
#   POST   /api/v1/orders/{order_id}/payment  → To'lov qabul qilish
#   POST   /api/v1/orders/{order_id}/archive  → Arxivlash
# ================================================

from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status

from app.database.models import OrderStatus
from app.schemas.order import (
    OrderCreateRequest,
    OrderUpdateRequest,
    OrderStatusUpdateRequest,
    OrderPaymentRequest,
    OrderResponse,
    OrderListResponse,
    OrderDeadlineAlertResponse,
    OrderStatsResponse,
)
from app.services.order_service import (
    create_order,
    get_order_by_id,
    get_order_by_number,
    get_orders_list,
    update_order,
    update_order_status,
    process_payment,
    get_deadline_alerts,
    get_order_stats,
)
from app.utils.dependencies import (
    CurrentUser,
    OperatorOrAdminUser,
    AdminUser,
    DBSession,
)
from app.utils.logger import logger


# ================================================================
#  ROUTER
# ================================================================

router = APIRouter(
    prefix="/orders",
    tags=["📋 Orders — Zakazlar boshqaruvi"],
    responses={
        401: {"description": "Avtorizatsiya talab qilinadi"},
        403: {"description": "Bu amal uchun ruxsat yo'q"},
        404: {"description": "Zakaz topilmadi"},
    },
)


# ================================================================
#  1. YANGI ZAKAZ OCHISH
# ================================================================

@router.post(
    "/",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Yangi zakaz ochish",
    description="""
    Yangi ta'mir zakazi ochadi.

    **Majburiy maydonlar:**
    - `problem_description` — nosozlik tavsifi (min 5 belgi)
    - `deadline` — bajarilish muddati (kelajakdagi sana bo'lishi shart)
    - `client_id` yoki `client_name` — mijoz ma'lumoti

    **Deadline qoidasi:**
    O'tgan vaqt kiritilsa `422 Validation Error` qaytariladi.

    **Mijoz logikasi:**
    - `client_id` berilsa — mavjud mijoz ishlatiladi
    - Faqat `client_name` + `client_phone` berilsa — avval telefon bo'yicha
      qidiriladi, topilmasa yangi mijoz yaratiladi
    """,
)
async def create_new_order(
    data: OrderCreateRequest,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    try:
        return await create_order(db, data, current_user)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )


# ================================================================
#  2. ZAKAZLAR RO'YXATI
# ================================================================

@router.get(
    "/",
    response_model=OrderListResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakazlar ro'yxati",
    description="""
    Barcha zakazlar ro'yxatini filtrlash va sahifalash bilan qaytaradi.

    **Filtrlar:**
    - `status` — holat bo'yicha (new, accepted, in_repair, ...)
    - `master_id` — ustaning zakazlari
    - `client_id` — mijozning zakazlari
    - `search` — zakaz raqami, mijoz ismi yoki telefoni bo'yicha
    - `is_archived` — arxivlangan zakazlar (default: false)
    - `only_overdue` — faqat muddati o'tgan zakazlar

    **Sahifalash:**
    - `page` — sahifa raqami (default: 1)
    - `page_size` — sahifadagi elementlar soni (default: 20, max: 100)
    """,
)
async def list_orders(
    current_user: CurrentUser,
    db: DBSession,
    page:         int            = Query(default=1,     ge=1,   description="Sahifa raqami"),
    page_size:    int            = Query(default=20,    ge=1,   le=100, description="Sahifadagi zakazlar soni"),
    status_filter: Optional[OrderStatus] = Query(default=None, alias="status", description="Holat bo'yicha filter"),
    master_id:    Optional[int]  = Query(default=None,  description="Usta ID si bo'yicha filter"),
    client_id:    Optional[int]  = Query(default=None,  description="Mijoz ID si bo'yicha filter"),
    search:       Optional[str]  = Query(default=None,  min_length=2, description="Zakaz raqami yoki mijoz ismi"),
    is_archived:  bool           = Query(default=False, description="Arxivlangan zakazlarni ko'rsatish"),
    only_overdue: bool           = Query(default=False, description="Faqat muddati o'tgan zakazlar"),
) -> OrderListResponse:

    # Usta faqat o'z zakazlarini ko'ra oladi
    from app.database.models import UserRole
    effective_master_id = master_id
    if current_user.role == UserRole.MASTER:
        effective_master_id = current_user.id

    return await get_orders_list(
        db=db,
        page=page,
        page_size=page_size,
        status=status_filter,
        master_id=effective_master_id,
        client_id=client_id,
        search=search,
        is_archived=is_archived,
        only_overdue=only_overdue,
    )


# ================================================================
#  3. STATISTIKA (Dashboard)
# ================================================================

@router.get(
    "/stats",
    response_model=OrderStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Dashboard statistikasi",
    description="""
    Bugungi va umumiy zakaz statistikasini qaytaradi.

    Dashboard bosh sahifasida ko'rsatish uchun:
    - Jami zakazlar soni
    - Yangi / Jarayondagi / Bugun tugallangan
    - Muddati o'tgan zakazlar soni
    - Bugungi daromad
    """,
)
async def order_statistics(
    current_user: CurrentUser,
    db: DBSession,
) -> OrderStatsResponse:
    return await get_order_stats(db)


# ================================================================
#  4. DEADLINE OGOHLANTIRISHLARI
# ================================================================

@router.get(
    "/alerts/deadline",
    response_model=list[OrderDeadlineAlertResponse],
    status_code=status.HTTP_200_OK,
    summary="Deadline ogohlantirishlari",
    description="""
    Muddati o'tgan yoki yaqinlashgan zakazlar ro'yxatini qaytaradi.

    **Ogohlantirish darajalari** (`hours_remaining` qiymatiga qarab):
    | Daraja   | Shart               | Frontend rangi |
    |----------|---------------------|----------------|
    | OVERDUE  | `hours_remaining < 0` | 🔴 Qizil       |
    | CRITICAL | `0 < hours < 2`     | 🟠 To'q sariq  |
    | WARNING  | `2 < hours < 24`    | 🟡 Sariq       |
    | OK       | `hours >= 24`       | ✅ Yashil      |

    Javob eng kritiklari (muddati o'tganlar) birinchi keladi.

    `warning_hours` parametri orqali ogohlantirish chegara vaqtini
    o'zgartirish mumkin (default: 24 soat).
    """,
)
async def deadline_alerts(
    current_user: CurrentUser,
    db: DBSession,
    warning_hours: float = Query(
        default=24.0,
        ge=1.0,
        le=168.0,
        description="Necha soat qolganda ogohlantirish berilsin (1-168 soat, default: 24)"
    ),
) -> list[OrderDeadlineAlertResponse]:
    return await get_deadline_alerts(db, warning_hours=warning_hours)


# ================================================================
#  5. ZAKAZ — RAQAM BO'YICHA  (/{order_id} dan OLDIN bo'lishi shart)
# ================================================================

@router.get(
    "/by-number/{order_number}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakaz raqami bo'yicha topish",
    description="Masalan: `TV-2025-0001`",
)
async def get_order_by_order_number(
    order_number: str,
    current_user: CurrentUser,
    db: DBSession,
) -> OrderResponse:
    order = await get_order_by_number(db, order_number)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: {order_number}",
        )
    return order


# ================================================================
#  6. ZAKAZ — ID BO'YICHA
# ================================================================

@router.get(
    "/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Bitta zakaz ma'lumoti",
    description="ID bo'yicha bitta zakazning to'liq ma'lumoti (status tarixi bilan)",
)
async def get_single_order(
    order_id: int,
    current_user: CurrentUser,
    db: DBSession,
) -> OrderResponse:
    order = await get_order_by_id(db, order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: id={order_id}",
        )
    return order


# ================================================================
#  7. ZAKAZ MA'LUMOTLARINI YANGILASH (PATCH)
# ================================================================

@router.patch(
    "/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakaz ma'lumotlarini yangilash",
    description="""
    Zakaz maydonlarini yangilaydi. **Faqat yuborilgan maydonlar o'zgaradi.**

    Status o'zgartirish uchun bu endpoint ishlatilmaydi —
    buning uchun `POST /{order_id}/status` endpoint'ini ishlating.

    Yangilanishi mumkin bo'lgan maydonlar:
    - TV ma'lumotlari (brand, model, diagonal)
    - Nosozlik va tashxis tavsifi
    - Usta tayinlash (`master_id`)
    - Narxlar (estimated_price, final_price)
    - Deadline (faqat kelajakdagi vaqt)
    """,
)
async def patch_order(
    order_id: int,
    data: OrderUpdateRequest,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    result = await update_order(db, order_id, data, current_user)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: id={order_id}",
        )
    return result


# ================================================================
#  8. STATUS O'ZGARTIRISH
# ================================================================

@router.post(
    "/{order_id}/status",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Status o'zgartirish",
    description="""
    Zakaz statusini o'zgartiradi. Har bir o'zgarish **tarixga yoziladi**.

    **Ruxsat etilgan o'tishlar:**
    ```
    new        → accepted, cancelled
    accepted   → diagnosing, cancelled
    diagnosing → waiting, in_repair, cancelled
    waiting    → in_repair, cancelled
    in_repair  → done, waiting, cancelled
    done       → delivered, cancelled
    delivered  → (yakuniy — o'zgartirib bo'lmaydi)
    cancelled  → (yakuniy — o'zgartirib bo'lmaydi)
    ```

    **Eslatma:** `cancelled` holatiga o'tkazilsa, zakaz avtomatik
    arxivlanadi va `cancel_reason` saqlanadi.
    """,
)
async def change_order_status(
    order_id: int,
    data: OrderStatusUpdateRequest,
    current_user: CurrentUser,
    db: DBSession,
) -> OrderResponse:
    result, error = await update_order_status(db, order_id, data, current_user)

    if error:
        # "topilmadi" xatosi 404, qolganlar 400
        status_code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)

    return result


# ================================================================
#  9. TO'LOV QABUL QILISH
# ================================================================

@router.post(
    "/{order_id}/payment",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="To'lov qabul qilish",
    description="""
    Zakaz to'lovini qabul qiladi va statusni **`delivered`** ga o'tkazadi.

    **Shartlar:**
    - Zakaz `done` holatida bo'lishi shart
    - Zakaz hali to'lanmagan bo'lishi shart

    **Avtomatik bajariladi:**
    - `is_paid = True`
    - `delivered_at` vaqt stampini saqlaydi
    - Kassa jadvaliga **kirim** yozadi
    - Usta balansiga **komisyon** qo'shadi (agar foiz belgilangan bo'lsa)
    - Status tarixiga yozadi
    """,
)
async def accept_payment(
    order_id: int,
    data: OrderPaymentRequest,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    result, error = await process_payment(db, order_id, data, current_user)

    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)

    return result


# ================================================================
#  10. ARXIVLASH (Tugallangan zakazni arxivga o'tkazish)
# ================================================================

@router.post(
    "/{order_id}/archive",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakazni arxivlash",
    description="""
    Tugallangan zakazni arxivga o'tkazadi.

    **Shartlar:**
    - Faqat `delivered` yoki `cancelled` holatidagi zakazlar arxivlanadi
    - Allaqachon arxivlangan bo'lsa xato qaytariladi

    Arxivlangan zakazlar asosiy ro'yxatda ko'rinmaydi,
    lekin `is_archived=true` filter bilan topish mumkin.
    """,
)
async def archive_order(
    order_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    # Zakazni topish
    order_resp = await get_order_by_id(db, order_id)
    if not order_resp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: id={order_id}",
        )

    # Arxivlash shartlarini tekshirish
    archivable = {OrderStatus.DELIVERED, OrderStatus.CANCELLED}
    if order_resp.status not in archivable:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Faqat 'delivered' yoki 'cancelled' holatidagi zakazlar arxivlanadi. "
                f"Hozirgi holat: '{order_resp.status.value}'"
            ),
        )

    if order_resp.is_archived:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu zakaz allaqachon arxivlangan",
        )

    # Arxivlash — to'g'ridan-to'g'ri DB da
    from sqlalchemy import update as sa_update
    from app.database.models import Order
    await db.execute(
        sa_update(Order)
        .where(Order.id == order_id)
        .values(is_archived=True)
    )
    await db.commit()

    logger.info(
        f"📦 Arxivlandi: order_id={order_id} | "
        f"Kim: {current_user.username}"
    )

    # Yangilangan zakazni qaytarish
    fresh = await get_order_by_id(db, order_id)
    return fresh
