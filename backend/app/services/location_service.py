# ================================================
# services/location_service.py — Geolokatsiya biznes logikasi
#
# Tarkib:
#   1. save_location_ping  — koordinata saqlash (asosiy funksiya)
#   2. start_visit         — vizit boshlash (on_the_way + 1-koordinata)
#   3. end_visit           — vizit yakunlash (in_repair + tarix)
#   4. get_worker_current  — ustaning oxirgi joylashuvi
#   5. get_all_active      — barcha on_the_way ustalar (xarita uchun)
#   6. get_worker_trek     — bitta vizit marshrutı
#   7. adaptive_ping_interval — batareyaga qarab interval maslahat
#   8. _haversine_distance — ikkita koordinata orasidagi masofa
# ================================================

import math
from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from sqlalchemy.orm import selectinload

from app.database.models import (
    WorkerLocation,
    Order, OrderStatus,
    OrderStatusHistory,
    User, UserRole,
    Client,
)
from app.schemas.location import (
    LocationPingRequest,
    VisitStartRequest,
    VisitEndRequest,
    LocationPingResponse,
    WorkerCurrentLocationResponse,
    LocationPointResponse,
    WorkerTrekResponse,
    ActiveWorkerMapResponse,
    VisitStartResponse,
    VisitEndResponse,
)
from app.utils.helpers import utc_now
from app.utils.logger import logger


# ================================================================
#  SOZLAMALAR
# ================================================================

# Ping intervallari (soniya)
PING_INTERVAL_NORMAL   = 15   # Oddiy holat
PING_INTERVAL_SLOW     = 30   # Batareya 30% dan past
PING_INTERVAL_CRITICAL = 60   # Batareya 10% dan past

# "Eskirgan" joylashuv — shu vaqtdan ko'p o'tgan bo'lsa stale
STALE_THRESHOLD_SECONDS = 300   # 5 daqiqa

# Usta vizit yakunlanganda qancha vaqtdagi trek ko'rsatilsin
TREK_DEFAULT_HOURS = 24


# ================================================================
#  1. KOORDINATA SAQLASH (asosiy funksiya)
# ================================================================

async def save_location_ping(
    db: AsyncSession,
    worker: User,
    data: LocationPingRequest,
) -> tuple[Optional[LocationPingResponse], Optional[str]]:
    """
    Mobil ilovadan kelgan koordinatani saqlaydi.

    Tekshiruvlar:
      1. Usta aktiv bo'lishi shart
      2. order_id berilgan bo'lsa — ushbu zakaz ustaga tegishli
         va on_the_way holatida bo'lishi shart
      3. Aks holda: usta hozir on_the_way holatidagi biror
         zakaziga bog'laydi (order_id null bo'lsa ham)

    Adaptiv interval:
      - Batareya < 10%: 60 sek
      - Batareya < 30%: 30 sek
      - Oddiy:          15 sek

    Returns:
        (LocationPingResponse, None)   — saqlandi
        (None, "xato sababi")          — xatolik
    """
    if not worker.is_active:
        return None, "Hisobingiz bloklangan"

    # order_id tekshiruvi
    effective_order_id = data.order_id
    if effective_order_id:
        order_check = await db.execute(
            select(Order).where(
                and_(
                    Order.id == effective_order_id,
                    Order.master_id == worker.id,
                )
            )
        )
        order = order_check.scalar_one_or_none()
        if not order:
            return None, (
                f"Zakaz id={effective_order_id} sizga tegishli emas "
                f"yoki topilmadi"
            )
    else:
        # Ustaning joriy on_the_way zakazini avtomatik topamiz
        active_order = await db.execute(
            select(Order).where(
                and_(
                    Order.master_id == worker.id,
                    Order.status == OrderStatus.ON_THE_WAY,
                )
            ).order_by(Order.updated_at.desc()).limit(1)
        )
        found = active_order.scalar_one_or_none()
        effective_order_id = found.id if found else None

    # Koordinatani saqlash
    loc = WorkerLocation(
        worker_id=worker.id,
        order_id=effective_order_id,
        latitude=data.latitude,
        longitude=data.longitude,
        accuracy=data.accuracy,
        speed=data.speed,
        bearing=data.bearing,
        altitude=data.altitude,
        location_provider=data.location_provider or "gps",
        battery_level=data.battery_level,
        device_time=data.device_time,
    )
    db.add(loc)
    await db.commit()
    await db.refresh(loc)

    # Adaptiv ping intervali
    next_interval = adaptive_ping_interval(data.battery_level)

    logger.debug(
        f"📍 Koordinata saqlandi: worker={worker.username} "
        f"({data.latitude:.5f}, {data.longitude:.5f}) "
        f"order={effective_order_id} "
        f"battery={data.battery_level}%"
    )

    return LocationPingResponse(
        success=True,
        location_id=loc.id,
        next_ping_seconds=next_interval,
    ), None


