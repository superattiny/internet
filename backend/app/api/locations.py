# ================================================
# api/locations.py — Geolokatsiya API Router
#
# Endpoint'lar ro'yxati:
#
#  [Mobil ilova → Server]
#   POST /api/v1/locations/ping              → Koordinata jo'natish (fon rejimi)
#   POST /api/v1/locations/visit/start       → Vizit boshlash
#   POST /api/v1/locations/visit/end         → Vizit yakunlash
#
#  [Admin/Operator → Server]
#   GET  /api/v1/locations/active            → Barcha faol ustalar xaritasi
#   GET  /api/v1/locations/workers/{id}/current  → Bitta ustaning oxirgi joylashuvi
#   GET  /api/v1/locations/workers/{id}/trek     → Ustaning vizit trekı
#   GET  /api/v1/locations/workers/{id}/history  → Koordinata tarixi (sahifalash)
# ================================================

from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status, Request

from app.schemas.location import (
    LocationPingRequest,
    VisitStartRequest,
    VisitEndRequest,
    LocationPingResponse,
    WorkerCurrentLocationResponse,
    WorkerTrekResponse,
    ActiveWorkerMapResponse,
    VisitStartResponse,
    VisitEndResponse,
    LocationPointResponse,
)
from app.services.location_service import (
    save_location_ping,
    start_visit,
    end_visit,
    get_worker_current_location,
    get_all_active_workers_locations,
    get_worker_trek,
    TREK_DEFAULT_HOURS,
)
from app.utils.dependencies import (
    CurrentUser,
    AdminUser,
    OperatorOrAdminUser,
    AnyAuthenticatedUser,
    DBSession,
)
from app.database.models import UserRole
from app.utils.logger import logger


# ================================================================
#  ROUTER
# ================================================================

router = APIRouter(
    prefix="/locations",
    tags=["📍 Locations — Geolokatsiya va Vizitlar"],
    responses={
        401: {"description": "Avtorizatsiya talab qilinadi"},
        403: {"description": "Bu amal uchun ruxsat yo'q"},
    },
)


# ================================================================
#  MOBIL ILOVA ENDPOINT'LARI
#  (Usta telefoni fon rejimda shu portlarga jo'natadi)
# ================================================================

@router.post(
    "/ping",
    response_model=LocationPingResponse,
    status_code=status.HTTP_200_OK,
    summary="Koordinata jo'natish [Mobil ilova]",
    description="""
    Mobil ilova **fon rejimida** har N sekundda shu endpoint'ga
    koordinata jo'natib turadi.

    **Ishlash tartibi:**
    1. Usta tizimga kiradi → JWT token oladi
    2. Vizit boshlanadi (`POST /visit/start`)
    3. Ilova fonda **15 soniyada bir** shu portga ping jo'natadi
    4. Server `next_ping_seconds` qaytaradi → ilova shuga moslashadi
    5. Vizit yakunlanadi (`POST /visit/end`)

    **Adaptiv interval:**
    | Batareya | Interval |
    |----------|----------|
    | ≥ 30%    | 15 sek   |
    | 10–29%   | 30 sek   |
    | < 10%    | 60 sek   |

    **Koordinata validatsiyasi:**
    O'zbekiston hududi tekshiriladi (lat: 36–46°, lon: 55–74°).
    Tashqarida bo'lsa `422` xato qaytariladi.

    **Eslatma:** `order_id` ixtiyoriy — berilmasa server
    ustaning joriy `on_the_way` zakazini avtomatik topadi.
    """,
)
async def location_ping(
    data: LocationPingRequest,
    current_user: AnyAuthenticatedUser,
    request: Request,
    db: DBSession,
) -> LocationPingResponse:
    """
    Mobil ilovadan koordinata qabul qilish.
    Barcha autentifikatsiya qilingan foydalanuvchilar uchun.
    """
    # Faqat Usta yoki Admin jo'natishi mumkin
    if current_user.role == UserRole.OPERATOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operator koordinata jo'natishi mumkin emas",
        )

    result, error = await save_location_ping(db, current_user, data)
    if error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error,
        )
    return result


