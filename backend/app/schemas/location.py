# ================================================
# schemas/location.py — Geolokatsiya Pydantic modellari
#
# So'rov (Request) va Javob (Response) formatlari:
#   - Mobil ilovadan koordinata qabul qilish
#   - Admin uchun ustaning joylashuvi ko'rsatish
#   - Vizit marshrutini (trek) ko'rsatish
# ================================================

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator

from app.database.models import OrderStatus


# ================================================================
#  REQUEST SCHEMALAR — Mobil ilovadan keladi
# ================================================================

class LocationPingRequest(BaseModel):
    """
    Mobil ilova fon rejimida har N sekundda shu formatda
    POST /api/v1/locations/ping ga jo'natadi.

    Barcha maydonlar izohlangan — mobil dasturchi uchun.
    """

    # --- Majburiy maydonlar ---
    latitude: float = Field(
        ...,
        ge=-90.0,
        le=90.0,
        description="Kenglik (WGS84). O'zbekiston: 37.2 – 45.6",
        examples=[41.2995]
    )
    longitude: float = Field(
        ...,
        ge=-180.0,
        le=180.0,
        description="Uzunlik (WGS84). O'zbekiston: 56.0 – 73.1",
        examples=[69.2401]
    )

    # --- Ixtiyoriy GPS maydonlari ---
    accuracy: Optional[float] = Field(
        default=None,
        ge=0.0,
        description="GPS aniqligi (metrda). Masalan: 5.0 = ±5 metr. "
                    "Yuqori bo'lsa (>50m) — network/wifi orqali aniqlangan"
    )
    speed: Optional[float] = Field(
        default=None,
        ge=0.0,
        description="Tezlik (m/s). 8.3 m/s ≈ 30 km/h. "
                    "Harakatsiz bo'lsa 0.0 yoki null"
    )
    bearing: Optional[float] = Field(
        default=None,
        ge=0.0,
        lt=360.0,
        description="Yo'nalish (gradus). 0=Shimol, 90=Sharq, 180=Janub, 270=G'arb"
    )
    altitude: Optional[float] = Field(
        default=None,
        description="Balandlik (metr, dengiz sathidan). "
                    "Toshkent o'rtacha: ~455 metr"
    )

    # --- Qurilma va manba ma'lumotlari ---
    location_provider: Optional[str] = Field(
        default="gps",
        max_length=20,
        description="Koordinata manba: 'gps' | 'network' | 'passive'. "
                    "gps = eng aniq, network = wifi/mobil, passive = past aniqlik"
    )
    battery_level: Optional[int] = Field(
        default=None,
        ge=0,
        le=100,
        description="Qurilma batareya darajasi (0-100%). "
                    "Server batareya past bo'lsa jo'natish intervalini uzaytirishi mumkin"
    )

    # --- Qurilma vaqti ---
    device_time: Optional[datetime] = Field(
        default=None,
        description="Qurilmaning mahalliy vaqti (ISO 8601). "
                    "Server vaqtidan farq qilsa tekshirish uchun ishlatiladi. "
                    "Oflayn to'plangan yozuvlar uchun muhim"
    )

    # --- Zakaz bog'lanishi ---
    order_id: Optional[int] = Field(
        default=None,
        description="Qaysi zakaz viziti uchun koordinata jo'natilmoqda. "
                    "Null bo'lsa — usta umumiy on_the_way holatida"
    )

    @field_validator("latitude")
    @classmethod
    def validate_latitude_uzbekistan(cls, v: float) -> float:
        """
        O'zbekiston hududini taxminiy tekshirish.
        Juda uzoq koordinatalar (xato qurilma) ni filtrlash uchun.
        Oraliq biroz keng qoldirildi (chegara hududlar uchun).
        """
        if not (36.0 <= v <= 46.0):
            raise ValueError(
                f"Latitude {v} O'zbekiston hududidan tashqarida (36.0–46.0). "
                f"GPS xato yoki qurilma muammosi bo'lishi mumkin."
            )
        return round(v, 8)   # 8 xona aniqlik ≈ 1 mm

    @field_validator("longitude")
    @classmethod
    def validate_longitude_uzbekistan(cls, v: float) -> float:
        """Longitude O'zbekiston hududi tekshiruvi"""
        if not (55.0 <= v <= 74.0):
            raise ValueError(
                f"Longitude {v} O'zbekiston hududidan tashqarida (55.0–74.0). "
                f"GPS xato yoki qurilma muammosi bo'lishi mumkin."
            )
        return round(v, 8)

    model_config = {
        "json_schema_extra": {
            "example": {
                "latitude":          41.2995,
                "longitude":         69.2401,
                "accuracy":          8.5,
                "speed":             5.2,
                "bearing":           45.0,
                "altitude":          455.0,
                "location_provider": "gps",
                "battery_level":     78,
                "device_time":       "2025-06-15T14:30:00",
                "order_id":          42
            }
        }
    }


