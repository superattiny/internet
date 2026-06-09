# ================================================
# schemas/order.py — Orders uchun Pydantic modellari
# So'rov (Request) va Javob (Response) formatlari
# ================================================

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator, model_validator

from app.database.models import OrderStatus, OrderSource, PaymentMethod


# ================================================================
#  REQUEST SCHEMALAR — Frontenddan keladi
# ================================================================

class OrderCreateRequest(BaseModel):
    """
    Yangi zakaz ochish so'rovi.
    deadline MAJBURIY — kiritilmasa 422 xato qaytariladi.
    """

    # --- Mijoz (yangi yoki mavjud) ---
    client_id: Optional[int] = Field(
        default=None,
        description="Mavjud mijoz ID si (agar yangi mijoz bo'lsa bo'sh qoldiring)"
    )
    # Yangi mijoz ma'lumotlari (client_id bo'lmasa bular shart)
    client_name:  Optional[str] = Field(default=None, max_length=100, description="Yangi mijoz ismi")
    client_phone: Optional[str] = Field(default=None, max_length=20,  description="Yangi mijoz telefoni")

    # --- Televizor ma'lumotlari ---
    tv_brand:         Optional[str] = Field(default=None, max_length=50,  examples=["Samsung"])
    tv_model:         Optional[str] = Field(default=None, max_length=100, examples=["UA55TU8000"])
    tv_diagonal:      Optional[str] = Field(default=None, max_length=20,  examples=["55\""])
    tv_serial_number: Optional[str] = Field(default=None, max_length=100)

    # --- Nosozlik tavsifi (MAJBURIY) ---
    problem_description: str = Field(
        ...,
        min_length=5,
        max_length=2000,
        description="Nosozlik tavsifi (majburiy, kamida 5 belgi)",
        examples=["Ekran yonmayapti, ovoz bor lekin tasvir yo'q"]
    )

    # --- Holat va manba ---
    source: OrderSource = Field(
        default=OrderSource.WALK_IN,
        description="Zakaz qayerdan keldi"
    )

    # --- Ishchilar ---
    master_id:   Optional[int] = Field(default=None, description="Tayinlangan usta ID si")
    operator_id: Optional[int] = Field(default=None, description="Operator ID si")

    # --- Narx ---
    estimated_price: float = Field(default=0.0, ge=0, description="Dastlabki taxminiy narx (so'm)")

    # *** DEADLINE — MAJBURIY ***
    deadline: datetime = Field(
        ...,
        description="Zakaz bajarilishi kerak bo'lgan sana va soat (MAJBURIY)",
        examples=["2025-06-20T18:00:00"]
    )

    @field_validator("deadline")
    @classmethod
    def deadline_must_be_future(cls, v: datetime) -> datetime:
        """Deadline o'tgan vaqtda bo'lmasligi kerak"""
        # Timezone-aware qilish
        from datetime import timezone
        now = datetime.now(timezone.utc)
        # Agar deadline timezone'siz kelsa, UTC deb qabul qilamiz
        if v.tzinfo is None:
            from datetime import timezone
            v = v.replace(tzinfo=timezone.utc)
        if v <= now:
            raise ValueError("Deadline o'tgan vaqt bo'lishi mumkin emas — kelajakdagi sana kiriting")
        return v

    @model_validator(mode="after")
    def client_info_required(self) -> "OrderCreateRequest":
        """
        client_id yoki (client_name + client_phone) dan biri bo'lishi shart.
        Ikkisi ham bo'lmasa xato.
        """
        if not self.client_id and not self.client_name:
            raise ValueError(
                "Mijoz ma'lumoti talab qilinadi: 'client_id' yoki 'client_name' kiritilishi shart"
            )
        return self

    model_config = {
        "json_schema_extra": {
            "example": {
                "client_name": "Alisher Karimov",
                "client_phone": "+998901234567",
                "tv_brand": "Samsung",
                "tv_model": "UA55TU8000",
                "tv_diagonal": "55\"",
                "problem_description": "Ekran yonmayapti, faqat ovoz bor",
                "source": "walk_in",
                "estimated_price": 150000,
                "deadline": "2025-06-20T18:00:00"
            }
        }
    }


class OrderUpdateRequest(BaseModel):
    """
    Zakaz ma'lumotlarini yangilash (PATCH — faqat yuborilgan maydonlar o'zgaradi).
    """
    tv_brand:            Optional[str]   = Field(default=None, max_length=50)
    tv_model:            Optional[str]   = Field(default=None, max_length=100)
    tv_diagonal:         Optional[str]   = Field(default=None, max_length=20)
    tv_serial_number:    Optional[str]   = Field(default=None, max_length=100)
    problem_description: Optional[str]   = Field(default=None, min_length=5, max_length=2000)
    master_diagnosis:    Optional[str]   = Field(default=None, max_length=2000)
    work_done:           Optional[str]   = Field(default=None, max_length=2000)
    estimated_price:     Optional[float] = Field(default=None, ge=0)
    final_price:         Optional[float] = Field(default=None, ge=0)
    parts_cost:          Optional[float] = Field(default=None, ge=0)
    master_id:           Optional[int]   = Field(default=None)
    deadline:            Optional[datetime] = Field(default=None)

    @field_validator("deadline")
    @classmethod
    def deadline_must_be_future(cls, v: Optional[datetime]) -> Optional[datetime]:
        if v is None:
            return v
        from datetime import timezone
        now = datetime.now(timezone.utc)
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        if v <= now:
            raise ValueError("Deadline o'tgan vaqt bo'lishi mumkin emas")
        return v