@router.post(
    "/visit/start",
    response_model=VisitStartResponse,
    status_code=status.HTTP_200_OK,
    summary="Vizit boshlash [Mobil ilova]",
    description="""
    Usta mijoznikiga vizitga otishdan oldin bu endpoint'ni chaqiradi.

    **Avtomatik bajariladi:**
    - Zakaz statusi → `on_the_way`
    - `OrderStatusHistory` ga yozuv qo'shiladi
    - Birinchi koordinata saqlanadi
    - Geolokatsiya fon rejimi yoqiladi

    **Ruxsat etilgan holatllar (qaysi statusdan o'tish mumkin):**
    `accepted` → `diagnosing` → `waiting` → `on_the_way`

    **Mobil UX tavsiyasi:**
    Usta "Yo'lga chiqdim" tugmasini bosadi →
    ilova shu endpoint'ni chaqiradi →
    fon lokatsiya xizmati avtomatik yoqiladi.
    """,
)
async def begin_visit(
    data: VisitStartRequest,
    current_user: AnyAuthenticatedUser,
    db: DBSession,
) -> VisitStartResponse:
    if current_user.role == UserRole.OPERATOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operator vizit boshlay olmaydi",
        )

    result, error = await start_visit(db, current_user, data)
    if error:
        code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=code, detail=error)
    return result


@router.post(
    "/visit/end",
    response_model=VisitEndResponse,
    status_code=status.HTTP_200_OK,
    summary="Vizit yakunlash [Mobil ilova]",
    description="""
    Usta mijoz uyiga yetib, ta'mirni boshlashdan oldin shu endpoint'ni chaqiradi.

    **Avtomatik bajariladi:**
    - Zakaz statusi: `on_the_way` → `in_repair`
    - `OrderStatusHistory` ga yozuv qo'shiladi
    - Oxirgi koordinata saqlanadi
    - Vizit trekining umumiy nuqtalar soni qaytariladi

    **Mobil UX tavsiyasi:**
    Usta "Yetib keldim" tugmasini bosadi →
    ilova shu endpoint'ni chaqiradi →
    fon lokatsiya xizmati to'xtatilishi mumkin.
    """,
)
async def finish_visit(
    data: VisitEndRequest,
    current_user: AnyAuthenticatedUser,
    db: DBSession,
) -> VisitEndResponse:
    if current_user.role == UserRole.OPERATOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operator vizit yakunlay olmaydi",
        )

    result, error = await end_visit(db, current_user, data)
    if error:
        code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=code, detail=error)
    return result


# ================================================================
#  ADMIN / OPERATOR NAZORAT ENDPOINT'LARI
#  (Web panel xaritasi uchun)
# ================================================================

