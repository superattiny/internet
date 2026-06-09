# ================================================
# services/auth_service.py — Auth biznes logikasi
# Login tekshirish, token yaratish, parol o'zgartirish
# Bu fayl DB bilan to'g'ridan-to'g'ri ishlaydi
# ================================================

from datetime import timedelta
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.database.models import User, UserRole
from app.schemas.auth import (
    LoginRequest,
    ChangePasswordRequest,
    TokenResponse,
    UserInfoResponse,
)
from app.utils.auth import (
    verify_password,
    hash_password,
    create_access_token,
)
from app.utils.logger import logger
from app.config import settings


# ================================================================
#  FOYDALANUVCHI QIDIRISH
# ================================================================

async def get_user_by_username(
    db: AsyncSession,
    username: str
) -> Optional[User]:
    """
    Username bo'yicha foydalanuvchini DB dan topadi.
    Topilmasa None qaytaradi.
    """
    result = await db.execute(
        select(User).where(
            User.username == username.strip().lower()
        )
    )
    return result.scalar_one_or_none()


async def get_user_by_id(
    db: AsyncSession,
    user_id: int
) -> Optional[User]:
    """
    ID bo'yicha foydalanuvchini DB dan topadi.
    Token tekshirishda ishlatiladi.
    """
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    return result.scalar_one_or_none()


# ================================================================
#  LOGIN — ASOSIY FUNKSIYA
# ================================================================

async def authenticate_user(
    db: AsyncSession,
    login_data: LoginRequest
) -> Optional[User]:
    """
    Foydalanuvchini autentifikatsiya qiladi.

    Tekshirish tartibi:
      1. Username bo'yicha DB dan qidiradi
      2. Foydalanuvchi mavjudligini tekshiradi
      3. is_active=True ekanligini tekshiradi
      4. Parol to'g'riligini tekshiradi (bcrypt)

    Muvaffaqiyatli bo'lsa: User ob'ekti
    Muvaffaqiyatsiz bo'lsa: None
    """
    username = login_data.username.strip().lower()

    # 1. Foydalanuvchini qidirish
    user = await get_user_by_username(db, username)

    if not user:
        logger.warning(f"Login urinishi: '{username}' — topilmadi")
        return None

    # 2. Faollik tekshirish
    if not user.is_active:
        logger.warning(f"Login urinishi: '{username}' — hisobi bloklangan")
        return None

    # 3. Parol tekshirish
    if not verify_password(login_data.password, user.hashed_password):
        logger.warning(f"Login urinishi: '{username}' — parol noto'g'ri")
        return None

    logger.info(f"✅ Muvaffaqiyatli login: '{username}' (rol: {user.role})")
    return user


# ================================================================
#  TOKEN YARATISH
# ================================================================

def build_token_response(user: User) -> TokenResponse:
    """
    Autentifikatsiya qilingan User uchun TokenResponse yaratadi.

    Token payload tarkibi:
      - sub   : username (standart JWT claim)
      - id    : foydalanuvchi ID si
      - role  : roli (admin / operator / master)
    """
    expires_seconds = settings.access_token_expire_minutes * 60

    token = create_access_token(
        data={
            "sub":  user.username,
            "id":   user.id,
            "role": user.role.value,
        },
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=expires_seconds,
        user=UserInfoResponse.model_validate(user),
    )


# ================================================================
#  PAROL O'ZGARTIRISH
# ================================================================

async def change_user_password(
    db: AsyncSession,
    user: User,
    request: ChangePasswordRequest,
) -> tuple[bool, str]:
    """
    Foydalanuvchi parolini o'zgartiradi.

    Returns:
        (True, "xabar")  — muvaffaqiyatli
        (False, "xabar") — xatolik sababi bilan

    Tekshirishlar:
      1. Hozirgi parol to'g'riligini tasdiqlash
      2. Yangi parol va tasdiq mos kelishini tekshirish
      3. Yangi parol hozirgiday emaslini tekshirish
    """
    # 1. Hozirgi parolni tekshirish
    if not verify_password(request.current_password, user.hashed_password):
        return False, "Hozirgi parol noto'g'ri"

    # 2. Yangi parol va tasdiqlash mos kelishini tekshirish
    if not request.passwords_match():
        return False, "Yangi parol va tasdiqlash mos kelmadi"

    # 3. Yangi parol hozirgiday emasligini tekshirish
    if verify_password(request.new_password, user.hashed_password):
        return False, "Yangi parol hozirgi paroldan farq qilishi kerak"

    # 4. Yangi parolni hashlab saqlash
    await db.execute(
        update(User)
        .where(User.id == user.id)
        .values(hashed_password=hash_password(request.new_password))
    )
    await db.commit()

    logger.info(f"🔑 Parol o'zgartirildi: user_id={user.id} username={user.username}")
    return True, "Parol muvaffaqiyatli o'zgartirildi"


# ================================================================
#  ADMIN UCHUN: FOYDALANUVCHI PAROLI TIKLASH
# ================================================================

async def reset_user_password(
    db: AsyncSession,
    target_user_id: int,
    new_password: str,
    performed_by: User,
) -> tuple[bool, str]:
    """
    Admin foydalanuvchi parolini majburiy tiklaydi.
    Faqat ADMIN roli uchun ruxsat etilgan.

    Args:
        db             : DB sessiyasi
        target_user_id : Paroli tiklanadigan foydalanuvchi ID si
        new_password   : Yangi parol (ochiq matn)
        performed_by   : Kim bajardi (Admin)

    Returns:
        (True/False, xabar)
    """
    if performed_by.role != UserRole.ADMIN:
        logger.warning(
            f"⛔ Ruxsatsiz parol tiklash urinishi: "
            f"user_id={performed_by.id} role={performed_by.role}"
        )
        return False, "Faqat Admin parolni tiklashi mumkin"

    if len(new_password) < 6:
        return False, "Yangi parol kamida 6 ta belgidan iborat bo'lishi kerak"

    target_user = await get_user_by_id(db, target_user_id)
    if not target_user:
        return False, "Foydalanuvchi topilmadi"

    await db.execute(
        update(User)
        .where(User.id == target_user_id)
        .values(hashed_password=hash_password(new_password))
    )
    await db.commit()

    logger.info(
        f"🔑 Admin parol tikladi: "
        f"target=user_id:{target_user_id}, "
        f"admin=user_id:{performed_by.id}"
    )
    return True, f"'{target_user.full_name}' paroli muvaffaqiyatli tiklandi"
