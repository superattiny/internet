# ================================================
# main.py — FastAPI ilovasining kirish nuqtasi
# Barcha router'lar, middleware va startup shu yerda
# ================================================

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.database.database import init_db
from app.utils.logger import setup_logger, logger

# --- API Router'lar (har yangi modul shu yerga qo'shiladi) ---
from app.api import auth      as auth_router
from app.api import orders    as orders_router
from app.api import workers   as workers_router
from app.api import locations as locations_router
from app.api import telegram  as telegram_router


# ================================================================
#  LIFESPAN — Ilova ishga tushganda va to'xtaganda
# ================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    FastAPI lifespan manager.
    yield dan OLDIN: startup (ishga tushish)
    yield dan KEYIN: shutdown (to'xtash)
    """
    # --- STARTUP ---
    setup_logger()
    logger.info(f"🚀 {settings.app_name} v{settings.app_version} ishga tushmoqda...")
    logger.info(f"📦 Ma'lumotlar bazasi: {settings.database_url}")

    # Jadvallarni yaratish (agar mavjud bo'lmasa)
    await init_db()
    logger.info("✅ Ma'lumotlar bazasi tayyor")

    # Telegram bot tekshiruvi
    if settings.telegram_bot_token:
        from app.integrations.telegram_bot import check_bot_info
        bot = await check_bot_info()
        if bot:
            logger.info(f"✅ Telegram bot: @{bot.get('username')}")
        else:
            logger.warning("⚠️ Telegram bot token noto'g'ri!")
    else:
        logger.info("ℹ️ Telegram bot sozlanmagan (.env da token yo'q)")

    yield  # <-- Ilova shu yerda ishlaydi

    # --- SHUTDOWN ---
    logger.info("🛑 CRM tizimi to'xtatilmoqda...")


# ================================================================
#  FASTAPI ILOVASI
# ================================================================

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="""
    ## 📺 TV Ta'mirlash Ustaxonasi — CRM API

    Professional ustaxona boshqaruv tizimi.

    ### Modullar:
    - **Auth**      — Kirish va chiqish (JWT)
    - **Orders**    — Zakazlar boshqaruvi (deadline, status tarixi)
    - **Workers**   — Ishchilar, balanslar, komisyon
    - **Locations** — 📍 Geolokatsiya: vizit trek, xarita
    - **Clients**   — Mijozlar bazasi *(keyingi bosqich)*
    - **Warehouse** — Ombor va zapchastlar *(keyingi bosqich)*
    - **Finance**   — Kassa va moliya *(keyingi bosqich)*
    """,
    docs_url="/docs",        # Swagger UI: http://localhost:8000/docs
    redoc_url="/redoc",      # ReDoc: http://localhost:8000/redoc
    lifespan=lifespan,
)


# ================================================================
#  MIDDLEWARE — Har bir so'rovga qo'llaniladigan qatlamlar
# ================================================================

# CORS — Frontend (React) dan so'rovlarga ruxsat berish
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        settings.frontend_url,          # http://localhost:5173
        "http://localhost:3000",         # Alternativ port
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,             # Cookie va JWT uchun
    allow_methods=["*"],                # GET, POST, PUT, DELETE, ...
    allow_headers=["*"],                # Authorization, Content-Type, ...
)


# ================================================================
#  API ROUTER'LAR — Modullar ulanishi
#  Har yangi modul yuqorida import qilinib, shu yerda ulanadi
# ================================================================

API_V1 = "/api/v1"

# ✅ Faol modullar
app.include_router(auth_router.router,      prefix=API_V1)
app.include_router(orders_router.router,    prefix=API_V1)
app.include_router(workers_router.router,   prefix=API_V1)
app.include_router(locations_router.router, prefix=API_V1)
app.include_router(telegram_router.router,  prefix=API_V1)

# 🔜 Keyingi bosqichlarda qo'shiladi:
# from app.api import clients, warehouse, finance, archive
# app.include_router(clients.router,   prefix=API_V1)
# app.include_router(warehouse.router, prefix=API_V1)
# app.include_router(finance.router,   prefix=API_V1)
# app.include_router(archive.router,   prefix=API_V1)


# ================================================================
#  ASOSIY ENDPOINT'LAR
# ================================================================

@app.get("/", tags=["Root"])
async def root():
    """
    Asosiy sahifa — API ishlayotganini tekshirish uchun.
    """
    return {
        "message": f"📺 {settings.app_name} API ishlayapti!",
        "version": settings.app_version,
        "docs": "/docs",
        "status": "ok",
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Sog'liq tekshiruvi — monitoring uchun.
    """
    from app.database.database import engine
    from sqlalchemy import text

    db_status = "ok"
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"error: {str(e)}"
        logger.error(f"❌ Database health check failed: {e}")

    return JSONResponse(
        content={
            "status": "ok" if db_status == "ok" else "degraded",
            "app": settings.app_name,
            "version": settings.app_version,
            "database": db_status,
            "debug": settings.debug,
        },
        status_code=200 if db_status == "ok" else 503,
    )