@router.get(
    "/active",
    response_model=ActiveWorkerMapResponse,
    status_code=status.HTTP_200_OK,
    summary="Barcha faol ustalar xaritasi [Admin/Operator]",
    description="""
    Hozirda **`on_the_way`** holatidagi barcha ustalarning
    oxirgi joylashuvini qaytaradi.

    **Frontend xarita uchun:**
    - Sahifa yuklanganda bir marta chaqiriladi
    - Keyin **15 soniyada bir** polling bilan yangilanadi
    - Har bir usta uchun xaritada marker ko'rsatiladi

    **`is_stale` maydoni:**
    Agar ustadan 5 daqiqadan ko'p vaqt o'tgan bo'lsa `true` —
    frontend markerini kulrang/sovuq rang bilan ko'rsatishi mumkin.

    **`seconds_since_update`** — oxirgi pingdan qancha soniya o'tgani.
    """,
)
async def active_workers_map(
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> ActiveWorkerMapResponse:
    return await get_all_active_workers_locations(db)


@router.get(
    "/workers/{worker_id}/current",
    response_model=WorkerCurrentLocationResponse,
    status_code=status.HTTP_200_OK,
    summary="Bitta ustaning oxirgi joylashuvi",
    description="""
    ID bo'yicha bitta ustaning **eng oxirgi** saqlangan
    koordinatasini qaytaradi.

    **Qaytaradi:**
    - Koordinata (lat, lon) + GPS aniqligi
    - Qaysi zakaz uchun ekanligi
    - Mijoz nomi va manzili
    - Batareya darajasi
    - Oxirgi yangilanish vaqti va `is_stale` holati

    Agar ushbu ustadan hech qachon koordinata kelmagan bo'lsa
    `404` qaytariladi.
    """,
)
async def worker_current_location(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> WorkerCurrentLocationResponse:
    result = await get_worker_current_location(db, worker_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Usta id={worker_id} uchun hech qanday joylashuv ma'lumoti "
                f"topilmadi. Usta hali koordinata jo'natmagan bo'lishi mumkin."
            ),
        )
    return result


@router.get(
    "/workers/{worker_id}/trek",
    response_model=WorkerTrekResponse,
    status_code=status.HTTP_200_OK,
    summary="Ustaning vizit trekı (marshrutı)",
    description="""
    Ustaning bitta vizit uchun **to'liq harakatlanish yo'lini**
    (trek) qaytaradi. Xaritada chiziq sifatida ko'rsatiladi.

    **Parametrlar:**
    - `order_id` — qaysi zakaz viziti (ixtiyoriy, berilmasa oxirgi vizit)
    - `hours`    — necha soat orqasiga qaralsin (1–168, default: 24)

    **Trek statistikasi:**
    - Boshlash va tugash vaqti
    - Davomiylik (daqiqalarda)
    - Taxminiy bosib o'tilgan masofa (km, Haversine formulasi)
    - Nuqtalar soni

    **Frontend tavsiyasi:**
    Nuqtalarni `polyline` sifatida chizing, tezlikka qarab
    rangini o'zgartiring (qizil = tez, yashil = sekin).
    """,
)
async def worker_trek(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
    order_id: Optional[int] = Query(
        default=None,
        description="Zakaz ID si (berilmasa — oxirgi vizit)",
    ),
    hours: int = Query(
        default=TREK_DEFAULT_HOURS,
        ge=1,
        le=168,
        description="Necha soat orqasiga (1–168, default: 24)",
    ),
) -> WorkerTrekResponse:
    result = await get_worker_trek(
        db=db,
        worker_id=worker_id,
        order_id=order_id,
        hours=hours,
    )
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Usta id={worker_id} topilmadi",
        )
    return result


@router.get(
    "/workers/{worker_id}/history",
    response_model=list[LocationPointResponse],
    status_code=status.HTTP_200_OK,
    summary="Koordinata tarixi (sahifalash bilan)",
    description="""
    Ustaning koordinata yozuvlarini sahifalash bilan qaytaradi.
    Debug va audit maqsadida ishlatiladi.

    **Filtrlar:**
    - `order_id` — faqat shu zakaz uchun yozuvlar
    - `limit`    — nechta yozuv (max: 500)
    - `offset`   — qayerdan boshlansin

    Yozuvlar **yangilikdan eskiga** (desc) tartiblangan qaytariladi.
    """,
)
async def worker_location_history(
    worker_id: int,
    current_user: AdminUser,
    db: DBSession,
    order_id: Optional[int] = Query(default=None),
    limit:    int = Query(default=100, ge=1, le=500),
    offset:   int = Query(default=0,   ge=0),
) -> list[LocationPointResponse]:
    from sqlalchemy import select, and_
    from app.database.models import WorkerLocation

    filters = [WorkerLocation.worker_id == worker_id]
    if order_id:
        filters.append(WorkerLocation.order_id == order_id)

    result = await db.execute(
        select(WorkerLocation)
        .where(and_(*filters))
        .order_by(WorkerLocation.recorded_at.desc())
        .offset(offset)
        .limit(limit)
    )
    locations = result.scalars().all()

    return [
        LocationPointResponse(
            id=loc.id,
            latitude=loc.latitude,
            longitude=loc.longitude,
            accuracy=loc.accuracy,
            speed=loc.speed,
            bearing=loc.bearing,
            battery_level=loc.battery_level,
            location_provider=loc.location_provider,
            device_time=loc.device_time,
            recorded_at=loc.recorded_at,
        )
        for loc in locations
    ]
