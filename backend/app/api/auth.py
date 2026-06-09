# ================================================
# api/auth.py — Auth API Router
#
# Endpoint'lar ro'yxati:
#   POST   /api/v1/auth/login           → Tizimga kirish
#   POST   /api/v1/auth/logout          → Tizimdan chiqish
#   GET    /api/v1/auth/me              → Joriy foydalanuvchi ma'lumoti
#   POST   /api/v1/auth/refresh         → Tokenni yangilash
#   POST   /api/v1/auth/change-password → Parolni o'zgartirish
#   POST   /api/v1/auth/reset-password/{user_id} → Admin: parol tiklash
# ================================================

from fastapi import APIRouter, HTTPException, status, Request
from fastapi.responses import JSONResponse

from app.schemas.auth import (
    LoginRequest,
    ChangePasswordRequest,
    TokenResponse,
    UserInfoResponse,
    LogoutResponse,
    MessageResponse,
)
from app.services.auth_service import (
    authenticate_user,
    build_token_response,
    change_user_password,
    reset_user_password,
    get_user_by_id,
)
from app.utils.dependencies import (
    CurrentUser,
    AdminUser,
    DBSession,
)
from app.utils.logger import logger


# ================================================================
#  ROUTER YARATISH
# ================================================================

router = APIRouter(
    prefix="/auth",
    tags=["🔐 Auth — Kirish va Xavfsizlik"],
    responses={
        401: {"description": "Token noto'g'ri yoki muddati o'tgan"},
        403: {"description": "Bu amal uchun ruxsat yo'q"},
    },
)


# ================================================================
#  1. LOGIN — Tizimga kirish
# ================================================================

@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Tizimga kirish",
    description="""
    Username va parol bilan tizimga kirish.

    Muvaffaqiyatli kirishda JWT Bearer token qaytariladi.
    Token barcha himoyalangan so'rovlarda ishlatiladi:
    ```
    Authorization: Bearer <token>
    ```
    """,
)
async def login(
    login_data: LoginRequest,
    request: Request,
    db: DBSession,
) -> TokenResponse:
    """
    Tizimga kirish endpoint'i.

    - **username**: Foydalanuvchi nomi (katta-kichik harfga sezgir emas)
    - **password**: Parol (kamida 4 ta belgi)
    """
    # IP manzilni log uchun olish
    client_ip = request.client.host if request.client else "unknown"

    logger.info(f"🔑 Login urinishi: username='{login_data.username}' ip={client_ip}")

    # Autentifikatsiya
    user = await authenticate_user(db, login_data)

    if user is None:
        # Xavfsizlik: kimligini oshkor qilmaslik uchun umumiy xabar
        logger.warning(
            f"❌ Muvaffaqiyatsiz login: username='{login_data.username}' ip={client_ip}"
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username yoki parol noto'g'ri.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Token yaratish va javob qaytarish
    token_response = build_token_response(user)

    logger.info(
        f"✅ Login muvaffaqiyatli: "
        f"user_id={user.id}, username='{user.username}', "
        f"role={user.role}, ip={client_ip}"
    )

    return token_response


# ================================================================
#  2. LOGOUT — Tizimdan chiqish
# ================================================================

@router.post(
    "/logout",
    response_model=LogoutResponse,
    status_code=status.HTTP_200_OK,
    summary="Tizimdan chiqish",
    description="""
    Tizimdan xavfsiz chiqish.

    **Eslatma:** JWT stateless bo'lgani uchun server tomonida
    token bekor qilinmaydi. Frontend o'zi tokenni o'chirishi kerak
    (localStorage yoki cookie'dan).

    Kelajakda token blacklist (Redis) qo'shilishi mumkin.
    """,
)
async def logout(
    current_user: CurrentUser,
) -> LogoutResponse:
    """
    Tizimdan chiqish. Token'ni frontend o'chiradi.
    """
    logger.info(
        f"👋 Logout: user_id={current_user.id}, username='{current_user.username}'"
    )

    return LogoutResponse(
        message=f"Xayr, {current_user.full_name}! Tizimdan muvaffaqiyatli chiqdingiz.",
        success=True,
    )


# ================================================================
#  3. ME — Joriy foydalanuvchi ma'lumoti
# ================================================================

@router.get(
    "/me",
    response_model=UserInfoResponse,
    status_code=status.HTTP_200_OK,
    summary="Mening profilim",
    description="""
    Hozirgi token egasining profil ma'lumotlarini qaytaradi.

    Frontend sahifa yuklanganda bu endpoint'ni chaqirib,
    foydalanuvchi ma'lumotlarini yangilashi kerak.
    """,
)
async def get_me(
    current_user: CurrentUser,
) -> UserInfoResponse:
    """
    Joriy autentifikatsiya qilingan foydalanuvchi ma'lumotlari.
    """
    logger.debug(f"👤 /me so'rovi: user_id={current_user.id}")
    return UserInfoResponse.model_validate(current_user)


# ================================================================
#  4. REFRESH — Tokenni yangilash
# ================================================================

@router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Tokenni yangilash",
    description="""
    Hali muddati o'tmagan tokenni yangilaydi.

    Frontend token muddati tugashidan oldin bu endpoint'ni
    chaqirib, foydalanuvchini qayta login qildirmasdan
    yangi token olishi mumkin.
    """,
)
async def refresh_token(
    current_user: CurrentUser,
    db: DBSession,
) -> TokenResponse:
    """
    Yangi JWT token beradi (eski token hali amal qilsa).
    """
    # DB dan eng yangi ma'lumotni olamiz (balans, rol o'zgargan bo'lishi mumkin)
    fresh_user = await get_user_by_id(db, current_user.id)

    if fresh_user is None or not fresh_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Foydalanuvchi topilmadi yoki bloklangan.",
        )

    new_token_response = build_token_response(fresh_user)

    logger.info(f"🔄 Token yangilandi: user_id={current_user.id}")
    return new_token_response