# ================================================================
#  2. VIZIT BOSHLASH
# ================================================================

async def start_visit(
    db: AsyncSession,
    worker: User,
    data: VisitStartRequest,
) -> tuple[Optional[VisitStartResponse], Optional[str]]:
    """
    Usta vizitni rasman boshlaydi.

    Mantiq:
      1. Zakaz mavjudligini va ustaga tegishliligini tekshiradi
      2. Zakaz ACCEPTED yoki DIAGNOSING holatida bo'lishi kerak
      3. Status → ON_THE_WAY ga o'tkazadi
      4. OrderStatusHistory ga yozadi
      5. Birinchi koordinatani saqlaydi
    """
    # Zakazni topish
    order_result = await db.execute(
        select(Order).where(
            and_(
                Order.id == data.order_id,
                Order.master_id == worker.id,
            )
        )
    )
    order = order_result.scalar_one_or_none()
    if not order:
        return None, f"Zakaz id={data.order_id} sizga tegishli emas yoki topilmadi"

    # Allaqachon yo'lda bo'lsa
    if order.status == OrderStatus.ON_THE_WAY:
        return None, f"Siz allaqachon bu zakaz uchun yo'ldasiz: {order.order_number}"

    # Ruxsat etilgan statuslar
    allowed_from = {
        OrderStatus.ACCEPTED,
        OrderStatus.DIAGNOSING,
        OrderStatus.WAITING,
    }
    if order.status not in allowed_from:
        return None, (
            f"Vizitni '{order.status.value}' holatidan boshlab bo'lmaydi. "
            f"Ruxsat etilganlar: {[s.value for s in allowed_from]}"
        )

    old_status = order.status

    # Status o'zgartirish
    order.status = OrderStatus.ON_THE_WAY

    # Tarixga yozish
    history = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=worker.id,
        old_status=old_status,
        new_status=OrderStatus.ON_THE_WAY,
        comment=data.notes or "Usta vizitga yo'lga chiqdi",
    )
    db.add(history)

    # Birinchi koordinata
    first_loc = WorkerLocation(
        worker_id=worker.id,
        order_id=order.id,
        latitude=data.latitude,
        longitude=data.longitude,
        location_provider="gps",
    )
    db.add(first_loc)

    await db.commit()
    await db.refresh(first_loc)

    logger.info(
        f"🚗 Vizit boshlandi: usta={worker.full_name} | "
        f"zakaz={order.order_number} | "
        f"holat: {old_status.value} → on_the_way | "
        f"boshlang'ich koordinata: ({data.latitude:.5f}, {data.longitude:.5f})"
    )

    return VisitStartResponse(
        success=True,
        message=f"Vizit boshlandi! {order.order_number} zakazi uchun geolokatsiya yoqildi.",
        order_id=order.id,
        order_number=order.order_number,
        order_status=OrderStatus.ON_THE_WAY,
        location_id=first_loc.id,
    ), None


# ================================================================
#  3. VIZIT YAKUNLASH
# ================================================================

async def end_visit(
    db: AsyncSession,
    worker: User,
    data: VisitEndRequest,
) -> tuple[Optional[VisitEndResponse], Optional[str]]:
    """
    Usta mijoz uyiga yetib, ta'mirni boshlamoqchi.

    Mantiq:
      1. Zakaz ON_THE_WAY holatida bo'lishi kerak
      2. Oxirgi koordinatani saqlaydi
      3. Status → IN_REPAIR ga o'tkazadi
      4. OrderStatusHistory ga yozadi
      5. Vizit davomida yig'ilgan nuqtalar sonini qaytaradi
    """
    order_result = await db.execute(
        select(Order).where(
            and_(
                Order.id == data.order_id,
                Order.master_id == worker.id,
            )
        )
    )
    order = order_result.scalar_one_or_none()
    if not order:
        return None, f"Zakaz id={data.order_id} sizga tegishli emas yoki topilmadi"

    if order.status != OrderStatus.ON_THE_WAY:
        return None, (
            f"Vizitni yakunlash uchun zakaz 'on_the_way' holatida bo'lishi kerak. "
            f"Hozirgi holat: '{order.status.value}'"
        )

    # Oxirgi koordinatani saqlash
    last_loc = WorkerLocation(
        worker_id=worker.id,
        order_id=order.id,
        latitude=data.latitude,
        longitude=data.longitude,
        location_provider="gps",
    )
    db.add(last_loc)
    await db.flush()

    # Status → IN_REPAIR
    order.status = OrderStatus.IN_REPAIR

    history = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=worker.id,
        old_status=OrderStatus.ON_THE_WAY,
        new_status=OrderStatus.IN_REPAIR,
        comment=data.notes or "Usta yetib keldi, ta'mir boshlandi",
    )
    db.add(history)

    await db.commit()

    # Vizit davomida yig'ilgan nuqtalar soni
    count_result = await db.execute(
        select(func.count(WorkerLocation.id)).where(
            and_(
                WorkerLocation.worker_id == worker.id,
                WorkerLocation.order_id == order.id,
            )
        )
    )
    total_points = count_result.scalar_one()

    logger.info(
        f"🏁 Vizit yakunlandi: usta={worker.full_name} | "
        f"zakaz={order.order_number} | "
        f"on_the_way → in_repair | "
        f"trek nuqtalari: {total_points} ta"
    )

    return VisitEndResponse(
        success=True,
        message=f"Yetib keldingiz! {order.order_number} zakazi uchun ta'mir boshlandi.",
        order_id=order.id,
        order_number=order.order_number,
        order_status=OrderStatus.IN_REPAIR,
        total_points=total_points,
    ), None


