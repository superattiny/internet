# ================================================
# schemas/auth.py — Auth uchun Pydantic modellari
# So'rov (Request) va Javob (Response) formatlari
# ================================================

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

from app.database.models import UserRole


# ================================================================
#  REQUEST SCHEMALAR — Frontenddan keladi
# ================================================================

class LoginRequest(BaseModel):
    """
    Login so'rovi.
    Frontend /api/v1/auth/login ga shu formatda POST qiladi.
    """
    username: str = Field(
        ...,
        min_length=3,
        max_length=50,
        examples=["admin"],
        description="Foydalanuvchi nomi"
    )
    password: str = Field(
        ...,
        min_length=4,
        max_length=100,
        examples=["admin123"],
        description="Parol (ochiq matn — server hashlab saqlaydi)"
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "username": "admin",
                "password": "admin123"
            }
        }
    }


class ChangePasswordRequest(BaseModel):
    """
    Parolni o'zgartirish so'rovi.
    Foydalanuvchi o'z parolini o'zgartirmoqchi bo'lganda.
    """
    current_password: str = Field(
        ...,
        min_length=4,
        description="Hozirgi parol"
    )
    new_password: str = Field(
        ...,
        min_length=6,
        max_length=100,
        description="Yangi parol (kamida 6 ta belgi)"
    )
    confirm_password: str = Field(
        ...,
        min_length=6,
        description="Yangi parolni takrorlash"
    )

    def passwords_match(self) -> bool:
        """Yangi parol va tasdiqlash mos kelishini tekshiradi"""
        return self.new_password == self.confirm_password


# ================================================================
#  RESPONSE SCHEMALAR — Frontendga qaytadi
# ================================================================

class UserInfoResponse(BaseModel):
    """
    Tizimga kirgan foydalanuvchi haqida ma'lumot.
    Token ichida va /me endpoint'da qaytariladi.
    """
    id: int
    username: str
    full_name: str
    role: UserRole
    phone: Optional[str] = None
    is_active: bool
    balance: float
    created_at: datetime

    model_config = {"from_attributes": True}  # SQLAlchemy modeldan yaratish uchun


class TokenResponse(BaseModel):
    """
    Muvaffaqiyatli login'dan keyin qaytariladigan javob.
    Frontend shu tokenni localStorage yoki cookie'ga saqlaydi.
    """
    access_token: str = Field(description="JWT Bearer token")
    token_type: str = Field(default="bearer", description="Token turi (har doim 'bearer')")
    expires_in: int = Field(description="Token muddati (soniyalarda)")
    user: UserInfoResponse = Field(description="Kirgan foydalanuvchi ma'lumotlari")

    model_config = {
        "json_schema_extra": {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 28800,
                "user": {
                    "id": 1,
                    "username": "admin",
                    "full_name": "Administrator",
                    "role": "admin",
                    "is_active": True,
                    "balance": 0.0
                }
            }
        }
    }


class LogoutResponse(BaseModel):
    """Logout javob formati"""
    message: str = "Tizimdan muvaffaqiyatli chiqdingiz"
    success: bool = True


class MessageResponse(BaseModel):
    """Umumiy xabar javob formati (operatsiya natijasi uchun)"""
    message: str
    success: bool = True