# ================================================================
#  5. CHANGE PASSWORD — Parolni o'zgartirish
# ================================================================

@router.post(
    "/change-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Parolni o'zgartirish",
    description="""
    Foydalanuvchi o'z parolini o'zgartiradi.

    Talab qilinadi:
    - **current_password**: Hozirgi parol (tasdiqlash uchun)
    - **new_password**: Yangi parol (kamida 6 ta belgi)
    - **confirm_password**: Yangi parolni takrorlash
    """,
)
async def change_password(
    request: ChangePasswordRequest,
    current_user: CurrentUser,
    db: DBSession,
) -> MessageResponse:
    """
    O'z parolini o'zgartirish. Hozirgi parol talab qilinadi.
    """
    success, message = await change_user_password(db, current_user, request)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message,
        )

    return MessageResponse(message=message, success=True)


# ================================================================
#  6. RESET PASSWORD — Admin: boshqa foydalanuvchi parolini tiklash
# ================================================================

@router.post(
    "/reset-password/{user_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="[Admin] Parolni tiklash",
    description="""
    **Faqat Admin** boshqa foydalanuvchining parolini tiklaydi.

    Masalan, usta parolini unutib qo'ysa, Admin yangi parol beradi.

    - **user_id**: Paroli tiklanadigan foydalanuvchi ID si
    - **new_password** (body): Yangi parol (kamida 6 ta belgi)
    """,
)
async def reset_password(
    user_id: int,
    body: dict,
    admin_user: AdminUser,
    db: DBSession,
) -> MessageResponse:
    """
    Admin foydalanuvchi parolini majburiy tiklaydi.
    Body: `{"new_password": "yangi_parol"}`
    """
    new_password = body.get("new_password", "").strip()

    if not new_password:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="'new_password' maydoni bo'sh bo'lmasligi kerak.",
        )

    if len(new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Yangi parol kamida 6 ta belgidan iborat bo'lishi kerak.",
        )

    success, message = await reset_user_password(
        db=db,
        target_user_id=user_id,
        new_password=new_password,
        performed_by=admin_user,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message,
        )

    return MessageResponse(message=message, success=True)