# ================================================================
#  4. USTANING OXIRGI JOYLASHUVI
# ================================================================

async def get_worker_current_location(
    db: AsyncSession,
    worker_id: int,
) -> Optional[WorkerCurrentLocationResponse]:
    """
    Ustaning eng oxirgi saqlangan koordinatasini qaytaradi.
    Admin xaritasidagi marker ma'lumoti uchun.
    """
    # Eng oxirgi koordinata
    loc_result = await db.execute(
        select(WorkerLocation)
        .where(WorkerLocation.worker_id == worker_id)
        .order_by(WorkerLocation.recorded_at.desc())
        .limit(1)
    )
    loc = loc_result.scalar_one_or_none()
    if not loc:
        return None

    # Usta ma'lumoti
    worker_result = await db.execute(
        select(User).where(User.id == worker_id)
    )
    worker = worker_result.scalar_one_or_none()
    if not worker:
        return None

    # Zakaz va mijoz ma'lumoti
    order_number  = None
    order_status  = None
    client_name   = None
    client_address = None

    if loc.order_id:
        order_result = await db.execute(
            select(Order)
            .options(selectinload(Order.client))
            .where(Order.id == loc.order_id)
        )
        order = order_result.scalar_one_or_none()
        if order:
            order_number  = order.order_number
            order_status  = order.status
            client_name   = order.client.full_name if order.client else None
            client_address = order.client.address if order.client else None

    # Qancha vaqt o'tgan
    now = utc_now()
    recorded_aware = loc.recorded_at
    if recorded_aware.tzinfo is None:
        recorded_aware = recorded_aware.replace(tzinfo=timezone.utc)

    seconds_ago = int((now - recorded_aware).total_seconds())
    is_stale    = seconds_ago > STALE_THRESHOLD_SECONDS

    return WorkerCurrentLocationResponse(
        worker_id=worker.id,
        worker_name=worker.full_name,
        worker_phone=worker.phone,
        latitude=loc.latitude,
        longitude=loc.longitude,
        accuracy=loc.accuracy,
        speed=loc.speed,
        bearing=loc.bearing,
        recorded_at=recorded_aware,
        order_id=loc.order_id,
        order_number=order_number,
        order_status=order_status,
        client_name=client_name,
        client_address=client_address,
        battery_level=loc.battery_level,
        location_provider=loc.location_provider,
        seconds_since_update=seconds_ago,
        is_stale=is_stale,
    )


# ================================================================
#  5. BARCHA FAOL USTALAR JOYLASHUVI (xarita uchun)
# ================================================================

async def get_all_active_workers_locations(
    db: AsyncSession,
) -> ActiveWorkerMapResponse:
    """
    Hozirda ON_THE_WAY holatidagi barcha ustalarning
    oxirgi koordinatalarini qaytaradi.

    Admin xaritasi sahifasi yuklanganda chaqiriladi.
    Keyin frontend 15 soniyada bir polling qilishi mumkin.
    """
    # ON_THE_WAY holatidagi zakazlardagi ustalar
    active_orders_result = await db.execute(
        select(Order.master_id)
        .where(
            and_(
                Order.status == OrderStatus.ON_THE_WAY,
                Order.master_id.isnot(None),
            )
        )
        .distinct()
    )
    active_worker_ids = [row[0] for row in active_orders_result.all()]

    workers_data = []
    for worker_id in active_worker_ids:
        loc_resp = await get_worker_current_location(db, worker_id)
        if loc_resp:
            workers_data.append(loc_resp)

    logger.debug(f"🗺️  Faol ustalar xaritasi: {len(workers_data)} ta usta")

    return ActiveWorkerMapResponse(
        total_active=len(workers_data),
        workers=workers_data,
        generated_at=utc_now(),
    )


