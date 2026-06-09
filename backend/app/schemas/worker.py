# ================================================
# schemas/worker.py — Workers uchun Pydantic modellari
# So'rov (Request) va Javob (Response) formatlari
# ================================================

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator

from app.database.models import UserRole, PaymentMethod


# ================================================================
#  REQUEST SCHEMALAR — Frontenddan keladi
# ================================================================

class WorkerCreateRequest(BaseModel):
    """
    Yangi ishchi (Usta / Operator) yaratish so'rovi.
    Faqat Admin bajarishi mumkin.
    """
    full_name: str = Field(
        ..., min_length=2, max_length=100,
        description="To'liq ismi-familiyasi",
        examples=["Sardor Toshmatov"]
    )
    username: str = Field(
        ..., min_length=3, max_length=50,
        description="Tizimga kirish nomi (login)",
        examples=["sardor_usta"]
    )
    password: str = Field(
        ..., min_length=6, max_length=100,
        description="Boshlang'ich parol (kamida 6 belgi)"
    )
    phone: Optional[str] = Field(
        default=None, max_length=20,
        description="Telefon raqami",
        examples=["+998901234567"]
    )
    role: UserRole = Field(
        ...,
        description="Rol: 'master' (Usta) yoki 'operator' (Operator)"
    )
    # --- Moliyaviy sozlamalar ---
    commission_percent: float = Field(
        default=0.0, ge=0.0, le=100.0,
        description="Har bir zakazdan olinadigan komisyon foizi (0-100%). "
                    "Masalan: 30.0 = har zakaz summasidan 30% ustaga tushadi"
    )
    salary_rate: float = Field(
        default=0.0, ge=0.0,
        description="Oylik ish haqi (so'mda). Komisyon bilan birga ishlatilishi mumkin."
    )

    @field_validator("role")
    @classmethod
    def role_not_admin(cls, v: UserRole) -> UserRole:
        """Admin rolini bu endpoint orqali yaratib bo'lmaydi"""
        if v == UserRole.ADMIN:
            raise ValueError(
                "Admin foydalanuvchini bu endpoint orqali yaratib bo'lmaydi."
            )
        return v

    @field_validator("username")
    @classmethod
    def username_lowercase(cls, v: str) -> str:
        """Username kichik harflarda va bo'sh joylarsiz bo'lishi shart"""
        v = v.strip().lower()
        if " " in v:
            raise ValueError("Username bo'sh joy tutmasligi kerak")
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "full_name": "Sardor Toshmatov",
                "username": "sardor_usta",
                "password": "parol123",
                "phone": "+998901234567",
                "role": "master",
                "commission_percent": 30.0,
                "salary_rate": 0.0
            }
        }
    }


class WorkerUpdateRequest(BaseModel):
    """
    Ishchi ma'lumotlarini yangilash (PATCH — faqat yuborilganlar o'zgaradi).
    """
    full_name:          Optional[str]   = Field(default=None, min_length=2, max_length=100)
    phone:              Optional[str]   = Field(default=None, max_length=20)
    commission_percent: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    salary_rate:        Optional[float] = Field(default=None, ge=0.0)
    is_active:          Optional[bool]  = Field(default=None, description="False = hisob bloklash")

    model_config = {
        "json_schema_extra": {
            "example": {
                "commission_percent": 35.0,
                "phone": "+998901112233"
            }
        }
    }


class SalaryPaymentRequest(BaseModel):
    """
    Ishchiga ish haqi to'lash so'rovi.
    Ishchining balansidan ayiriladi, kassaga chiqim yoziladi.
    """
    amount: float = Field(
        ..., gt=0,
        description="To'lov summasi (so'mda, noldan katta bo'lishi shart)"
    )
    payment_method: PaymentMethod = Field(
        default=PaymentMethod.CASH,
        description="To'lov usuli: cash / card / transfer"
    )
    notes: Optional[str] = Field(
        default=None, max_length=500,
        description="Izoh (masalan: 'Iyun oyi ish haqi')"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "amount": 1500000,
                "payment_method": "cash",
                "notes": "Iyun oyi ish haqi to'lovi"
            }
        }
    }


class BalanceAdjustRequest(BaseModel):
    """
    Ishchi balansini qo'lda to'g'irlash (Admin uchun).
    Masalan: bonus qo'shish yoki noto'g'ri yozuvni tuzatish.
    """
    amount: float = Field(
        ...,
        description="Miqdor (musbat = qo'shish, manfiy = ayirish)"
    )
    reason: str = Field(
        ..., min_length=3, max_length=500,
        description="Sabab (majburiy) — audit izi uchun"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "amount": 200000,
                "reason": "Iyul oyi bonusi — eng yaxshi usta"
            }
        }
    }


# ================================================================
#  RESPONSE SCHEMALAR — Frontendga qaytadi
# ================================================================

class WorkerResponse(BaseModel):
    """
    Ishchi to'liq ma'lumoti.
    """
    id:                 int
    full_name:          str
    username:           str
    phone:              Optional[str]  = None
    role:               UserRole
    is_active:          bool

    # --- Moliyaviy ma'lumotlar ---
    balance:            float   # Joriy balans (to'lanmagan komisyon yig'indisi)
    commission_percent: float   # Komisyon foizi
    salary_rate:        float   # Oylik stavka

    # --- Statistika (servis tomonidan hisoblanadi) ---
    total_orders_done:  int     = 0
    total_earned:       float   = 0.0
    total_paid_out:     float   = 0.0

    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class WorkerListResponse(BaseModel):
    """Ishchilar ro'yxati"""
    items:      list[WorkerResponse]
    total:      int
    masters:    int
    operators:  int


class CommissionDetailResponse(BaseModel):
    """Bitta komisyon yozuvi — zakaz bilan bog'liq"""
    order_id:           int
    order_number:       str
    order_date:         datetime
    final_price:        float
    commission_percent: float
    commission_amount:  float
    client_name:        str
    tv_info:            str

    model_config = {"from_attributes": True}


class SalaryPaymentHistoryResponse(BaseModel):
    """Bitta ish haqi to'lovi yozuvi"""
    id:             int
    amount:         float
    payment_method: PaymentMethod
    notes:          Optional[str] = None
    paid_by:        Optional[str] = None
    created_at:     datetime

    model_config = {"from_attributes": True}


class WorkerBalanceHistoryResponse(BaseModel):
    """
    Ishchi balans tarixi — barcha kirim va chiqimlar.
    """
    worker_id:       int
    worker_name:     str
    balance:         float

    commissions:     list[CommissionDetailResponse]       = []
    total_earned:    float                                = 0.0

    salary_payments: list[SalaryPaymentHistoryResponse]   = []
    total_paid_out:  float                                = 0.0


class SalaryPaymentResponse(BaseModel):
    """To'lov amalga oshirilgandan keyingi javob"""
    success:        bool
    message:        str
    worker_name:    str
    amount_paid:    float
    new_balance:    float
    payment_method: PaymentMethod


class CommissionEventResponse(BaseModel):
    """
    Zakaz DELIVERED bo'lganda ustaga hisoblangan
    komisyon haqida to'liq hisobot.
    """
    worker_id:          int
    worker_name:        str
    order_number:       str
    final_price:        float
    commission_percent: float
    commission_amount:  float
    new_balance:        float
    kassa_deducted:     float
