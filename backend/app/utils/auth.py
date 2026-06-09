# ================================================
# utils/auth.py — Autentifikatsiya yordamchilari
# Parol hash va JWT token boshqaruvi
# ================================================

from datetime import datetime, timedelta, timezone
from typing import Optional

import bcrypt
from jose import JWTError, jwt

from app.config import settings


# ================================================================
#  PAROL FUNKSIYALARI
#  passlib o'rniga bcrypt to'g'ridan-to'g'ri ishlatiladi
#  (passlib 1.7.4 + bcrypt 4.x+ versiyalari mos kelmaydi)
# ================================================================

def hash_password(plain_password: str) -> str:
    """
    Oddiy parolni bcrypt bilan hashlaydi.
    Faqat bir tomonlama — hashdan parolni qaytarib olish mumkin emas.
    """
    return bcrypt.hashpw(
        plain_password.encode("utf-8"),
        bcrypt.gensalt()
    ).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Kirilgan parol hash bilan mos kelishini tekshiradi.
    Login vaqtida ishlatiladi.
    """
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8")
    )


# ================================================================
#  JWT TOKEN FUNKSIYALARI
# ================================================================

def create_access_token(
    data: dict,
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    JWT access token yaratadi.

    Args:
        data: Token ichiga yoziladigan ma'lumot (masalan: {"sub": "admin"})
        expires_delta: Token amal qilish muddati (None bo'lsa default ishlatiladi)

    Returns:
        Kodlangan JWT string
    """
    to_encode = data.copy()

    # Token muddati
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.access_token_expire_minutes
        )

    to_encode.update({"exp": expire})

    encoded_jwt = jwt.encode(
        to_encode,
        settings.secret_key,
        algorithm=settings.jwt_algorithm
    )
    return encoded_jwt


def decode_access_token(token: str) -> Optional[dict]:
    """
    JWT tokenni dekod qiladi va ichidagi ma'lumotni qaytaradi.

    Args:
        token: JWT string

    Returns:
        Token payload (dict) yoki None (token noto'g'ri bo'lsa)
    """
    try:
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=[settings.jwt_algorithm]
        )
        return payload
    except JWTError:
        return None


def get_username_from_token(token: str) -> Optional[str]:
    """
    Tokendan username (sub) ni chiqarib oladi.
    FastAPI dependency'larida ishlatiladi.
    """
    payload = decode_access_token(token)
    if payload is None:
        return None
    return payload.get("sub")