class OrderStatusUpdateRequest(BaseModel):
    """
    Zakaz statusini o'zgartirish so'rovi.
    Har bir o'zgarish order_status_history ga yoziladi.
    """
    new_status: OrderStatus = Field(
        ...,
        description="Yangi holat"
    )
    comment: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Status o'zgarishi sababi yoki izohi (ixtiyoriy)"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "new_status": "in_repair",
                "comment": "Zapchast keldi, ta'mirga kirdi"
            }
        }
    }


class OrderPaymentRequest(BaseModel):
    """
    Zakaz to'lovini qabul qilish so'rovi.
    """
    final_price:    float         = Field(..., gt=0, description="Yakuniy to'lov summasi (so'm)")
    payment_method: PaymentMethod = Field(..., description="To'lov usuli")
    comment:        Optional[str] = Field(default=None, max_length=500)

    model_config = {
        "json_schema_extra": {
            "example": {
                "final_price": 250000,
                "payment_method": "cash",
                "comment": "Mijoz to'liq to'ladi"
            }
        }
    }


# ================================================================
#  RESPONSE SCHEMALAR — Frontendga qaytadi
# ================================================================

class ClientShortResponse(BaseModel):
    """Zakaz ichida ko'rsatiladigan mijoz qisqacha ma'lumoti"""
    id:        int
    full_name: str
    phone:     Optional[str] = None

    model_config = {"from_attributes": True}


class WorkerShortResponse(BaseModel):
    """Zakaz ichida ko'rsatiladigan ishchi qisqacha ma'lumoti"""
    id:        int
    full_name: str
    role:      str

    model_config = {"from_attributes": True}


class StatusHistoryResponse(BaseModel):
    """Bitta status o'zgarishi"""
    id:          int
    old_status:  Optional[OrderStatus] = None
    new_status:  OrderStatus
    comment:     Optional[str] = None
    changed_by:  Optional[WorkerShortResponse] = None
    created_at:  datetime

    model_config = {"from_attributes": True}


class OrderResponse(BaseModel):
    """
    Zakaz to'liq ma'lumoti (ro'yxat va detail uchun).
    """
    id:           int
    order_number: str

    # Shaxslar
    client:   ClientShortResponse
    operator: Optional[WorkerShortResponse] = None
    master:   Optional[WorkerShortResponse] = None

    # Televizor
    tv_brand:         Optional[str] = None
    tv_model:         Optional[str] = None
    tv_diagonal:      Optional[str] = None
    tv_serial_number: Optional[str] = None

    # Nosozlik
    problem_description: str
    ai_diagnosis:        Optional[str] = None
    master_diagnosis:    Optional[str] = None
    work_done:           Optional[str] = None

    # Holat
    status: OrderStatus
    source: OrderSource

    # Moliya
    estimated_price:   float
    final_price:       float
    parts_cost:        float
    is_paid:           bool
    payment_method:    Optional[PaymentMethod] = None
    master_commission: float

    # Vaqt
    deadline:      datetime
    created_at:    datetime
    updated_at:    datetime
    accepted_at:   Optional[datetime] = None
    completed_at:  Optional[datetime] = None
    delivered_at:  Optional[datetime] = None

    # Arxiv
    is_archived:   bool
    cancel_reason: Optional[str] = None

    # Deadline ogohlantirish (server tomonidan hisoblanadi)
    is_overdue:       bool = False   # Muddat o'tib ketganmi
    hours_until_deadline: Optional[float] = None  # Qancha vaqt qoldi

    # Status tarixi
    status_history: list[StatusHistoryResponse] = []

    model_config = {"from_attributes": True}


class OrderListResponse(BaseModel):
    """
    Zakazlar ro'yxati (pagination bilan).
    """
    items:       list[OrderResponse]
    total:       int
    page:        int
    page_size:   int
    total_pages: int
    # Ogohlantirish: muddati o'tgan zakazlar soni
    overdue_count: int = 0


class OrderDeadlineAlertResponse(BaseModel):
    """
    Muddati yaqinlashgan yoki o'tib ketgan zakazlar ogohlantirishlari.
    """
    order_id:     int
    order_number: str
    client_name:  str
    tv_info:      str
    status:       OrderStatus
    deadline:     datetime
    is_overdue:   bool
    hours_remaining: float   # Manfiy bo'lsa — muddat o'tib ketgan
    master_name:  Optional[str] = None

    model_config = {"from_attributes": True}


class OrderStatsResponse(BaseModel):
    """
    Dashboard uchun zakaz statistikasi.
    """
    total_orders:     int
    new_orders:       int
    in_progress:      int   # accepted + diagnosing + waiting + in_repair
    completed_today:  int
    delivered_today:  int
    cancelled_today:  int
    overdue_count:    int
    total_revenue_today: float