# ================================================================
#  6. BITTA VIZIT TREKINI OLISH
# ================================================================

async def get_worker_trek(
    db: AsyncSession,
    worker_id: int,
    order_id: Optional[int] = None,
    hours: int = TREK_DEFAULT_HOURS,
) -> Optional[WorkerTrekResponse]:
    """
    Ustaning vizit marshrutini (trek) qaytaradi.

    Args:
        worker_id : Usta ID
        order_id  : Qaysi zakaz viziti (None = oxirgi vizit)
        hours     : Necha soat orqasiga qaralsin (default: 24)

    Qaytaradi:
        Trek nuqtalari + masofa + davomiylik statistikasi
    """
    worker_result = await db.execute(
        select(User).where(User.id == worker_id)
    )
    worker = worker_result.scalar_one_or_none()
    if not worker:
        return None

    since = utc_now() - timedelta(hours=hours)

    # Filtr qurish
    filters = [
        WorkerLocation.worker_id == worker_id,
        WorkerLocation.recorded_at >= since,
    ]
    if order_id:
        filters.append(WorkerLocation.order_id == order_id)

    loc_result = await db.execute(
        select(WorkerLocation)
        .where(and_(*filters))
        .order_by(WorkerLocation.recorded_at.asc())
    )
    locations = loc_result.scalars().all()

    if not locations:
        return WorkerTrekResponse(
            worker_id=worker_id,
            worker_name=worker.full_name,
            order_id=order_id,
        )

    # Zakaz raqami
    order_number = None
    effective_order_id = order_id or locations[0].order_id
    if effective_order_id:
        ord_r = await db.execute(
            select(Order.order_number).where(Order.id == effective_order_id)
        )
        row = ord_r.first()
        order_number = row[0] if row else None

    # Trek nuqtalari
    points = [
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

    # Statistika
    trek_start = locations[0].recorded_at
    trek_end   = locations[-1].recorded_at

    start_aware = trek_start if trek_start.tzinfo else trek_start.replace(tzinfo=timezone.utc)
    end_aware   = trek_end   if trek_end.tzinfo   else trek_end.replace(tzinfo=timezone.utc)
    duration_min = (end_aware - start_aware).total_seconds() / 60

    # Taxminiy masofa (Haversine formula)
    total_distance_km = 0.0
    for i in range(1, len(locations)):
        total_distance_km += _haversine_distance(
            locations[i - 1].latitude, locations[i - 1].longitude,
            locations[i].latitude,     locations[i].longitude,
        )

    return WorkerTrekResponse(
        worker_id=worker_id,
        worker_name=worker.full_name,
        order_id=effective_order_id,
        order_number=order_number,
        points=points,
        total_points=len(points),
        trek_start=start_aware,
        trek_end=end_aware,
        duration_minutes=round(duration_min, 1),
        distance_km=round(total_distance_km, 2),
    )


# ================================================================
#  7. ADAPTIV PING INTERVALI
# ================================================================

def adaptive_ping_interval(battery_level: Optional[int]) -> int:
    """
    Batareya darajasiga qarab keyingi ping intervalini (soniya) qaytaradi.

    Mantiq:
      - Batareya noma'lum  → 15 sek (normal)
      - Batareya >= 30%    → 15 sek (normal)
      - Batareya 10–29%    → 30 sek (tejamkor)
      - Batareya < 10%     → 60 sek (kritik)

    Mobil ilova bu qiymatni olib, keyingi pingni shunga qarab yuboradi.
    """
    if battery_level is None:
        return PING_INTERVAL_NORMAL

    if battery_level < 10:
        return PING_INTERVAL_CRITICAL
    elif battery_level < 30:
        return PING_INTERVAL_SLOW
    else:
        return PING_INTERVAL_NORMAL


# ================================================================
#  8. HAVERSINE MASOFA FORMULASI
# ================================================================

def _haversine_distance(
    lat1: float, lon1: float,
    lat2: float, lon2: float,
) -> float:
    """
    Yer shari yuzasidagi ikkita koordinata orasidagi masofani
    km da hisoblaydi (Haversine formulasi).

    Aniqlik: ±0.5% (GPS xatosi bilan birgalikda yetarli)

    Args:
        lat1, lon1 : Birinchi nuqta (gradus)
        lat2, lon2 : Ikkinchi nuqta (gradus)

    Returns:
        Masofa (km)
    """
    R = 6371.0   # Yer radiusi (km)

    phi1    = math.radians(lat1)
    phi2    = math.radians(lat2)
    d_phi   = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c