class VisitStartRequest(BaseModel):
    """
    Usta vizitni rasman boshlayotganini bildiradi.
    Bu so'rov order statusini on_the_way ga o'tkazadi
    va birinchi koordinatani saqlaydi.
    """
    order_id: int = Field(
        ...,
        description="Vizit qilinayotgan zakaz ID si"
    )
    latitude:  float = Field(..., ge=-90.0,  le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    notes: Optional[str] = Field(
        default=None,
        max_length=300,
        description="Ixtiyoriy izoh (masalan: 'Yo'lga chiqdim, 20 daqiqada yetaman')"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "order_id":  42,
                "latitude":  41.2995,
                "longitude": 69.2401,
                "notes":     "Yo'lga chiqdim, 20 daqiqada yetaman"
            }
        }
    }


class VisitEndRequest(BaseModel):
    """
    Usta vizitni yakunlayotganini bildiradi.
    Status on_the_way dan → in_repair ga o'tadi.
    """
    order_id: int = Field(..., description="Zakaz ID si")
    latitude:  float = Field(..., ge=-90.0,  le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    notes: Optional[str] = Field(
        default=None,
        max_length=300,
        description="Ixtiyoriy izoh (masalan: 'Mijoz uyida, ta'mirni boshladim')"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "order_id":  42,
                "latitude":  41.3105,
                "longitude": 69.2780,
                "notes":     "Mijoz uyiga yetdim, ta'mirni boshladim"
            }
        }
    }


# ================================================================
#  RESPONSE SCHEMALAR — Frontendga / Adminга qaytadi
# ================================================================

class LocationPingResponse(BaseModel):
    """
    Koordinata qabul qilingandan keyin mobil ilovaga qaytariladigan javob.
    Ilova bu javobga qarab xatti-harakatini o'zgartirishi mumkin.
    """
    success:          bool  = True
    location_id:      int               # Saqlangan yozuv ID si
    next_ping_seconds: int  = 15        # Keyingi ping qachon (server maslahat beradi)
    message:          Optional[str] = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "success":            True,
                "location_id":        128,
                "next_ping_seconds":  15,
                "message":            None
            }
        }
    }


class WorkerCurrentLocationResponse(BaseModel):
    """
    Ustaning eng oxirgi joylashuvi.
    Admin xaritasida har usta uchun bitta marker ko'rsatiladi.
    """
    worker_id:    int
    worker_name:  str
    worker_phone: Optional[str] = None

    # Joylashuv
    latitude:   float
    longitude:  float
    accuracy:   Optional[float] = None
    speed:      Optional[float] = None
    bearing:    Optional[float] = None
    recorded_at: datetime

    # Zakaz
    order_id:     Optional[int]         = None
    order_number: Optional[str]         = None
    order_status: Optional[OrderStatus] = None
    client_name:  Optional[str]         = None
    client_address: Optional[str]       = None

    # Qurilma
    battery_level:     Optional[int] = None
    location_provider: Optional[str] = None

    # Qancha vaqt avval yangilangani
    seconds_since_update: int = 0
    is_stale: bool = False   # True = 5 daqiqadan ko'p vaqt o'tgan

    model_config = {"from_attributes": True}


class LocationPointResponse(BaseModel):
    """
    Trek (marshrut) uchun bitta koordinata nuqtasi.
    """
    id:                int
    latitude:          float
    longitude:         float
    accuracy:          Optional[float] = None
    speed:             Optional[float] = None
    bearing:           Optional[float] = None
    battery_level:     Optional[int]   = None
    location_provider: Optional[str]   = None
    device_time:       Optional[datetime] = None
    recorded_at:       datetime

    model_config = {"from_attributes": True}


class WorkerTrekResponse(BaseModel):
    """
    Ustaning bitta vizit/seans uchun to'liq marshrutı (trek).
    Xaritada chiziq sifatida ko'rsatiladi.
    """
    worker_id:    int
    worker_name:  str
    order_id:     Optional[int]    = None
    order_number: Optional[str]    = None

    # Trek nuqtalari (vaqt bo'yicha o'sish tartibida)
    points:       list[LocationPointResponse] = []
    total_points: int = 0

    # Trek statistikasi
    trek_start:   Optional[datetime] = None
    trek_end:     Optional[datetime] = None
    duration_minutes: Optional[float] = None
    # Taxminiy bosib o'tilgan masofa (km) — oddiy hisoblash
    distance_km:  Optional[float] = None


class ActiveWorkerMapResponse(BaseModel):
    """
    Admin xaritasi uchun barcha faol (on_the_way) ustalar.
    Xarita sahifasi yuklanganda bir marta so'raladi,
    keyin WebSocket yoki polling orqali yangilanadi.
    """
    total_active:   int
    workers:        list[WorkerCurrentLocationResponse] = []
    generated_at:   datetime


class VisitStartResponse(BaseModel):
    """Vizit boshlanganda qaytariladigan javob"""
    success:      bool
    message:      str
    order_id:     int
    order_number: str
    order_status: OrderStatus
    location_id:  int    # Saqlangan birinchi koordinata ID si


class VisitEndResponse(BaseModel):
    """Vizit yakunlanganda qaytariladigan javob"""
    success:      bool
    message:      str
    order_id:     int
    order_number: str
    order_status: OrderStatus
    total_points: int   # Vizit davomida yig'ilgan koordinatalar soni
