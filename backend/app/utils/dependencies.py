# ================================================
# utils/dependencies.py — FastAPI Dependency'lari
#
# Bu fayl barcha himoyalangan endpoint'lar uchun
# "darvoza qo'riqchisi" vazifasini bajaradi.
#
# Ishlatilishi (istalgan route'da):
#   current_user = Depends(get_current_user)
#   admin_user   = Depends(require_admin)
#   operator     = Depends(require_operator_or_admin)
# ================================================

from typing import Annotated, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.database import get_db
from app.database.models import User, UserRole
from app.utils.auth import decode_access_token
from app.utils.logger import logger


# ================================================================
#  HTTP BEARER — "Authorization: Bearer <token>" headerini o'qiydi
# ================================================================

# auto_error=False: token yo'q bo'lsa biz o'zimiz xato qaytaramiz
bearer_scheme = HTTPBearer(auto_error=False)


# ================================================================
#  ASOSIY DEPENDENCY: get_current_user
#  Barcha himoyalangan route'larning asosi
# ================================================================

async def get_current_user(
    credentials: Annotated[
        Optional[HTTPAuthorizationCredentials],
        Depends(bearer_scheme)
    ],
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    JWT tokenni tekshirib, joriy foydalanuvchini qaytaradi.

    Tekshirish tartibi:
      1. Authorization header mavjudligini tekshiradi
      2. Token imzosini va muddatini tekshiradi
      3. Token ichidagi user ID bilan DB dan foydalanuvchini topadi
      4. Foydalanuvchi aktiv ekanligini tekshiradi

    Xatoliklar:
      401 — token yo'q yoki noto'g'ri
      401 — token muddati o'tgan
      401 — foydalanuvchi topilmadi
      403 — hisob bloklangan
    """

    # Standart 401 xato — token muammosi uchun qayta-qayta yozmaslik uchun
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Tizimga kirish talab qilinadi. Token noto'g'ri yoki muddati o'tgan.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    # 1. Token mavjudligini tekshirish
    if not credentials or not credentials.credentials:
        logger.debug("So'rov token'siz keldi")
        raise credentials_error

    token = credentials.credentials

    # 2. Token dekod qilish (imzo + muddat tekshiruvi)
    payload = decode_access_token(token)
    if payload is None:
        logger.warning("Noto'g'ri yoki muddati o'tgan token keldi")
        raise credentials_error

    # 3. Token ichidan user ID ni olish
    user_id: int | None = payload.get("id")
    if user_id is None:
        logger.warning("Token payload'ida 'id' maydoni topilmadi")
        raise credentials_error

    # 4. DB dan foydalanuvchini topish
    from app.services.auth_service import get_user_by_id
    user = await get_user_by_id(db, user_id)

    if user is None:
        logger.warning(f"Token'dagi user_id={user_id} DB da topilmadi")
        raise credentials_error

    # 5. Hisob bloklangan emasligini tekshirish
    if not user.is_active:
        logger.warning(f"Bloklangan hisob kirish urinishi: user_id={user_id}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sizning hisobingiz bloklangan. Admin bilan bog'laning.",
        )

    return user


# ================================================================
#  ROL ASOSIDA HIMOYA DEPENDENCY'LARI
# ================================================================

async def require_admin(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """
    Faqat ADMIN uchun ruxsat.

    Ishlatilishi:
        @router.delete("/users/{id}")
        async def delete_user(admin: User = Depends(require_admin)):
            ...
    """
    if current_user.role != UserRole.ADMIN:
        logger.warning(
            f"⛔ Admin huquqi talab qilinadi: "
            f"user_id={current_user.id}, role={current_user.role}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu amalni bajarish uchun Admin huquqi talab qilinadi.",
        )
    return current_user


async def require_operator_or_admin(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """
    ADMIN yoki OPERATOR uchun ruxsat.
    Ustalar (master) bu endpoint'larga kira olmaydi.

    Ishlatilishi:
        @router.post("/orders")
        async def create_order(user: User = Depends(require_operator_or_admin)):
            ...
    """
    allowed_roles = {UserRole.ADMIN, UserRole.OPERATOR}
    if current_user.role not in allowed_roles:
        logger.warning(
            f"⛔ Operator/Admin huquqi talab qilinadi: "
            f"user_id={current_user.id}, role={current_user.role}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu amalni bajarish uchun Operator yoki Admin huquqi talab qilinadi.",
        )
    return current_user


async def require_master_or_above(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """
    MASTER, OPERATOR yoki ADMIN uchun ruxsat.
    Barcha autentifikatsiya qilingan foydalanuvchilarga ruxsat beradi.
    (get_current_user bilan deyarli bir xil, lekin semantik aniq)

    Ishlatilishi:
        @router.patch("/orders/{id}/status")
        async def update_status(user: User = Depends(require_master_or_above)):
            ...
    """
    # Barcha rollar ruxsatli — faqat aktiv ekanligini yuqorida tekshirdik
    return current_user


# ================================================================
#  QULAYLIK UCHUN: TYPE ALIAS'LAR
#  Har safar Depends() yozmaslik uchun
# ================================================================

# Tip annotatsiyasi sifatida ishlatiladi:
#   async def my_route(user: CurrentUser):
CurrentUser            = Annotated[User, Depends(get_current_user)]
AdminUser              = Annotated[User, Depends(require_admin)]
OperatorOrAdminUser    = Annotated[User, Depends(require_operator_or_admin)]
AnyAuthenticatedUser   = Annotated[User, Depends(require_master_or_above)]

# DB session type alias
DBSession = Annotated[AsyncSession, Depends(get_db)]
