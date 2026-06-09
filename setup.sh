#!/usr/bin/env bash
# ================================================================
#  TV Ta'mirlash CRM — Avtomatik o'rnatish skripti  v1.0
#
#  Ishlatilishi:
#    chmod +x setup.sh && ./setup.sh
#
#  Yaratiladi:
#    tv-crm/backend/   — FastAPI + SQLAlchemy + SQLite
#    tv-crm/frontend/  — React + Vite + Tailwind CSS
#
#  Kerakli dasturlar:
#    Python 3.9+  →  https://python.org
#    Node.js 18+  →  https://nodejs.org
# ================================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header()  { echo -e "\n${BOLD}${BLUE}━━━  $1  ━━━${NC}"; }

check_requirements() {
  header "Talablarni tekshirish"
  command -v python3 >/dev/null 2>&1 || error "Python3 topilmadi → https://python.org"
  command -v pip3    >/dev/null 2>&1 || error "pip3 topilmadi"
  command -v node    >/dev/null 2>&1 || error "Node.js topilmadi → https://nodejs.org"
  command -v npm     >/dev/null 2>&1 || error "npm topilmadi"
  PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
  NODE_VER=$(node -v | sed 's/v//')
  success "Python $PY_VER ✓"
  success "Node.js $NODE_VER ✓"
}

make_dirs() {
  header "Papkalar yaratilmoqda"
  mkdir -p tv-crm/backend/app/api
  mkdir -p tv-crm/backend/app/database/migrations
  mkdir -p tv-crm/backend/app/schemas
  mkdir -p tv-crm/backend/app/services
  mkdir -p tv-crm/backend/app/utils
  mkdir -p tv-crm/backend/app/integrations
  mkdir -p tv-crm/backend/tests
  mkdir -p tv-crm/frontend/src/api
  mkdir -p tv-crm/frontend/src/components/Layout
  mkdir -p tv-crm/frontend/src/components/Orders
  mkdir -p tv-crm/frontend/src/components/common
  mkdir -p tv-crm/frontend/src/components/Finance
  mkdir -p tv-crm/frontend/src/pages
  mkdir -p tv-crm/frontend/src/store
  mkdir -p tv-crm/frontend/src/styles
  mkdir -p tv-crm/frontend/src/utils
  mkdir -p tv-crm/frontend/public
  success "Barcha papkalar yaratildi"
}

write_files() {
  header "Fayllar yozilmoqda"
  cat > 'tv-crm/backend/.env.example' << 'TVCRM_EOF'
# ================================================
# TV CRM - Muhit o'zgaruvchilari (Namuna fayli)
# Bu faylni nusxalab .env nomini bering
# .env faylini HECH QACHON git'ga yuklamang!
# ================================================

# --- Ilova sozlamalari ---
APP_NAME="TV Ta'mirlash CRM"
APP_VERSION="1.0.0"
DEBUG=True
SECRET_KEY=your-very-secret-key-change-this-in-production

# --- Ma'lumotlar bazasi ---
# SQLite (mahalliy fayl, boshlash uchun)
DATABASE_URL=sqlite:///./tv_crm.db

# PostgreSQL (kelajakda korporativ versiya uchun)
# DATABASE_URL=postgresql://user:password@localhost:5432/tv_crm_db

# --- JWT Token sozlamalari ---
JWT_ALGORITHM=HS256
# Token amal qilish muddati (daqiqalarda): 8 soat = 480 daqiqa
ACCESS_TOKEN_EXPIRE_MINUTES=480

# --- CORS (Frontend manzili) ---
FRONTEND_URL=http://localhost:5173

# --- Telegram Bot (kelajakda) ---
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
TELEGRAM_CHAT_ID=your-chat-id

# --- Instagram (kelajakda) ---
INSTAGRAM_ACCESS_TOKEN=your-instagram-access-token
INSTAGRAM_PAGE_ID=your-page-id

# --- Gemini AI (kelajakda) ---
GEMINI_API_KEY=your-gemini-api-key

# --- SIP/Telefoniya (kelajakda) ---
SIP_SERVER_HOST=192.168.1.100
SIP_SERVER_PORT=5060
TVCRM_EOF

  cat > 'tv-crm/backend/requirements.txt' << 'TVCRM_EOF'
# ================================================
# TV CRM - Python kutubxonalari
# O'rnatish: pip install -r requirements.txt
# ================================================

# --- Web Framework ---
fastapi==0.111.0
uvicorn[standard]==0.29.0

# --- Ma'lumotlar bazasi ---
sqlalchemy==2.0.30
aiosqlite==0.20.0          # Async SQLite uchun
alembic==1.13.1            # Migratsiyalar uchun

# --- Ma'lumot validatsiyasi ---
pydantic==2.7.1
pydantic-settings==2.2.1   # .env o'qish uchun

# --- Autentifikatsiya ---
python-jose[cryptography]==3.3.0   # JWT tokenlar
bcrypt==4.2.1                      # Parol hash (passlib o'rniga to'g'ridan-to'g'ri)

# --- Fayl yuklash ---
python-multipart==0.0.9

# --- HTTP so'rovlar (integratsiyalar uchun) ---
httpx==0.27.0

# --- Vaqt va sana ---
python-dateutil==2.9.0

# --- Muhit o'zgaruvchilari ---
python-dotenv==1.0.1

# --- Logging ---
loguru==0.7.2

# --- Kelajakda kerak bo'ladigan kutubxonalar ---
# google-generativeai==0.5.4    # Gemini AI
# aiogram==3.6.0                # Telegram Bot
TVCRM_EOF

  cat > 'tv-crm/backend/run.py' << 'TVCRM_EOF'
# ================================================
# run.py — Serverni ishga tushirish
# Ishlatilishi: python run.py
# ================================================

import uvicorn
from app.config import settings


if __name__ == "__main__":
    print(f"\n{'='*50}")
    print(f"  📺 {settings.app_name}")
    print(f"  🌐 http://localhost:8000")
    print(f"  📖 Docs: http://localhost:8000/docs")
    print(f"{'='*50}\n")

    uvicorn.run(
        app="app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,      # Debug rejimda auto-reload
        log_level="debug" if settings.debug else "info",
    )
TVCRM_EOF

  cat > 'tv-crm/backend/app/__init__.py' << 'TVCRM_EOF'
# TV CRM - Backend Application Package
TVCRM_EOF

  cat > 'tv-crm/backend/app/config.py' << 'TVCRM_EOF'
# ================================================
# config.py — Ilova sozlamalari
# Barcha muhit o'zgaruvchilari shu yerdan o'qiladi
# ================================================

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    """
    Barcha ilova sozlamalari.
    Qiymatlar .env faylidan avtomatik o'qiladi.
    """

    # --- Ilova ma'lumotlari ---
    app_name: str = "TV Ta'mirlash CRM"
    app_version: str = "1.0.0"
    debug: bool = True

    # --- Xavfsizlik ---
    secret_key: str = "change-this-in-production"

    # --- Ma'lumotlar bazasi ---
    database_url: str = "sqlite:///./tv_crm.db"

    # --- JWT Token ---
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 480  # 8 soat

    # --- CORS ---
    frontend_url: str = "http://localhost:5173"

    # --- Telegram (kelajakda) ---
    telegram_bot_token: str = ""
    telegram_chat_id: str = ""

    # --- Instagram (kelajakda) ---
    instagram_access_token: str = ""
    instagram_page_id: str = ""

    # --- Gemini AI (kelajakda) ---
    gemini_api_key: str = ""

    # --- SIP Telefoniya (kelajakda) ---
    sip_server_host: str = "192.168.1.100"
    sip_server_port: int = 5060

    # .env faylini avtomatik o'qish uchun
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache()
def get_settings() -> Settings:
    """
    Sozlamalarni bir marta o'qib, xotirada saqlaydi (cache).
    Dependency Injection orqali ishlatiladi:
        settings = Depends(get_settings)
    """
    return Settings()


# Global sozlamalar ob'ekti — to'g'ridan-to'g'ri import qilish uchun
settings = get_settings()
TVCRM_EOF

  cat > 'tv-crm/backend/app/main.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/database/__init__.py' << 'TVCRM_EOF'
# Database package
TVCRM_EOF

  cat > 'tv-crm/backend/app/database/database.py' << 'TVCRM_EOF'
# ================================================
# database.py — Ma'lumotlar bazasi ulanishi
# SQLAlchemy async engine va session factory
# ================================================

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import event
from app.config import settings


# ------------------------------------------------
# 1. ASYNC ENGINE — ma'lumotlar bazasiga ulanish
# ------------------------------------------------
# SQLite uchun aiosqlite drayveri ishlatiladi
# connect_args: SQLite'da bir vaqtda bir nechta
# threaddan foydalanishga ruxsat beradi
engine = create_async_engine(
    url=settings.database_url.replace("sqlite:///", "sqlite+aiosqlite:///"),
    echo=settings.debug,       # Debug rejimda SQL so'rovlarni konsolga chiqaradi
    connect_args={"check_same_thread": False},
)


# ------------------------------------------------
# 2. SESSION FACTORY — har bir so'rov uchun session
# ------------------------------------------------
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,    # Commit'dan keyin ob'ektlar eskirib qolmasin
    autocommit=False,
    autoflush=False,
)


# ------------------------------------------------
# 3. BASE MODEL — barcha modellar shu klassdan meros oladi
# ------------------------------------------------
class Base(DeclarativeBase):
    """
    Barcha SQLAlchemy modellari uchun asosiy klass.
    Har bir model: class MyModel(Base)
    """
    pass


# ------------------------------------------------
# 4. DEPENDENCY — FastAPI route'larida ishlatiladi
# ------------------------------------------------
async def get_db() -> AsyncSession:
    """
    FastAPI Dependency Injection uchun database session.

    Ishlatilish:
        @router.get("/orders")
        async def get_orders(db: AsyncSession = Depends(get_db)):
            ...

    Session avtomatik yopiladi (try/finally orqali).
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


# ------------------------------------------------
# 5. INIT — Barcha jadvallarni yaratish
# ------------------------------------------------
async def init_db():
    """
    Ilova ishga tushganda barcha jadvallarni yaratadi.
    Agar jadval mavjud bo'lsa, o'zgartirmaydi (checkfirst=True).
    """
    # Models import qilinishi kerak, aks holda Base ularni bilmaydi
    from app.database import models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def drop_db():
    """
    Faqat development/test uchun: barcha jadvallarni o'chiradi.
    Production'da HECH QACHON ishlatmang!
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
TVCRM_EOF

  cat > 'tv-crm/backend/app/database/models.py' << 'TVCRM_EOF'
# ================================================
# models.py — Barcha ma'lumotlar bazasi modellari
# Har bir klass = bitta jadval
# ================================================

from datetime import datetime
from typing import Optional
from sqlalchemy import (
    String, Integer, Float, Boolean, Text,
    DateTime, ForeignKey, Enum as SAEnum,
    UniqueConstraint, Index
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
import enum

from app.database.database import Base


# ================================================================
#  ENUM TURLARI — Jadval ustunlarida qat'iy qiymatlar uchun
# ================================================================

class UserRole(str, enum.Enum):
    """Foydalanuvchi roli"""
    ADMIN    = "admin"      # To'liq huquq
    OPERATOR = "operator"   # Zakazlarni boshqaradi
    MASTER   = "master"     # Faqat o'z zakazlarini ko'radi


class OrderStatus(str, enum.Enum):
    """Zakaz holati"""
    NEW         = "new"         # Yangi, hali qabul qilinmagan
    ACCEPTED    = "accepted"    # Qabul qilindi, usta tayinlandi
    DIAGNOSING  = "diagnosing"  # Diagnostika jarayonida
    WAITING     = "waiting"     # Zapchast kutilmoqda
    IN_REPAIR   = "in_repair"   # Ta'mirlanmoqda
    ON_THE_WAY  = "on_the_way"  # Usta vizitga yo'lda (geolokatsiya faol)
    DONE        = "done"        # Ta'mir tugadi, mijozga topshirilmagan
    DELIVERED   = "delivered"   # Mijozga topshirildi, to'lov qilindi
    CANCELLED   = "cancelled"   # Rad etildi / Bekor qilindi


class OrderSource(str, enum.Enum):
    """Zakaz qayerdan keldi"""
    WALK_IN   = "walk_in"    # Bevosita ustaxonaga keldi
    PHONE     = "phone"      # Telefon orqali
    TELEGRAM  = "telegram"   # Telegram bot orqali
    INSTAGRAM = "instagram"  # Instagram DM orqali
    OTHER     = "other"      # Boshqa


class PaymentMethod(str, enum.Enum):
    """To'lov usuli"""
    CASH     = "cash"      # Naqd pul
    CARD     = "card"      # Plastik karta
    TRANSFER = "transfer"  # Bank o'tkazmasi


class TransactionType(str, enum.Enum):
    """Moliyaviy operatsiya turi"""
    INCOME   = "income"   # Daromad (to'lov keldi)
    EXPENSE  = "expense"  # Xarajat (pul chiqdi)
    SALARY   = "salary"   # Ish haqi to'lovi
    REFUND   = "refund"   # Qaytarish


class WarehouseMovementType(str, enum.Enum):
    """Ombor harakati turi"""
    IN      = "in"      # Kirim — yangi zapchast keldi
    OUT     = "out"     # Chiqim — ta'mirda ishlatildi
    RETURN  = "return"  # Qaytarish — mijoz tomonidan


# ================================================================
#  1. USERS — Foydalanuvchilar jadvali (Admin, Operator, Usta)
# ================================================================

class User(Base):
    """
    Tizim foydalanuvchilari.
    Admin, Operator va Ustalar shu jadvalda saqlanadi.
    """
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Shaxsiy ma'lumotlar ---
    full_name: Mapped[str]           = mapped_column(String(100), nullable=False)
    phone: Mapped[Optional[str]]     = mapped_column(String(20), nullable=True)
    username: Mapped[str]            = mapped_column(String(50), unique=True, nullable=False)
    hashed_password: Mapped[str]     = mapped_column(String(255), nullable=False)

    # --- Rol va holat ---
    role: Mapped[UserRole]           = mapped_column(SAEnum(UserRole), default=UserRole.OPERATOR)
    is_active: Mapped[bool]          = mapped_column(Boolean, default=True)

    # --- Ish haqi va balans (faqat Usta/Operator uchun) ---
    # Bu ustaning shaxsiy balans hisob raqami:
    # har bir tugallangan zakaz uchun ulush qo'shiladi
    balance: Mapped[float]           = mapped_column(Float, default=0.0)
    salary_rate: Mapped[float]       = mapped_column(Float, default=0.0)
    # Har bir zakaz uchun foiz ulushi (masalan: 30.0 = 30%)
    commission_percent: Mapped[float] = mapped_column(Float, default=0.0)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]     = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]     = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # --- Bog'liq ma'lumotlar ---
    orders_as_master: Mapped[list["Order"]]       = relationship("Order", foreign_keys="Order.master_id", back_populates="master")
    orders_as_operator: Mapped[list["Order"]]     = relationship("Order", foreign_keys="Order.operator_id", back_populates="operator")
    salary_payments: Mapped[list["SalaryPayment"]] = relationship("SalaryPayment", foreign_keys="SalaryPayment.worker_id", back_populates="worker")
    locations: Mapped[list["WorkerLocation"]]      = relationship("WorkerLocation", back_populates="worker", order_by="WorkerLocation.recorded_at.desc()")

    def __repr__(self) -> str:
        return f"<User id={self.id} username={self.username} role={self.role}>"


# ================================================================
#  2. CLIENTS — Mijozlar jadvali
# ================================================================

class Client(Base):
    """
    Ustaxona mijozlari.
    Telegram/Instagram orqali kelganda ham shu jadvalga yoziladi.
    """
    __tablename__ = "clients"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Shaxsiy ma'lumotlar ---
    full_name: Mapped[str]               = mapped_column(String(100), nullable=False)
    phone: Mapped[Optional[str]]         = mapped_column(String(20), nullable=True, index=True)
    phone_secondary: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    address: Mapped[Optional[str]]       = mapped_column(String(255), nullable=True)
    notes: Mapped[Optional[str]]         = mapped_column(Text, nullable=True)

    # --- Ijtimoiy tarmoq ma'lumotlari (integratsiyalar uchun) ---
    telegram_id: Mapped[Optional[str]]   = mapped_column(String(50), nullable=True, unique=True)
    telegram_username: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    instagram_id: Mapped[Optional[str]]  = mapped_column(String(50), nullable=True, unique=True)

    # --- Statistika ---
    total_orders: Mapped[int]            = mapped_column(Integer, default=0)
    total_spent: Mapped[float]           = mapped_column(Float, default=0.0)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # --- Bog'liq ma'lumotlar ---
    orders: Mapped[list["Order"]]        = relationship("Order", back_populates="client")

    def __repr__(self) -> str:
        return f"<Client id={self.id} name={self.full_name} phone={self.phone}>"


# ================================================================
#  3. ORDERS — Zakazlar jadvali (CRM'ning yuragi)
# ================================================================

class Order(Base):
    """
    Har bir ta'mir zakazi.
    Bu jadval CRM tizimining asosiy jadvali hisoblanadi.
    """
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Zakaz raqami (chiroyli, o'qish uchun qulay) ---
    # Masalan: TV-2024-0001
    order_number: Mapped[str]            = mapped_column(String(20), unique=True, nullable=False, index=True)

    # --- Mijoz (kim olib keldi) ---
    client_id: Mapped[int]               = mapped_column(Integer, ForeignKey("clients.id"), nullable=False)
    client: Mapped["Client"]             = relationship("Client", back_populates="orders")

    # --- Ishchilar ---
    operator_id: Mapped[Optional[int]]   = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    master_id: Mapped[Optional[int]]     = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    operator: Mapped[Optional["User"]]   = relationship("User", foreign_keys=[operator_id], back_populates="orders_as_operator")
    master: Mapped[Optional["User"]]     = relationship("User", foreign_keys=[master_id], back_populates="orders_as_master")

    # --- Televizor ma'lumotlari ---
    tv_brand: Mapped[Optional[str]]      = mapped_column(String(50), nullable=True)   # Samsung, LG, Sony...
    tv_model: Mapped[Optional[str]]      = mapped_column(String(100), nullable=True)  # UA55TU8000
    tv_diagonal: Mapped[Optional[str]]   = mapped_column(String(20), nullable=True)   # 55", 43"
    tv_serial_number: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)

    # --- Nosozlik tavsifi ---
    problem_description: Mapped[str]     = mapped_column(Text, nullable=False)
    # AI tahlilidan kelgan natija (Gemini)
    ai_diagnosis: Mapped[Optional[str]]  = mapped_column(Text, nullable=True)
    # Usta tomonidan yozilgan haqiqiy tashxis
    master_diagnosis: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    # Bajarilgan ishlar tavsifi
    work_done: Mapped[Optional[str]]     = mapped_column(Text, nullable=True)

    # --- Holat va manba ---
    status: Mapped[OrderStatus]          = mapped_column(SAEnum(OrderStatus), default=OrderStatus.NEW, index=True)
    source: Mapped[OrderSource]          = mapped_column(SAEnum(OrderSource), default=OrderSource.WALK_IN)

    # --- Moliyaviy ma'lumotlar ---
    estimated_price: Mapped[float]       = mapped_column(Float, default=0.0)  # Dastlabki narx
    final_price: Mapped[float]           = mapped_column(Float, default=0.0)  # Yakuniy narx
    parts_cost: Mapped[float]            = mapped_column(Float, default=0.0)  # Zapchastlar narxi
    is_paid: Mapped[bool]                = mapped_column(Boolean, default=False)
    payment_method: Mapped[Optional[PaymentMethod]] = mapped_column(SAEnum(PaymentMethod), nullable=True)

    # --- Ustaga hisoblangan komisyon ---
    master_commission: Mapped[float]     = mapped_column(Float, default=0.0)

    # --- Qabul qilish paytidagi rasm/hujjat ---
    # Fayllar yo'llari vergul bilan ajratilgan holda saqlanadi
    photos: Mapped[Optional[str]]        = mapped_column(Text, nullable=True)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]         = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    accepted_at: Mapped[Optional[datetime]]  = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    delivered_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    # --- Arxiv (tugallangandan keyin) ---
    is_archived: Mapped[bool]            = mapped_column(Boolean, default=False)
    cancel_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Bog'liq ma'lumotlar ---
    status_history: Mapped[list["OrderStatusHistory"]]  = relationship("OrderStatusHistory", back_populates="order")
    used_parts: Mapped[list["OrderPart"]]               = relationship("OrderPart", back_populates="order")

    def __repr__(self) -> str:
        return f"<Order id={self.id} number={self.order_number} status={self.status}>"


# ================================================================
#  4. ORDER_STATUS_HISTORY — Zakaz holat tarixi
# ================================================================

class OrderStatusHistory(Base):
    """
    Har bir zakaz statusining o'zgarish tarixi.
    Kim, qachon, qaysi statusga o'zgartirganini saqlaydi.
    """
    __tablename__ = "order_status_history"

    id: Mapped[int]                  = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[int]            = mapped_column(Integer, ForeignKey("orders.id"), nullable=False)
    changed_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)

    old_status: Mapped[Optional[OrderStatus]] = mapped_column(SAEnum(OrderStatus), nullable=True)
    new_status: Mapped[OrderStatus]           = mapped_column(SAEnum(OrderStatus), nullable=False)
    comment: Mapped[Optional[str]]            = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime]     = mapped_column(DateTime, server_default=func.now())

    # --- Bog'liq ma'lumotlar ---
    order: Mapped["Order"]           = relationship("Order", back_populates="status_history")
    changed_by: Mapped[Optional["User"]] = relationship("User")

    def __repr__(self) -> str:
        return f"<OrderStatusHistory order={self.order_id} {self.old_status}→{self.new_status}>"


# ================================================================
#  5. WAREHOUSE_ITEMS — Ombor: Zapchastlar va materiallar
# ================================================================

class WarehouseItem(Base):
    """
    Omborhona: har bir zapchast yoki material.
    Ekranlar, platalar, kondensatorlar, t-con va boshqalar.
    """
    __tablename__ = "warehouse_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Mahsulot ma'lumotlari ---
    name: Mapped[str]                  = mapped_column(String(200), nullable=False)
    article: Mapped[Optional[str]]     = mapped_column(String(100), nullable=True, unique=True)  # Katalog raqami
    category: Mapped[Optional[str]]    = mapped_column(String(100), nullable=True)  # Ekran, Plata, T-con...
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # --- Qaysi televiozorga mos keladi ---
    compatible_brands: Mapped[Optional[str]]  = mapped_column(String(255), nullable=True)  # Samsung, LG
    compatible_models: Mapped[Optional[str]]  = mapped_column(Text, nullable=True)

    # --- Miqdor va narx ---
    quantity: Mapped[int]              = mapped_column(Integer, default=0)
    min_quantity: Mapped[int]          = mapped_column(Integer, default=1)   # Minimal qoldiq (ogohlantirish uchun)
    unit: Mapped[str]                  = mapped_column(String(20), default="dona")

    purchase_price: Mapped[float]      = mapped_column(Float, default=0.0)   # Sotib olish narxi
    selling_price: Mapped[float]       = mapped_column(Float, default=0.0)   # Sotish narxi

    # --- Holat ---
    is_active: Mapped[bool]            = mapped_column(Boolean, default=True)

    # --- Vaqt belgilari ---
    created_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # --- Bog'liq ma'lumotlar ---
    movements: Mapped[list["WarehouseMovement"]]  = relationship("WarehouseMovement", back_populates="item")
    order_parts: Mapped[list["OrderPart"]]        = relationship("OrderPart", back_populates="warehouse_item")

    @property
    def is_low_stock(self) -> bool:
        """Zaxira kam qolganini tekshiradi"""
        return self.quantity <= self.min_quantity

    def __repr__(self) -> str:
        return f"<WarehouseItem id={self.id} name={self.name} qty={self.quantity}>"


# ================================================================
#  6. WAREHOUSE_MOVEMENTS — Ombor harakati tarixi
# ================================================================

class WarehouseMovement(Base):
    """
    Omborga kirib-chiqqan barcha zapchastlar tarixi.
    Har bir kirim/chiqim shu yerda qayd etiladi.
    """
    __tablename__ = "warehouse_movements"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    item_id: Mapped[int]                  = mapped_column(Integer, ForeignKey("warehouse_items.id"), nullable=False)
    performed_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    order_id: Mapped[Optional[int]]       = mapped_column(Integer, ForeignKey("orders.id"), nullable=True)

    movement_type: Mapped[WarehouseMovementType] = mapped_column(SAEnum(WarehouseMovementType), nullable=False)

    quantity: Mapped[int]                 = mapped_column(Integer, nullable=False)
    price_per_unit: Mapped[float]         = mapped_column(Float, default=0.0)
    total_price: Mapped[float]            = mapped_column(Float, default=0.0)

    notes: Mapped[Optional[str]]          = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime]          = mapped_column(DateTime, server_default=func.now())

    # --- Bog'liq ma'lumotlar ---
    item: Mapped["WarehouseItem"]         = relationship("WarehouseItem", back_populates="movements")
    performed_by: Mapped[Optional["User"]] = relationship("User")
    order: Mapped[Optional["Order"]]      = relationship("Order")

    def __repr__(self) -> str:
        return f"<WarehouseMovement item={self.item_id} type={self.movement_type} qty={self.quantity}>"


# ================================================================
#  7. ORDER_PARTS — Zakazda ishlatilgan zapchastlar
# ================================================================

class OrderPart(Base):
    """
    Har bir zakazda ishlatilgan zapchastlar.
    Zakaz va Ombor o'rtasidagi bog'lovchi jadval.
    """
    __tablename__ = "order_parts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    order_id: Mapped[int]              = mapped_column(Integer, ForeignKey("orders.id"), nullable=False)
    warehouse_item_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("warehouse_items.id"), nullable=True)

    # Agar zapchast ombordan emas, tashqaridan olingan bo'lsa:
    custom_part_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)

    quantity: Mapped[int]              = mapped_column(Integer, default=1)
    price_per_unit: Mapped[float]      = mapped_column(Float, default=0.0)
    total_price: Mapped[float]         = mapped_column(Float, default=0.0)

    created_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now())

    # --- Bog'liq ma'lumotlar ---
    order: Mapped["Order"]             = relationship("Order", back_populates="used_parts")
    warehouse_item: Mapped[Optional["WarehouseItem"]] = relationship("WarehouseItem", back_populates="order_parts")

    def __repr__(self) -> str:
        return f"<OrderPart order={self.order_id} item={self.warehouse_item_id} qty={self.quantity}>"


# ================================================================
#  8. FINANCE_TRANSACTIONS — Moliyaviy operatsiyalar (Kassa)
# ================================================================

class FinanceTransaction(Base):
    """
    Ustaxona kassasidagi barcha moliyaviy operatsiyalar.
    Kirim, chiqim, ish haqi — hammasi shu yerda.
    """
    __tablename__ = "finance_transactions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    transaction_type: Mapped[TransactionType] = mapped_column(SAEnum(TransactionType), nullable=False)

    amount: Mapped[float]              = mapped_column(Float, nullable=False)
    description: Mapped[str]          = mapped_column(String(255), nullable=False)
    notes: Mapped[Optional[str]]      = mapped_column(Text, nullable=True)

    # --- Kim amalga oshirdi ---
    performed_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    performed_by: Mapped[Optional["User"]] = relationship("User")

    # --- Qaysi zakaz bilan bog'liq (agar bo'lsa) ---
    order_id: Mapped[Optional[int]]   = mapped_column(Integer, ForeignKey("orders.id"), nullable=True)
    order: Mapped[Optional["Order"]]  = relationship("Order")

    # --- To'lov usuli ---
    payment_method: Mapped[Optional[PaymentMethod]] = mapped_column(SAEnum(PaymentMethod), nullable=True)

    # --- Vaqt belgisi ---
    created_at: Mapped[datetime]      = mapped_column(DateTime, server_default=func.now())

    def __repr__(self) -> str:
        return f"<FinanceTransaction type={self.transaction_type} amount={self.amount}>"


# ================================================================
#  9. SALARY_PAYMENTS — Ishchilarga ish haqi to'lovlari
# ================================================================

class SalaryPayment(Base):
    """
    Ustalarga va operatorlarga qilingan ish haqi to'lovlari.
    Har bir to'lov qayd etiladi, balansdan ayiriladi.
    """
    __tablename__ = "salary_payments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    worker_id: Mapped[int]            = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    worker: Mapped["User"]            = relationship("User", foreign_keys="SalaryPayment.worker_id", back_populates="salary_payments")

    amount: Mapped[float]             = mapped_column(Float, nullable=False)
    payment_method: Mapped[PaymentMethod] = mapped_column(SAEnum(PaymentMethod), default=PaymentMethod.CASH)

    notes: Mapped[Optional[str]]      = mapped_column(Text, nullable=True)

    # --- Kim to'ladi ---
    paid_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    paid_by: Mapped[Optional["User"]] = relationship("User", foreign_keys="SalaryPayment.paid_by_id")

    created_at: Mapped[datetime]      = mapped_column(DateTime, server_default=func.now())

    def __repr__(self) -> str:
        return f"<SalaryPayment worker={self.worker_id} amount={self.amount}>"


# ================================================================
#  10. SHOP_SETTINGS — Ustaxona sozlamalari
# ================================================================

class ShopSettings(Base):
    """
    Ustaxona umumiy sozlamalari.
    Bitta qator bo'ladi (id=1).
    """
    __tablename__ = "shop_settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    shop_name: Mapped[str]             = mapped_column(String(200), default="TV Ta'mirlash Ustaxonasi")
    phone: Mapped[Optional[str]]       = mapped_column(String(20), nullable=True)
    address: Mapped[Optional[str]]     = mapped_column(String(255), nullable=True)

    # --- Moliyaviy sozlamalar ---
    # Ustaxonaning umumiy balansi (sof kassa)
    total_balance: Mapped[float]       = mapped_column(Float, default=0.0)
    # Xarajatlar fondi
    expense_balance: Mapped[float]     = mapped_column(Float, default=0.0)

    # --- Zakaz raqami uchun counter ---
    order_counter: Mapped[int]         = mapped_column(Integer, default=0)

    updated_at: Mapped[datetime]       = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    def __repr__(self) -> str:
        return f"<ShopSettings name={self.shop_name} balance={self.total_balance}>"


# ================================================================
#  11. WORKER_LOCATIONS — Ustalar geolokatsiya tarixi
# ================================================================

class WorkerLocation(Base):
    """
    Ustaning joylashuv yozuvlari.

    Arxitektura qarorlari:
      - ALOHIDA jadval: users jadvali shishmaydi
      - TARIX saqlanadi: faqat oxirgisi emas, butun vizit yo'nalishi
      - Har bir on_the_way statusidagi zakaz uchun koordinatalar yoziladi
      - Mobil ilova fonga shu jadvalga yozib turadi

    Misol oqim:
      1. Usta status → on_the_way     (vizit boshlandi)
      2. Mobil ilova har N sekundda koordinata jo'natadi  → bu jadval
      3. Usta status → in_repair/done (vizit tugadi)
      4. Admin xaritada ustaning butun yo'lini ko'radi
    """
    __tablename__ = "worker_locations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # --- Kim (usta) ---
    worker_id: Mapped[int]              = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    worker: Mapped["User"]              = relationship("User", back_populates="locations")

    # --- Qaysi zakaz viziti uchun ---
    order_id: Mapped[Optional[int]]     = mapped_column(
        Integer, ForeignKey("orders.id", ondelete="SET NULL"),
        nullable=True, index=True
    )
    order: Mapped[Optional["Order"]]    = relationship("Order")

    # --- Koordinatalar (WGS84 standart) ---
    latitude: Mapped[float]             = mapped_column(
        Float, nullable=False,
        # Toshkent: ~41.3°, O'zbekiston: 37.2° – 45.6°
    )
    longitude: Mapped[float]            = mapped_column(
        Float, nullable=False,
        # Toshkent: ~69.2°, O'zbekiston: 56.0° – 73.1°
    )

    # --- Qo'shimcha GPS ma'lumotlari (ixtiyoriy) ---
    accuracy:  Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # GPS aniqligi (metrda), masalan: 5.0 = ±5 metr
    )
    speed:     Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # Tezlik (m/s), masalan: 8.3 = ~30 km/h
    )
    bearing:   Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # Yo'nalish (gradus, 0=Shimol, 90=Sharq, 180=Janub, 270=G'arb)
    )
    altitude:  Mapped[Optional[float]]  = mapped_column(
        Float, nullable=True,
        # Balandlik (metrda dengiz sathidan)
    )

    # --- Manba va sifat ---
    # Koordinata qayerdan olingan: gps / network / passive
    location_provider: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True, default="gps"
    )
    # Batareya darajasi (%) — fon rejimini optimallashtirish uchun
    battery_level: Mapped[Optional[int]] = mapped_column(
        Integer, nullable=True
    )

    # --- Vaqt (mobil qurilma vaqti va server qabul vaqti) ---
    # device_time: qurilmaning mahalliy vaqti (oflayn rejimda ham to'g'ri bo'ladi)
    device_time: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    # recorded_at: server qabul qilgan vaqt (UTC) — asosiy vaqt damg'asi
    recorded_at: Mapped[datetime]           = mapped_column(
        DateTime, server_default=func.now(), nullable=False, index=True
    )

    def __repr__(self) -> str:
        return (
            f"<WorkerLocation worker={self.worker_id} "
            f"order={self.order_id} "
            f"({self.latitude:.4f}, {self.longitude:.4f}) "
            f"@ {self.recorded_at}>"
        )


# ================================================================
#  DATABASE INDEKSLARI — Tezlik uchun
# ================================================================
# Tez-tez qidiriladigan ustunlarga index qo'shamiz

Index("idx_orders_status",     Order.status)
Index("idx_orders_client",     Order.client_id)
Index("idx_orders_master",     Order.master_id)
Index("idx_orders_created",    Order.created_at)
Index("idx_orders_archived",   Order.is_archived)
Index("idx_clients_phone",     Client.phone)
Index("idx_finance_type",      FinanceTransaction.transaction_type)
Index("idx_finance_created",   FinanceTransaction.created_at)
Index("idx_warehouse_article", WarehouseItem.article)

# Geolokatsiya uchun kompozit indeks:
# "Ushbu ustaning, ushbu zakaz uchun, vaqt bo'yicha tartiblangan yozuvlari"
Index("idx_location_worker_order",   WorkerLocation.worker_id, WorkerLocation.order_id)
Index("idx_location_worker_time",    WorkerLocation.worker_id, WorkerLocation.recorded_at)

TVCRM_EOF

  cat > 'tv-crm/backend/app/database/migrations/__init__.py' << 'TVCRM_EOF'
# backend/app/database/migrations/__init__.py
TVCRM_EOF
  cat > 'tv-crm/backend/app/database/migrations/init_db.py' << 'TVCRM_EOF'
# ================================================
# init_db.py — Ma'lumotlar bazasini boshlang'ich
# ma'lumotlar bilan to'ldirish (seed script)
#
# Ishlatilishi:
#   cd backend
#   python -m app.database.migrations.init_db
# ================================================

import asyncio
import sys
import os

# Loyiha root'ini path'ga qo'shamiz
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database.database import init_db, AsyncSessionLocal, engine
from app.database.models import (
    User, UserRole,
    ShopSettings,
    WarehouseItem,
)
from app.utils.auth import hash_password


# ================================================================
#  BOSHLANG'ICH MA'LUMOTLAR
# ================================================================

INITIAL_ADMIN = {
    "full_name": "Administrator",
    "username": "admin",
    "password": "admin123",        # Ishga tushirgandan keyin O'ZGARTIRING!
    "role": UserRole.ADMIN,
    "phone": "+998901234567",
    "balance": 0.0,
    "salary_rate": 0.0,
    "commission_percent": 0.0,
}

INITIAL_SHOP_SETTINGS = {
    "shop_name": "TV Ta'mirlash Ustaxonasi",
    "phone": "+998901234567",
    "address": "Toshkent shahar, ...",
    "total_balance": 0.0,
    "expense_balance": 0.0,
    "order_counter": 0,
}

# Boshlang'ich zapchastlar namunasi
INITIAL_WAREHOUSE_ITEMS = [
    {
        "name": "Samsung 55\" LCD Panel",
        "article": "BN95-07236A",
        "category": "Ekran",
        "description": "Samsung 55 dyuym LCD matritsa",
        "compatible_brands": "Samsung",
        "compatible_models": "QN55Q60B, UN55TU8000",
        "quantity": 2,
        "min_quantity": 1,
        "unit": "dona",
        "purchase_price": 1500000.0,
        "selling_price": 1800000.0,
    },
    {
        "name": "LG 43\" T-CON Board",
        "article": "EAT64532802",
        "category": "T-CON",
        "description": "LG 43 dyuym T-CON plata",
        "compatible_brands": "LG",
        "compatible_models": "43LM5700, 43UQ7500",
        "quantity": 3,
        "min_quantity": 1,
        "unit": "dona",
        "purchase_price": 250000.0,
        "selling_price": 350000.0,
    },
    {
        "name": "Universal Power Board 32-65\"",
        "article": "PWR-UNI-001",
        "category": "Quvvat plata",
        "description": "Universal quvvat bloki, 32-65 dyuym",
        "compatible_brands": "Samsung, LG, Sony, Philips",
        "compatible_models": "Universal",
        "quantity": 5,
        "min_quantity": 2,
        "unit": "dona",
        "purchase_price": 180000.0,
        "selling_price": 260000.0,
    },
    {
        "name": "Kondensator 1000uF 25V",
        "article": "CAP-1000-25",
        "category": "Komponent",
        "description": "Elektrolit kondensator, quvvat bloki uchun",
        "compatible_brands": "Universal",
        "quantity": 50,
        "min_quantity": 10,
        "unit": "dona",
        "purchase_price": 2000.0,
        "selling_price": 5000.0,
    },
    {
        "name": "HDMI Kabel 2m",
        "article": "CBL-HDMI-2M",
        "category": "Kabel",
        "description": "HDMI 2.0 kabel, 2 metr",
        "compatible_brands": "Universal",
        "quantity": 10,
        "min_quantity": 3,
        "unit": "dona",
        "purchase_price": 25000.0,
        "selling_price": 45000.0,
    },
]


# ================================================================
#  SEED FUNKSIYALARI
# ================================================================

async def create_admin_user(session: AsyncSession) -> None:
    """Admin foydalanuvchi yaratadi (agar mavjud bo'lmasa)"""

    # Mavjudligini tekshirish
    result = await session.execute(
        select(User).where(User.username == INITIAL_ADMIN["username"])
    )
    existing = result.scalar_one_or_none()

    if existing:
        print(f"  ⚠️  Admin allaqachon mavjud: {INITIAL_ADMIN['username']}")
        return

    admin = User(
        full_name=INITIAL_ADMIN["full_name"],
        username=INITIAL_ADMIN["username"],
        hashed_password=hash_password(INITIAL_ADMIN["password"]),
        role=INITIAL_ADMIN["role"],
        phone=INITIAL_ADMIN["phone"],
        balance=INITIAL_ADMIN["balance"],
        salary_rate=INITIAL_ADMIN["salary_rate"],
        commission_percent=INITIAL_ADMIN["commission_percent"],
        is_active=True,
    )
    session.add(admin)
    print(f"  ✅ Admin yaratildi: {INITIAL_ADMIN['username']} / {INITIAL_ADMIN['password']}")


async def create_shop_settings(session: AsyncSession) -> None:
    """Ustaxona sozlamalarini yaratadi (agar mavjud bo'lmasa)"""

    result = await session.execute(select(ShopSettings))
    existing = result.scalar_one_or_none()

    if existing:
        print(f"  ⚠️  Ustaxona sozlamalari allaqachon mavjud")
        return

    settings = ShopSettings(**INITIAL_SHOP_SETTINGS)
    session.add(settings)
    print(f"  ✅ Ustaxona sozlamalari yaratildi: {INITIAL_SHOP_SETTINGS['shop_name']}")


async def create_warehouse_items(session: AsyncSession) -> None:
    """Namuna zapchastlarni omborga qo'shadi"""

    result = await session.execute(select(WarehouseItem))
    existing = result.scalars().all()

    if existing:
        print(f"  ⚠️  Omborda {len(existing)} ta mahsulot allaqachon mavjud")
        return

    for item_data in INITIAL_WAREHOUSE_ITEMS:
        item = WarehouseItem(**item_data)
        session.add(item)

    print(f"  ✅ {len(INITIAL_WAREHOUSE_ITEMS)} ta zapchast omborga qo'shildi")


# ================================================================
#  ASOSIY FUNKSIYA
# ================================================================

async def run_migrations() -> None:
    """
    Barcha migration qadamlarini ketma-ket bajaradi:
    1. Jadvallarni yaratadi
    2. Boshlang'ich ma'lumotlarni kiritadi
    """
    print("\n" + "="*50)
    print("  TV CRM — Ma'lumotlar Bazasi Initsializatsiyasi")
    print("="*50)

    # 1. Jadvallarni yaratish
    print("\n📦 Jadvallar yaratilmoqda...")
    await init_db()
    print("  ✅ Barcha jadvallar yaratildi")

    # 2. Boshlang'ich ma'lumotlar
    print("\n🌱 Boshlang'ich ma'lumotlar kiritilmoqda...")
    async with AsyncSessionLocal() as session:
        async with session.begin():
            await create_admin_user(session)
            await create_shop_settings(session)
            await create_warehouse_items(session)

    print("\n" + "="*50)
    print("  ✅ Initsializatsiya muvaffaqiyatli tugadi!")
    print("="*50)
    print("\n⚠️  DIQQAT: Admin parolini o'zgartiring!")
    print(f"   Login: {INITIAL_ADMIN['username']}")
    print(f"   Parol: {INITIAL_ADMIN['password']}")
    print("="*50 + "\n")

    # Engine'ni yopish
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(run_migrations())
TVCRM_EOF

  cat > 'tv-crm/backend/app/api/__init__.py' << 'TVCRM_EOF'
# API routes package
TVCRM_EOF

  cat > 'tv-crm/backend/app/api/auth.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/api/orders.py' << 'TVCRM_EOF'
# ================================================
# api/orders.py — Zakazlar API Router
#
# Endpoint'lar ro'yxati:
#   POST   /api/v1/orders/                    → Yangi zakaz ochish
#   GET    /api/v1/orders/                    → Ro'yxat (filter + pagination)
#   GET    /api/v1/orders/stats               → Dashboard statistikasi
#   GET    /api/v1/orders/alerts/deadline     → Deadline ogohlantirishlari
#   GET    /api/v1/orders/{order_id}          → Bitta zakaz (ID bo'yicha)
#   GET    /api/v1/orders/by-number/{number}  → Bitta zakaz (raqam bo'yicha)
#   PATCH  /api/v1/orders/{order_id}          → Ma'lumotlarni yangilash
#   POST   /api/v1/orders/{order_id}/status   → Status o'zgartirish
#   POST   /api/v1/orders/{order_id}/payment  → To'lov qabul qilish
#   POST   /api/v1/orders/{order_id}/archive  → Arxivlash
# ================================================

from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status

from app.database.models import OrderStatus
from app.schemas.order import (
    OrderCreateRequest,
    OrderUpdateRequest,
    OrderStatusUpdateRequest,
    OrderPaymentRequest,
    OrderResponse,
    OrderListResponse,
    OrderDeadlineAlertResponse,
    OrderStatsResponse,
)
from app.services.order_service import (
    create_order,
    get_order_by_id,
    get_order_by_number,
    get_orders_list,
    update_order,
    update_order_status,
    process_payment,
    get_deadline_alerts,
    get_order_stats,
)
from app.utils.dependencies import (
    CurrentUser,
    OperatorOrAdminUser,
    AdminUser,
    DBSession,
)
from app.utils.logger import logger


# ================================================================
#  ROUTER
# ================================================================

router = APIRouter(
    prefix="/orders",
    tags=["📋 Orders — Zakazlar boshqaruvi"],
    responses={
        401: {"description": "Avtorizatsiya talab qilinadi"},
        403: {"description": "Bu amal uchun ruxsat yo'q"},
        404: {"description": "Zakaz topilmadi"},
    },
)


# ================================================================
#  1. YANGI ZAKAZ OCHISH
# ================================================================

@router.post(
    "/",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Yangi zakaz ochish",
    description="""
    Yangi ta'mir zakazi ochadi.

    **Majburiy maydonlar:**
    - `problem_description` — nosozlik tavsifi (min 5 belgi)
    - `deadline` — bajarilish muddati (kelajakdagi sana bo'lishi shart)
    - `client_id` yoki `client_name` — mijoz ma'lumoti

    **Deadline qoidasi:**
    O'tgan vaqt kiritilsa `422 Validation Error` qaytariladi.

    **Mijoz logikasi:**
    - `client_id` berilsa — mavjud mijoz ishlatiladi
    - Faqat `client_name` + `client_phone` berilsa — avval telefon bo'yicha
      qidiriladi, topilmasa yangi mijoz yaratiladi
    """,
)
async def create_new_order(
    data: OrderCreateRequest,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    try:
        return await create_order(db, data, current_user)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )


# ================================================================
#  2. ZAKAZLAR RO'YXATI
# ================================================================

@router.get(
    "/",
    response_model=OrderListResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakazlar ro'yxati",
    description="""
    Barcha zakazlar ro'yxatini filtrlash va sahifalash bilan qaytaradi.

    **Filtrlar:**
    - `status` — holat bo'yicha (new, accepted, in_repair, ...)
    - `master_id` — ustaning zakazlari
    - `client_id` — mijozning zakazlari
    - `search` — zakaz raqami, mijoz ismi yoki telefoni bo'yicha
    - `is_archived` — arxivlangan zakazlar (default: false)
    - `only_overdue` — faqat muddati o'tgan zakazlar

    **Sahifalash:**
    - `page` — sahifa raqami (default: 1)
    - `page_size` — sahifadagi elementlar soni (default: 20, max: 100)
    """,
)
async def list_orders(
    current_user: CurrentUser,
    db: DBSession,
    page:         int            = Query(default=1,     ge=1,   description="Sahifa raqami"),
    page_size:    int            = Query(default=20,    ge=1,   le=100, description="Sahifadagi zakazlar soni"),
    status_filter: Optional[OrderStatus] = Query(default=None, alias="status", description="Holat bo'yicha filter"),
    master_id:    Optional[int]  = Query(default=None,  description="Usta ID si bo'yicha filter"),
    client_id:    Optional[int]  = Query(default=None,  description="Mijoz ID si bo'yicha filter"),
    search:       Optional[str]  = Query(default=None,  min_length=2, description="Zakaz raqami yoki mijoz ismi"),
    is_archived:  bool           = Query(default=False, description="Arxivlangan zakazlarni ko'rsatish"),
    only_overdue: bool           = Query(default=False, description="Faqat muddati o'tgan zakazlar"),
) -> OrderListResponse:

    # Usta faqat o'z zakazlarini ko'ra oladi
    from app.database.models import UserRole
    effective_master_id = master_id
    if current_user.role == UserRole.MASTER:
        effective_master_id = current_user.id

    return await get_orders_list(
        db=db,
        page=page,
        page_size=page_size,
        status=status_filter,
        master_id=effective_master_id,
        client_id=client_id,
        search=search,
        is_archived=is_archived,
        only_overdue=only_overdue,
    )


# ================================================================
#  3. STATISTIKA (Dashboard)
# ================================================================

@router.get(
    "/stats",
    response_model=OrderStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Dashboard statistikasi",
    description="""
    Bugungi va umumiy zakaz statistikasini qaytaradi.

    Dashboard bosh sahifasida ko'rsatish uchun:
    - Jami zakazlar soni
    - Yangi / Jarayondagi / Bugun tugallangan
    - Muddati o'tgan zakazlar soni
    - Bugungi daromad
    """,
)
async def order_statistics(
    current_user: CurrentUser,
    db: DBSession,
) -> OrderStatsResponse:
    return await get_order_stats(db)


# ================================================================
#  4. DEADLINE OGOHLANTIRISHLARI
# ================================================================

@router.get(
    "/alerts/deadline",
    response_model=list[OrderDeadlineAlertResponse],
    status_code=status.HTTP_200_OK,
    summary="Deadline ogohlantirishlari",
    description="""
    Muddati o'tgan yoki yaqinlashgan zakazlar ro'yxatini qaytaradi.

    **Ogohlantirish darajalari** (`hours_remaining` qiymatiga qarab):
    | Daraja   | Shart               | Frontend rangi |
    |----------|---------------------|----------------|
    | OVERDUE  | `hours_remaining < 0` | 🔴 Qizil       |
    | CRITICAL | `0 < hours < 2`     | 🟠 To'q sariq  |
    | WARNING  | `2 < hours < 24`    | 🟡 Sariq       |
    | OK       | `hours >= 24`       | ✅ Yashil      |

    Javob eng kritiklari (muddati o'tganlar) birinchi keladi.

    `warning_hours` parametri orqali ogohlantirish chegara vaqtini
    o'zgartirish mumkin (default: 24 soat).
    """,
)
async def deadline_alerts(
    current_user: CurrentUser,
    db: DBSession,
    warning_hours: float = Query(
        default=24.0,
        ge=1.0,
        le=168.0,
        description="Necha soat qolganda ogohlantirish berilsin (1-168 soat, default: 24)"
    ),
) -> list[OrderDeadlineAlertResponse]:
    return await get_deadline_alerts(db, warning_hours=warning_hours)


# ================================================================
#  5. ZAKAZ — RAQAM BO'YICHA  (/{order_id} dan OLDIN bo'lishi shart)
# ================================================================

@router.get(
    "/by-number/{order_number}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakaz raqami bo'yicha topish",
    description="Masalan: `TV-2025-0001`",
)
async def get_order_by_order_number(
    order_number: str,
    current_user: CurrentUser,
    db: DBSession,
) -> OrderResponse:
    order = await get_order_by_number(db, order_number)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: {order_number}",
        )
    return order


# ================================================================
#  6. ZAKAZ — ID BO'YICHA
# ================================================================

@router.get(
    "/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Bitta zakaz ma'lumoti",
    description="ID bo'yicha bitta zakazning to'liq ma'lumoti (status tarixi bilan)",
)
async def get_single_order(
    order_id: int,
    current_user: CurrentUser,
    db: DBSession,
) -> OrderResponse:
    order = await get_order_by_id(db, order_id)
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: id={order_id}",
        )
    return order


# ================================================================
#  7. ZAKAZ MA'LUMOTLARINI YANGILASH (PATCH)
# ================================================================

@router.patch(
    "/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakaz ma'lumotlarini yangilash",
    description="""
    Zakaz maydonlarini yangilaydi. **Faqat yuborilgan maydonlar o'zgaradi.**

    Status o'zgartirish uchun bu endpoint ishlatilmaydi —
    buning uchun `POST /{order_id}/status` endpoint'ini ishlating.

    Yangilanishi mumkin bo'lgan maydonlar:
    - TV ma'lumotlari (brand, model, diagonal)
    - Nosozlik va tashxis tavsifi
    - Usta tayinlash (`master_id`)
    - Narxlar (estimated_price, final_price)
    - Deadline (faqat kelajakdagi vaqt)
    """,
)
async def patch_order(
    order_id: int,
    data: OrderUpdateRequest,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    result = await update_order(db, order_id, data, current_user)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: id={order_id}",
        )
    return result


# ================================================================
#  8. STATUS O'ZGARTIRISH
# ================================================================

@router.post(
    "/{order_id}/status",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Status o'zgartirish",
    description="""
    Zakaz statusini o'zgartiradi. Har bir o'zgarish **tarixga yoziladi**.

    **Ruxsat etilgan o'tishlar:**
    ```
    new        → accepted, cancelled
    accepted   → diagnosing, cancelled
    diagnosing → waiting, in_repair, cancelled
    waiting    → in_repair, cancelled
    in_repair  → done, waiting, cancelled
    done       → delivered, cancelled
    delivered  → (yakuniy — o'zgartirib bo'lmaydi)
    cancelled  → (yakuniy — o'zgartirib bo'lmaydi)
    ```

    **Eslatma:** `cancelled` holatiga o'tkazilsa, zakaz avtomatik
    arxivlanadi va `cancel_reason` saqlanadi.
    """,
)
async def change_order_status(
    order_id: int,
    data: OrderStatusUpdateRequest,
    current_user: CurrentUser,
    db: DBSession,
) -> OrderResponse:
    result, error = await update_order_status(db, order_id, data, current_user)

    if error:
        # "topilmadi" xatosi 404, qolganlar 400
        status_code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)

    return result


# ================================================================
#  9. TO'LOV QABUL QILISH
# ================================================================

@router.post(
    "/{order_id}/payment",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="To'lov qabul qilish",
    description="""
    Zakaz to'lovini qabul qiladi va statusni **`delivered`** ga o'tkazadi.

    **Shartlar:**
    - Zakaz `done` holatida bo'lishi shart
    - Zakaz hali to'lanmagan bo'lishi shart

    **Avtomatik bajariladi:**
    - `is_paid = True`
    - `delivered_at` vaqt stampini saqlaydi
    - Kassa jadvaliga **kirim** yozadi
    - Usta balansiga **komisyon** qo'shadi (agar foiz belgilangan bo'lsa)
    - Status tarixiga yozadi
    """,
)
async def accept_payment(
    order_id: int,
    data: OrderPaymentRequest,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    result, error = await process_payment(db, order_id, data, current_user)

    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)

    return result


# ================================================================
#  10. ARXIVLASH (Tugallangan zakazni arxivga o'tkazish)
# ================================================================

@router.post(
    "/{order_id}/archive",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Zakazni arxivlash",
    description="""
    Tugallangan zakazni arxivga o'tkazadi.

    **Shartlar:**
    - Faqat `delivered` yoki `cancelled` holatidagi zakazlar arxivlanadi
    - Allaqachon arxivlangan bo'lsa xato qaytariladi

    Arxivlangan zakazlar asosiy ro'yxatda ko'rinmaydi,
    lekin `is_archived=true` filter bilan topish mumkin.
    """,
)
async def archive_order(
    order_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> OrderResponse:
    # Zakazni topish
    order_resp = await get_order_by_id(db, order_id)
    if not order_resp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Zakaz topilmadi: id={order_id}",
        )

    # Arxivlash shartlarini tekshirish
    archivable = {OrderStatus.DELIVERED, OrderStatus.CANCELLED}
    if order_resp.status not in archivable:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Faqat 'delivered' yoki 'cancelled' holatidagi zakazlar arxivlanadi. "
                f"Hozirgi holat: '{order_resp.status.value}'"
            ),
        )

    if order_resp.is_archived:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu zakaz allaqachon arxivlangan",
        )

    # Arxivlash — to'g'ridan-to'g'ri DB da
    from sqlalchemy import update as sa_update
    from app.database.models import Order
    await db.execute(
        sa_update(Order)
        .where(Order.id == order_id)
        .values(is_archived=True)
    )
    await db.commit()

    logger.info(
        f"📦 Arxivlandi: order_id={order_id} | "
        f"Kim: {current_user.username}"
    )

    # Yangilangan zakazni qaytarish
    fresh = await get_order_by_id(db, order_id)
    return fresh
TVCRM_EOF

  cat > 'tv-crm/backend/app/api/workers.py' << 'TVCRM_EOF'
# ================================================
# api/workers.py — Ishchilar API Router
#
# Endpoint'lar ro'yxati:
#   POST   /api/v1/workers/                          → Yangi ishchi yaratish [Admin]
#   GET    /api/v1/workers/                          → Ro'yxat (filter bilan)
#   GET    /api/v1/workers/summary                   → Moliyaviy xulosa [Admin]
#   GET    /api/v1/workers/{worker_id}               → Bitta ishchi
#   PATCH  /api/v1/workers/{worker_id}               → Ma'lumot yangilash [Admin]
#   DELETE /api/v1/workers/{worker_id}               → Bloklash [Admin]
#   POST   /api/v1/workers/{worker_id}/activate      → Qayta faollashtirish [Admin]
#   GET    /api/v1/workers/{worker_id}/balance       → Balans tarixi
#   POST   /api/v1/workers/{worker_id}/salary        → Ish haqi to'lash [Admin]
#   POST   /api/v1/workers/{worker_id}/balance/adjust → Balans tuzatish [Admin]
#   GET    /api/v1/workers/me/balance                → O'z balansi (Usta uchun)
# ================================================

from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status

from app.database.models import UserRole
from app.schemas.worker import (
    WorkerCreateRequest,
    WorkerUpdateRequest,
    SalaryPaymentRequest,
    BalanceAdjustRequest,
    WorkerResponse,
    WorkerListResponse,
    WorkerBalanceHistoryResponse,
    SalaryPaymentResponse,
)
from app.services.worker_service import (
    create_worker,
    get_worker_by_id,
    get_workers_list,
    update_worker,
    pay_salary,
    adjust_balance,
    get_worker_balance_history,
    get_workers_finance_summary,
)
from app.utils.dependencies import (
    CurrentUser,
    AdminUser,
    OperatorOrAdminUser,
    DBSession,
)
from app.utils.logger import logger


# ================================================================
#  ROUTER
# ================================================================

router = APIRouter(
    prefix="/workers",
    tags=["👷 Workers — Ishchilar va Balanslar"],
    responses={
        401: {"description": "Avtorizatsiya talab qilinadi"},
        403: {"description": "Bu amal uchun ruxsat yo'q"},
        404: {"description": "Ishchi topilmadi"},
    },
)


# ================================================================
#  YORDAMCHI: Ishchini topish yoki 404
# ================================================================

async def _get_worker_or_404(worker_id: int, db: DBSession) -> WorkerResponse:
    worker = await get_worker_by_id(db, worker_id)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ishchi topilmadi: id={worker_id}",
        )
    return worker


# ================================================================
#  1. YANGI ISHCHI YARATISH  [Admin only]
# ================================================================

@router.post(
    "/",
    response_model=WorkerResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Yangi ishchi yaratish [Admin]",
    description="""
    Yangi usta yoki operator yaratadi. **Faqat Admin** bajarishi mumkin.

    **Muhim qoidalar:**
    - `username` noyob bo'lishi shart (band bo'lsa `409` xato)
    - `role` faqat `master` yoki `operator` bo'lishi mumkin
    - `commission_percent` — har zakaz topshirilganda avtomatik
      hisoblanadigankulushfoizi (0–100%)
    - `salary_rate` — oylik stavka (ixtiyoriy, komisyon bilan birga ishlatilishi mumkin)

    **Boshlang'ich balans:** 0 so'm (komisyon hisoblanganda oshib boradi).
    """,
)
async def create_new_worker(
    data: WorkerCreateRequest,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await create_worker(db, data, admin)
    if error:
        status_code = (
            status.HTTP_409_CONFLICT
            if "band" in error
            else status.HTTP_422_UNPROCESSABLE_ENTITY
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result


# ================================================================
#  2. ISHCHILAR RO'YXATI
# ================================================================

@router.get(
    "/",
    response_model=WorkerListResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchilar ro'yxati",
    description="""
    Barcha ishchilar ro'yxati.

    **Ruxsatlar:**
    - **Admin** — hammani ko'radi (faol + bloklangan)
    - **Operator** — faqat faol ustalarni ko'radi

    **Filtrlar:**
    - `role` — `master` yoki `operator`
    - `is_active` — `true` (faol) yoki `false` (bloklangan)
    """,
)
async def list_workers(
    current_user: CurrentUser,
    db: DBSession,
    role: Optional[UserRole] = Query(
        default=None,
        description="Rol bo'yicha filter: master yoki operator"
    ),
    is_active: Optional[bool] = Query(
        default=None,
        description="Holat: true=faol, false=bloklangan"
    ),
    page:      int = Query(default=1,  ge=1),
    page_size: int = Query(default=50, ge=1, le=100),
) -> WorkerListResponse:
    # Operator faqat ustalarni ko'ra oladi
    effective_role = role
    if current_user.role == UserRole.OPERATOR:
        effective_role = UserRole.MASTER
        is_active = True   # Operator bloklangan ustalarni ko'rmaydi

    return await get_workers_list(
        db=db,
        role=effective_role,
        is_active=is_active,
        page=page,
        page_size=page_size,
    )


# ================================================================
#  3. MOLIYAVIY XULOSA  [Admin only]
# ================================================================

@router.get(
    "/summary",
    status_code=status.HTTP_200_OK,
    summary="Ishchilar moliyaviy xulosasi [Admin]",
    description="""
    Barcha ishchilar bo'yicha moliyaviy umumiy hisobot.

    **Qaytaradi:**
    - Jami faol ishchilar soni
    - Barcha balanslarda turib-turgan umumiy summa
    - Jami hisoblangan komisyonlar
    - Jami to'lab berilgan ish haqlar
    - Hali to'lanmagan qoldiq
    - Har bir ishchining qisqacha holati
    """,
)
async def workers_finance_summary(
    admin: AdminUser,
    db: DBSession,
) -> dict:
    return await get_workers_finance_summary(db)


# ================================================================
#  4. O'Z BALANSI — USTA UCHUN  (/{worker_id} dan OLDIN bo'lishi shart)
# ================================================================

@router.get(
    "/me/balance",
    response_model=WorkerBalanceHistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Mening balansim va tarixim",
    description="""
    Tizimga kirgan usta o'z balansini va barcha moliyaviy
    tarixini ko'radi.

    **Ko'rsatiladi:**
    - Joriy balans
    - Har bir zakazdan hisoblangan komisyonlar
    - To'lab berilgan ish haq tarixi
    - Jami ishlab topilgan va jami to'langan summalar
    """,
)
async def my_balance(
    current_user: CurrentUser,
    db: DBSession,
) -> WorkerBalanceHistoryResponse:
    history = await get_worker_balance_history(db, current_user.id)
    if not history:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ma'lumot topilmadi",
        )
    return history


# ================================================================
#  5. BITTA ISHCHI MA'LUMOTI
# ================================================================

@router.get(
    "/{worker_id}",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Bitta ishchi ma'lumoti",
    description="""
    ID bo'yicha ishchining to'liq ma'lumoti va statistikasi.

    **Statistika:**
    - Jami bitirgan zakazlari soni
    - Jami ishlab topgani (komisyon yig'indisi)
    - Jami to'lab berilgani
    - Joriy balans (hali to'lanmagan qoldiq)
    """,
)
async def get_worker(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> WorkerResponse:
    return await _get_worker_or_404(worker_id, db)


# ================================================================
#  6. ISHCHI MA'LUMOTLARINI YANGILASH  [Admin only]
# ================================================================

@router.patch(
    "/{worker_id}",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchi ma'lumotlarini yangilash [Admin]",
    description="""
    Ishchi ma'lumotlarini yangilaydi. **Faqat yuborilgan maydonlar o'zgaradi.**

    **Yangilanishi mumkin:**
    - `full_name` — ismi-familiyasi
    - `phone` — telefon raqami
    - `commission_percent` — komisyon foizi (o'zgarish log ga yoziladi)
    - `salary_rate` — oylik stavka
    - `is_active` — `false` qilib bloklash mumkin

    **E'tibor:** komisyon foizi o'zgarsa, **yangi foiz faqat keyingi
    zakazlarga** qo'llaniladi. Allaqachon hisoblangan komisyonlar o'zgarmaydi.
    """,
)
async def update_worker_info(
    worker_id: int,
    data: WorkerUpdateRequest,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await update_worker(db, worker_id, data, admin)
    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result


# ================================================================
#  7. ISHCHINI BLOKLASH  [Admin only]
# ================================================================

@router.delete(
    "/{worker_id}",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchini bloklash [Admin]",
    description="""
    Ishchini tizimdan **o'chirmaydi** — faqat `is_active = false` qiladi.

    Bloklangan ishchi:
    - Tizimga kira olmaydi
    - Yangi zakazlarga tayinlanmaydi
    - Ma'lumotlari va tarixi saqlanib qoladi

    Qayta faollashtirish uchun: `POST /{worker_id}/activate`
    """,
)
async def deactivate_worker(
    worker_id: int,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    # O'zini bloklay olmasligi kerak
    if worker_id == admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O'zingizni bloklay olmaysiz",
        )

    result, error = await update_worker(
        db, worker_id,
        WorkerUpdateRequest(is_active=False),
        admin,
    )
    if error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST,
            detail=error,
        )

    logger.info(f"🔒 Ishchi bloklandi: id={worker_id} | Admin: {admin.username}")
    return result


# ================================================================
#  8. ISHCHINI QAYTA FAOLLASHTIRISH  [Admin only]
# ================================================================

@router.post(
    "/{worker_id}/activate",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchini qayta faollashtirish [Admin]",
    description="Bloklangan ishchini yana faol holatga qaytaradi.",
)
async def activate_worker(
    worker_id: int,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await update_worker(
        db, worker_id,
        WorkerUpdateRequest(is_active=True),
        admin,
    )
    if error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST,
            detail=error,
        )

    logger.info(f"🔓 Ishchi faollashtirildi: id={worker_id} | Admin: {admin.username}")
    return result


# ================================================================
#  9. ISHCHI BALANS TARIXI
# ================================================================

@router.get(
    "/{worker_id}/balance",
    response_model=WorkerBalanceHistoryResponse,
    status_code=status.HTTP_200_OK,
    summary="Ishchi balans tarixi",
    description="""
    Ishchining to'liq moliyaviy tarixi:

    **Kirimlar (komisyonlar):**
    - Har bir zakaz bo'yicha hisoblangan komisyon
    - Zakaz raqami, mijoz, TV ma'lumotlari, summa, foiz

    **Chiqimlar (ish haqlar):**
    - To'lab berilgan barcha to'lovlar
    - Kim to'ladi, qachon, qanday usulda

    **Joriy holat:**
    - Hozirgi balans = jami komisyon − jami to'lovlar
    """,
)
async def worker_balance_history(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> WorkerBalanceHistoryResponse:
    history = await get_worker_balance_history(db, worker_id)
    if not history:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ishchi topilmadi: id={worker_id}",
        )
    return history


# ================================================================
#  10. ISH HAQI TO'LASH  [Admin only]
# ================================================================

@router.post(
    "/{worker_id}/salary",
    response_model=SalaryPaymentResponse,
    status_code=status.HTTP_200_OK,
    summary="Ish haqi to'lash [Admin]",
    description="""
    Ishchiga ish haqi to'laydi.

    **Avtomatik bajariladi:**
    1. Ishchi balansidan to'lov summasi **ayiriladi**
    2. `SalaryPayment` jadvaliga to'lov tarixi **yoziladi**
    3. `FinanceTransaction` jadvaliga kassa **chiqimi yoziladi**

    **Shartlar:**
    - Ishchi faol bo'lishi shart
    - To'lov summasi joriy balansdan oshmasligi kerak
      (balans manfiyga tushmaydi)
    """,
)
async def pay_worker_salary(
    worker_id: int,
    data: SalaryPaymentRequest,
    admin: AdminUser,
    db: DBSession,
) -> SalaryPaymentResponse:
    result, error = await pay_salary(db, worker_id, data, admin)
    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND  if "topilmadi" in error else
            status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result


# ================================================================
#  11. BALANSNI QO'LDA TO'G'IRLASH  [Admin only]
# ================================================================

@router.post(
    "/{worker_id}/balance/adjust",
    response_model=WorkerResponse,
    status_code=status.HTTP_200_OK,
    summary="Balansni qo'lda to'g'irlash [Admin]",
    description="""
    Admin ishchi balansini qo'lda o'zgartiradi.

    **Ishlatilish holatlari:**
    - Bonus qo'shish (musbat `amount`)
    - Noto'g'ri hisoblangan komisyonni tuzatish (manfiy `amount`)
    - Avans berish

    **`reason` maydoni MAJBURIY** — audit izi uchun barcha
    o'zgarishlar `FinanceTransaction` jadvaliga yoziladi.

    **Cheklov:** Balans manfiyga tushishi mumkin emas.
    """,
)
async def adjust_worker_balance(
    worker_id: int,
    data: BalanceAdjustRequest,
    admin: AdminUser,
    db: DBSession,
) -> WorkerResponse:
    result, error = await adjust_balance(db, worker_id, data, admin)
    if error:
        status_code = (
            status.HTTP_404_NOT_FOUND  if "topilmadi" in error else
            status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=status_code, detail=error)
    return result
TVCRM_EOF

  cat > 'tv-crm/backend/app/api/locations.py' << 'TVCRM_EOF'
# ================================================
# api/locations.py — Geolokatsiya API Router
#
# Endpoint'lar ro'yxati:
#
#  [Mobil ilova → Server]
#   POST /api/v1/locations/ping              → Koordinata jo'natish (fon rejimi)
#   POST /api/v1/locations/visit/start       → Vizit boshlash
#   POST /api/v1/locations/visit/end         → Vizit yakunlash
#
#  [Admin/Operator → Server]
#   GET  /api/v1/locations/active            → Barcha faol ustalar xaritasi
#   GET  /api/v1/locations/workers/{id}/current  → Bitta ustaning oxirgi joylashuvi
#   GET  /api/v1/locations/workers/{id}/trek     → Ustaning vizit trekı
#   GET  /api/v1/locations/workers/{id}/history  → Koordinata tarixi (sahifalash)
# ================================================

from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status, Request

from app.schemas.location import (
    LocationPingRequest,
    VisitStartRequest,
    VisitEndRequest,
    LocationPingResponse,
    WorkerCurrentLocationResponse,
    WorkerTrekResponse,
    ActiveWorkerMapResponse,
    VisitStartResponse,
    VisitEndResponse,
    LocationPointResponse,
)
from app.services.location_service import (
    save_location_ping,
    start_visit,
    end_visit,
    get_worker_current_location,
    get_all_active_workers_locations,
    get_worker_trek,
    TREK_DEFAULT_HOURS,
)
from app.utils.dependencies import (
    CurrentUser,
    AdminUser,
    OperatorOrAdminUser,
    AnyAuthenticatedUser,
    DBSession,
)
from app.database.models import UserRole
from app.utils.logger import logger


# ================================================================
#  ROUTER
# ================================================================

router = APIRouter(
    prefix="/locations",
    tags=["📍 Locations — Geolokatsiya va Vizitlar"],
    responses={
        401: {"description": "Avtorizatsiya talab qilinadi"},
        403: {"description": "Bu amal uchun ruxsat yo'q"},
    },
)


# ================================================================
#  MOBIL ILOVA ENDPOINT'LARI
#  (Usta telefoni fon rejimda shu portlarga jo'natadi)
# ================================================================

@router.post(
    "/ping",
    response_model=LocationPingResponse,
    status_code=status.HTTP_200_OK,
    summary="Koordinata jo'natish [Mobil ilova]",
    description="""
    Mobil ilova **fon rejimida** har N sekundda shu endpoint'ga
    koordinata jo'natib turadi.

    **Ishlash tartibi:**
    1. Usta tizimga kiradi → JWT token oladi
    2. Vizit boshlanadi (`POST /visit/start`)
    3. Ilova fonda **15 soniyada bir** shu portga ping jo'natadi
    4. Server `next_ping_seconds` qaytaradi → ilova shuga moslashadi
    5. Vizit yakunlanadi (`POST /visit/end`)

    **Adaptiv interval:**
    | Batareya | Interval |
    |----------|----------|
    | ≥ 30%    | 15 sek   |
    | 10–29%   | 30 sek   |
    | < 10%    | 60 sek   |

    **Koordinata validatsiyasi:**
    O'zbekiston hududi tekshiriladi (lat: 36–46°, lon: 55–74°).
    Tashqarida bo'lsa `422` xato qaytariladi.

    **Eslatma:** `order_id` ixtiyoriy — berilmasa server
    ustaning joriy `on_the_way` zakazini avtomatik topadi.
    """,
)
async def location_ping(
    data: LocationPingRequest,
    current_user: AnyAuthenticatedUser,
    request: Request,
    db: DBSession,
) -> LocationPingResponse:
    """
    Mobil ilovadan koordinata qabul qilish.
    Barcha autentifikatsiya qilingan foydalanuvchilar uchun.
    """
    # Faqat Usta yoki Admin jo'natishi mumkin
    if current_user.role == UserRole.OPERATOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operator koordinata jo'natishi mumkin emas",
        )

    result, error = await save_location_ping(db, current_user, data)
    if error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error,
        )
    return result


@router.post(
    "/visit/start",
    response_model=VisitStartResponse,
    status_code=status.HTTP_200_OK,
    summary="Vizit boshlash [Mobil ilova]",
    description="""
    Usta mijoznikiga vizitga otishdan oldin bu endpoint'ni chaqiradi.

    **Avtomatik bajariladi:**
    - Zakaz statusi → `on_the_way`
    - `OrderStatusHistory` ga yozuv qo'shiladi
    - Birinchi koordinata saqlanadi
    - Geolokatsiya fon rejimi yoqiladi

    **Ruxsat etilgan holatllar (qaysi statusdan o'tish mumkin):**
    `accepted` → `diagnosing` → `waiting` → `on_the_way`

    **Mobil UX tavsiyasi:**
    Usta "Yo'lga chiqdim" tugmasini bosadi →
    ilova shu endpoint'ni chaqiradi →
    fon lokatsiya xizmati avtomatik yoqiladi.
    """,
)
async def begin_visit(
    data: VisitStartRequest,
    current_user: AnyAuthenticatedUser,
    db: DBSession,
) -> VisitStartResponse:
    if current_user.role == UserRole.OPERATOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operator vizit boshlay olmaydi",
        )

    result, error = await start_visit(db, current_user, data)
    if error:
        code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=code, detail=error)
    return result


@router.post(
    "/visit/end",
    response_model=VisitEndResponse,
    status_code=status.HTTP_200_OK,
    summary="Vizit yakunlash [Mobil ilova]",
    description="""
    Usta mijoz uyiga yetib, ta'mirni boshlashdan oldin shu endpoint'ni chaqiradi.

    **Avtomatik bajariladi:**
    - Zakaz statusi: `on_the_way` → `in_repair`
    - `OrderStatusHistory` ga yozuv qo'shiladi
    - Oxirgi koordinata saqlanadi
    - Vizit trekining umumiy nuqtalar soni qaytariladi

    **Mobil UX tavsiyasi:**
    Usta "Yetib keldim" tugmasini bosadi →
    ilova shu endpoint'ni chaqiradi →
    fon lokatsiya xizmati to'xtatilishi mumkin.
    """,
)
async def finish_visit(
    data: VisitEndRequest,
    current_user: AnyAuthenticatedUser,
    db: DBSession,
) -> VisitEndResponse:
    if current_user.role == UserRole.OPERATOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operator vizit yakunlay olmaydi",
        )

    result, error = await end_visit(db, current_user, data)
    if error:
        code = (
            status.HTTP_404_NOT_FOUND
            if "topilmadi" in error
            else status.HTTP_400_BAD_REQUEST
        )
        raise HTTPException(status_code=code, detail=error)
    return result


# ================================================================
#  ADMIN / OPERATOR NAZORAT ENDPOINT'LARI
#  (Web panel xaritasi uchun)
# ================================================================

@router.get(
    "/active",
    response_model=ActiveWorkerMapResponse,
    status_code=status.HTTP_200_OK,
    summary="Barcha faol ustalar xaritasi [Admin/Operator]",
    description="""
    Hozirda **`on_the_way`** holatidagi barcha ustalarning
    oxirgi joylashuvini qaytaradi.

    **Frontend xarita uchun:**
    - Sahifa yuklanganda bir marta chaqiriladi
    - Keyin **15 soniyada bir** polling bilan yangilanadi
    - Har bir usta uchun xaritada marker ko'rsatiladi

    **`is_stale` maydoni:**
    Agar ustadan 5 daqiqadan ko'p vaqt o'tgan bo'lsa `true` —
    frontend markerini kulrang/sovuq rang bilan ko'rsatishi mumkin.

    **`seconds_since_update`** — oxirgi pingdan qancha soniya o'tgani.
    """,
)
async def active_workers_map(
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> ActiveWorkerMapResponse:
    return await get_all_active_workers_locations(db)


@router.get(
    "/workers/{worker_id}/current",
    response_model=WorkerCurrentLocationResponse,
    status_code=status.HTTP_200_OK,
    summary="Bitta ustaning oxirgi joylashuvi",
    description="""
    ID bo'yicha bitta ustaning **eng oxirgi** saqlangan
    koordinatasini qaytaradi.

    **Qaytaradi:**
    - Koordinata (lat, lon) + GPS aniqligi
    - Qaysi zakaz uchun ekanligi
    - Mijoz nomi va manzili
    - Batareya darajasi
    - Oxirgi yangilanish vaqti va `is_stale` holati

    Agar ushbu ustadan hech qachon koordinata kelmagan bo'lsa
    `404` qaytariladi.
    """,
)
async def worker_current_location(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
) -> WorkerCurrentLocationResponse:
    result = await get_worker_current_location(db, worker_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Usta id={worker_id} uchun hech qanday joylashuv ma'lumoti "
                f"topilmadi. Usta hali koordinata jo'natmagan bo'lishi mumkin."
            ),
        )
    return result


@router.get(
    "/workers/{worker_id}/trek",
    response_model=WorkerTrekResponse,
    status_code=status.HTTP_200_OK,
    summary="Ustaning vizit trekı (marshrutı)",
    description="""
    Ustaning bitta vizit uchun **to'liq harakatlanish yo'lini**
    (trek) qaytaradi. Xaritada chiziq sifatida ko'rsatiladi.

    **Parametrlar:**
    - `order_id` — qaysi zakaz viziti (ixtiyoriy, berilmasa oxirgi vizit)
    - `hours`    — necha soat orqasiga qaralsin (1–168, default: 24)

    **Trek statistikasi:**
    - Boshlash va tugash vaqti
    - Davomiylik (daqiqalarda)
    - Taxminiy bosib o'tilgan masofa (km, Haversine formulasi)
    - Nuqtalar soni

    **Frontend tavsiyasi:**
    Nuqtalarni `polyline` sifatida chizing, tezlikka qarab
    rangini o'zgartiring (qizil = tez, yashil = sekin).
    """,
)
async def worker_trek(
    worker_id: int,
    current_user: OperatorOrAdminUser,
    db: DBSession,
    order_id: Optional[int] = Query(
        default=None,
        description="Zakaz ID si (berilmasa — oxirgi vizit)",
    ),
    hours: int = Query(
        default=TREK_DEFAULT_HOURS,
        ge=1,
        le=168,
        description="Necha soat orqasiga (1–168, default: 24)",
    ),
) -> WorkerTrekResponse:
    result = await get_worker_trek(
        db=db,
        worker_id=worker_id,
        order_id=order_id,
        hours=hours,
    )
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Usta id={worker_id} topilmadi",
        )
    return result


@router.get(
    "/workers/{worker_id}/history",
    response_model=list[LocationPointResponse],
    status_code=status.HTTP_200_OK,
    summary="Koordinata tarixi (sahifalash bilan)",
    description="""
    Ustaning koordinata yozuvlarini sahifalash bilan qaytaradi.
    Debug va audit maqsadida ishlatiladi.

    **Filtrlar:**
    - `order_id` — faqat shu zakaz uchun yozuvlar
    - `limit`    — nechta yozuv (max: 500)
    - `offset`   — qayerdan boshlansin

    Yozuvlar **yangilikdan eskiga** (desc) tartiblangan qaytariladi.
    """,
)
async def worker_location_history(
    worker_id: int,
    current_user: AdminUser,
    db: DBSession,
    order_id: Optional[int] = Query(default=None),
    limit:    int = Query(default=100, ge=1, le=500),
    offset:   int = Query(default=0,   ge=0),
) -> list[LocationPointResponse]:
    from sqlalchemy import select, and_
    from app.database.models import WorkerLocation

    filters = [WorkerLocation.worker_id == worker_id]
    if order_id:
        filters.append(WorkerLocation.order_id == order_id)

    result = await db.execute(
        select(WorkerLocation)
        .where(and_(*filters))
        .order_by(WorkerLocation.recorded_at.desc())
        .offset(offset)
        .limit(limit)
    )
    locations = result.scalars().all()

    return [
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/schemas/__init__.py' << 'TVCRM_EOF'
# Pydantic schemas package
TVCRM_EOF

  cat > 'tv-crm/backend/app/schemas/auth.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/schemas/order.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/schemas/worker.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/schemas/location.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/services/__init__.py' << 'TVCRM_EOF'
# Business logic services package
TVCRM_EOF

  cat > 'tv-crm/backend/app/services/auth_service.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/services/order_service.py' << 'TVCRM_EOF'
# ================================================
# services/order_service.py — Zakazlar biznes logikasi
#
# Tarkib:
#   1. Zakaz yaratish (mijoz ham avtomatik yaratiladi)
#   2. Zakaz o'qish (bitta / ro'yxat / filter)
#   3. Zakaz ma'lumotlarini yangilash
#   4. Status o'zgartirish + tarix yozish (MAJBURIY)
#   5. To'lov qabul qilish
#   6. Deadline alert — muddati o'tgan/yaqinlashgan zakazlar
#   7. Statistika (dashboard uchun)
# ================================================

from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func, and_, or_
from sqlalchemy.orm import selectinload

from app.database.models import (
    Order, OrderStatus, OrderSource, PaymentMethod,
    OrderStatusHistory, Client, User, ShopSettings,
    FinanceTransaction, TransactionType,
)
from app.schemas.order import (
    OrderCreateRequest,
    OrderUpdateRequest,
    OrderStatusUpdateRequest,
    OrderPaymentRequest,
    OrderResponse,
    OrderListResponse,
    OrderDeadlineAlertResponse,
    OrderStatsResponse,
    ClientShortResponse,
    WorkerShortResponse,
    StatusHistoryResponse,
)
from app.utils.helpers import (
    generate_order_number,
    get_deadline_info,
    is_overdue,
    hours_until_deadline,
    utc_now,
    make_aware,
)
from app.utils.logger import logger


# ================================================================
#  YORDAMCHI: Order → OrderResponse (deadline ma'lumoti bilan)
# ================================================================

def _build_order_response(order: Order) -> OrderResponse:
    """
    SQLAlchemy Order ob'ektini OrderResponse Pydantic modeliga
    o'tkazadi va deadline hisob-kitoblarini qo'shadi.
    """
    deadline_aware = make_aware(order.deadline)
    d_info = get_deadline_info(deadline_aware)

    # Status tarixini yig'amiz
    history = [
        StatusHistoryResponse(
            id=h.id,
            old_status=h.old_status,
            new_status=h.new_status,
            comment=h.comment,
            changed_by=(
                WorkerShortResponse(
                    id=h.changed_by.id,
                    full_name=h.changed_by.full_name,
                    role=h.changed_by.role.value,
                )
                if h.changed_by else None
            ),
            created_at=h.created_at,
        )
        for h in (order.status_history or [])
    ]

    return OrderResponse(
        id=order.id,
        order_number=order.order_number,
        client=ClientShortResponse(
            id=order.client.id,
            full_name=order.client.full_name,
            phone=order.client.phone,
        ),
        operator=(
            WorkerShortResponse(
                id=order.operator.id,
                full_name=order.operator.full_name,
                role=order.operator.role.value,
            ) if order.operator else None
        ),
        master=(
            WorkerShortResponse(
                id=order.master.id,
                full_name=order.master.full_name,
                role=order.master.role.value,
            ) if order.master else None
        ),
        tv_brand=order.tv_brand,
        tv_model=order.tv_model,
        tv_diagonal=order.tv_diagonal,
        tv_serial_number=order.tv_serial_number,
        problem_description=order.problem_description,
        ai_diagnosis=order.ai_diagnosis,
        master_diagnosis=order.master_diagnosis,
        work_done=order.work_done,
        status=order.status,
        source=order.source,
        estimated_price=order.estimated_price,
        final_price=order.final_price,
        parts_cost=order.parts_cost,
        is_paid=order.is_paid,
        payment_method=order.payment_method,
        master_commission=order.master_commission,
        deadline=deadline_aware,
        created_at=order.created_at,
        updated_at=order.updated_at,
        accepted_at=order.accepted_at,
        completed_at=order.completed_at,
        delivered_at=order.delivered_at,
        is_archived=order.is_archived,
        cancel_reason=order.cancel_reason,
        is_overdue=d_info["is_overdue"],
        hours_until_deadline=d_info["hours_remaining"],
        status_history=history,
    )


# ================================================================
#  YORDAMCHI: Order ni eager load bilan yuklash
# ================================================================

def _order_query_with_relations():
    """
    Order'ni barcha bog'liq jadvallar bilan birga yuklash.
    N+1 muammosini oldini oladi.
    """
    return (
        select(Order)
        .options(
            selectinload(Order.client),
            selectinload(Order.operator),
            selectinload(Order.master),
            selectinload(Order.status_history).selectinload(
                OrderStatusHistory.changed_by
            ),
        )
    )


# ================================================================
#  1. ZAKAZ YARATISH
# ================================================================

async def create_order(
    db: AsyncSession,
    data: OrderCreateRequest,
    created_by: User,
) -> OrderResponse:
    """
    Yangi zakaz yaratadi.

    Mantiq:
      1. Mijozni topadi yoki yangi yaratadi
      2. ShopSettings.order_counter ni oshiradi
      3. Zakaz raqamini generatsiya qiladi (TV-2025-XXXX)
      4. Order saqlaydi
      5. Birinchi status_history yozuvini qo'shadi (new → new)
    """

    # ── 1. Mijoz ──────────────────────────────────────────────
    if data.client_id:
        client_result = await db.execute(
            select(Client).where(Client.id == data.client_id)
        )
        client = client_result.scalar_one_or_none()
        if not client:
            raise ValueError(f"Mijoz topilmadi: id={data.client_id}")
    else:
        # Telefon bo'yicha mavjud mijozni tekshirish
        if data.client_phone:
            existing = await db.execute(
                select(Client).where(Client.phone == data.client_phone)
            )
            client = existing.scalar_one_or_none()
        else:
            client = None

        if not client:
            # Yangi mijoz yaratish
            client = Client(
                full_name=data.client_name,
                phone=data.client_phone,
            )
            db.add(client)
            await db.flush()   # ID olish uchun
            logger.info(f"👤 Yangi mijoz yaratildi: {client.full_name} ({client.phone})")

    # ── 2. Zakaz raqami ───────────────────────────────────────
    settings_result = await db.execute(select(ShopSettings))
    shop = settings_result.scalar_one_or_none()

    if not shop:
        # Sozlamalar yo'q bo'lsa — yaratamiz
        shop = ShopSettings()
        db.add(shop)
        await db.flush()

    shop.order_counter += 1
    order_number = generate_order_number(
        counter=shop.order_counter,
        year=utc_now().year,
    )

    # ── 3. Zakaz yaratish ─────────────────────────────────────
    deadline = make_aware(data.deadline)

    order = Order(
        order_number=order_number,
        client_id=client.id,
        operator_id=data.operator_id or created_by.id,
        master_id=data.master_id,
        tv_brand=data.tv_brand,
        tv_model=data.tv_model,
        tv_diagonal=data.tv_diagonal,
        tv_serial_number=data.tv_serial_number,
        problem_description=data.problem_description,
        source=data.source,
        estimated_price=data.estimated_price,
        final_price=0.0,
        parts_cost=0.0,
        status=OrderStatus.NEW,
        deadline=deadline,
        is_paid=False,
        is_archived=False,
    )
    db.add(order)
    await db.flush()   # order.id olish uchun

    # ── 4. Birinchi status tarixi ─────────────────────────────
    history = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=created_by.id,
        old_status=None,
        new_status=OrderStatus.NEW,
        comment="Zakaz ochildi",
    )
    db.add(history)

    # ── 5. Mijoz statistikasini yangilash ─────────────────────
    client.total_orders += 1

    await db.commit()

    # Refresh with relations
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order.id)
    )
    fresh_order = result.scalar_one()

    logger.info(
        f"✅ Zakaz yaratildi: {order_number} | "
        f"Mijoz: {client.full_name} | "
        f"Deadline: {deadline.strftime('%d.%m.%Y %H:%M')} | "
        f"Operator: {created_by.username}"
    )

    return _build_order_response(fresh_order)


# ================================================================
#  2. ZAKAZ O'QISH — BITTA
# ================================================================

async def get_order_by_id(
    db: AsyncSession,
    order_id: int,
) -> Optional[OrderResponse]:
    """ID bo'yicha bitta zakazni qaytaradi"""
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None
    return _build_order_response(order)


async def get_order_by_number(
    db: AsyncSession,
    order_number: str,
) -> Optional[OrderResponse]:
    """Zakaz raqami bo'yicha topadi (masalan: TV-2025-0001)"""
    result = await db.execute(
        _order_query_with_relations().where(
            Order.order_number == order_number.upper()
        )
    )
    order = result.scalar_one_or_none()
    if not order:
        return None
    return _build_order_response(order)


# ================================================================
#  3. ZAKAZLAR RO'YXATI (filter + pagination)
# ================================================================

async def get_orders_list(
    db: AsyncSession,
    page: int = 1,
    page_size: int = 20,
    status: Optional[OrderStatus] = None,
    master_id: Optional[int] = None,
    client_id: Optional[int] = None,
    search: Optional[str] = None,
    is_archived: bool = False,
    only_overdue: bool = False,
) -> OrderListResponse:
    """
    Zakazlar ro'yxati — filtrlash va sahifalash bilan.

    Filtrlar:
      status      — holat bo'yicha
      master_id   — usta bo'yicha
      client_id   — mijoz bo'yicha
      search      — zakaz raqami yoki mijoz nomi bo'yicha
      is_archived — arxivlangan zakazlar
      only_overdue — faqat muddati o'tganlar
    """
    # Asosiy so'rov
    base_q = (
        _order_query_with_relations()
        .where(Order.is_archived == is_archived)
    )

    # Filtrlar
    if status:
        base_q = base_q.where(Order.status == status)

    if master_id:
        base_q = base_q.where(Order.master_id == master_id)

    if client_id:
        base_q = base_q.where(Order.client_id == client_id)

    if search:
        base_q = base_q.join(Client).where(
            or_(
                Order.order_number.ilike(f"%{search}%"),
                Client.full_name.ilike(f"%{search}%"),
                Client.phone.ilike(f"%{search}%"),
            )
        )

    if only_overdue:
        now = utc_now()
        # Aktiv (arxivlanmagan) va muddati o'tgan
        base_q = base_q.where(
            and_(
                Order.deadline < now,
                Order.status.notin_([
                    OrderStatus.DELIVERED,
                    OrderStatus.CANCELLED,
                ]),
            )
        )

    # Jami soni (pagination uchun)
    count_q = select(func.count()).select_from(
        base_q.subquery()
    )
    total_result = await db.execute(count_q)
    total = total_result.scalar_one()

    # Sahifalash
    offset = (page - 1) * page_size
    paginated_q = (
        base_q
        .order_by(Order.created_at.desc())
        .offset(offset)
        .limit(page_size)
    )
    result = await db.execute(paginated_q)
    orders = result.scalars().all()

    # Muddati o'tgan zakazlar soni (umumiy)
    now = utc_now()
    overdue_count_q = select(func.count(Order.id)).where(
        and_(
            Order.is_archived == False,
            Order.deadline < now,
            Order.status.notin_([
                OrderStatus.DELIVERED,
                OrderStatus.CANCELLED,
            ]),
        )
    )
    overdue_result = await db.execute(overdue_count_q)
    overdue_count = overdue_result.scalar_one()

    import math
    return OrderListResponse(
        items=[_build_order_response(o) for o in orders],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=max(1, math.ceil(total / page_size)),
        overdue_count=overdue_count,
    )


# ================================================================
#  4. ZAKAZ MA'LUMOTLARINI YANGILASH
# ================================================================

async def update_order(
    db: AsyncSession,
    order_id: int,
    data: OrderUpdateRequest,
    updated_by: User,
) -> Optional[OrderResponse]:
    """
    Zakaz maydonlarini yangilaydi (PATCH — faqat yuborilgan maydonlar).
    Status o'zgarmaydi — buning uchun update_order_status ishlatiladi.
    """
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None

    # Faqat yuborilgan maydonlarni yangilaymiz
    update_data = data.model_dump(exclude_unset=True)

    # Deadline kelgan bo'lsa, timezone-aware qilamiz
    if "deadline" in update_data and update_data["deadline"]:
        update_data["deadline"] = make_aware(update_data["deadline"])

    for field, value in update_data.items():
        setattr(order, field, value)

    await db.commit()
    await db.refresh(order)

    # Qayta yuklash (relation'lar uchun)
    fresh_result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    fresh_order = fresh_result.scalar_one()

    logger.info(
        f"✏️  Zakaz yangilandi: {order.order_number} | "
        f"Kim: {updated_by.username} | "
        f"Maydonlar: {list(update_data.keys())}"
    )
    return _build_order_response(fresh_order)


# ================================================================
#  5. STATUS O'ZGARTIRISH + TARIX YOZISH (MAJBURIY)
# ================================================================

# Ruxsat etilgan status o'tishlar jadvali
# Kalit: joriy holat → Qiymat: o'tish mumkin bo'lgan holatlari
#
# on_the_way holati location_service orqali avtomatik boshqariladi:
#   POST /locations/visit/start → on_the_way
#   POST /locations/visit/end   → in_repair
# Lekin order_service orqali ham qo'lda o'zgartirish ruxsat etiladi
# (masalan: usta vizitdan bekor qilsa).
ALLOWED_TRANSITIONS: dict[OrderStatus, list[OrderStatus]] = {
    OrderStatus.NEW: [
        OrderStatus.ACCEPTED,
        OrderStatus.CANCELLED,
    ],
    OrderStatus.ACCEPTED: [
        OrderStatus.DIAGNOSING,
        OrderStatus.ON_THE_WAY,   # ← Bevosita vizitga chiqish (qo'lda)
        OrderStatus.CANCELLED,
    ],
    OrderStatus.DIAGNOSING: [
        OrderStatus.WAITING,
        OrderStatus.IN_REPAIR,
        OrderStatus.ON_THE_WAY,   # ← Diagnostika keyin vizitga
        OrderStatus.CANCELLED,
    ],
    OrderStatus.WAITING: [
        OrderStatus.IN_REPAIR,
        OrderStatus.ON_THE_WAY,   # ← Zapchast olib ketish uchun vizit
        OrderStatus.CANCELLED,
    ],
    OrderStatus.ON_THE_WAY: [
        OrderStatus.IN_REPAIR,    # ← Yetib keldi (odatda visit/end orqali)
        OrderStatus.ACCEPTED,     # ← Vizit bekor qilindi, qaytdi
        OrderStatus.DIAGNOSING,   # ← Qaytib diagnostikaga
        OrderStatus.CANCELLED,
    ],
    OrderStatus.IN_REPAIR: [
        OrderStatus.DONE,
        OrderStatus.WAITING,
        OrderStatus.ON_THE_WAY,   # ← Qo'shimcha detal uchun qayta vizit
        OrderStatus.CANCELLED,
    ],
    OrderStatus.DONE: [
        OrderStatus.DELIVERED,
        OrderStatus.CANCELLED,
    ],
    OrderStatus.DELIVERED: [],    # Yakuniy holat — o'zgartirib bo'lmaydi
    OrderStatus.CANCELLED: [],    # Yakuniy holat — o'zgartirib bo'lmaydi
}

# Status o'zgarganda qaysi vaqt maydonini yangilash kerak
STATUS_TIMESTAMP_MAP: dict[OrderStatus, str] = {
    OrderStatus.ACCEPTED:   "accepted_at",
    OrderStatus.DONE:       "completed_at",
    OrderStatus.DELIVERED:  "delivered_at",
}


async def update_order_status(
    db: AsyncSession,
    order_id: int,
    data: OrderStatusUpdateRequest,
    changed_by: User,
) -> tuple[Optional[OrderResponse], Optional[str]]:
    """
    Zakaz statusini o'zgartiradi va tarixga yozadi.

    Returns:
        (OrderResponse, None)     — muvaffaqiyatli
        (None, "xato sababi")     — xatolik

    Mantiq:
      1. Zakazni topadi
      2. Transition ruxsat etilganini tekshiradi
      3. Statusni yangilaydi
      4. Vaqt stampini yangilaydi (accepted_at, completed_at, ...)
      5. OrderStatusHistory ga MAJBURIY yozadi
      6. DELIVERED bo'lsa ustaga komisyon hisoblaydi
    """
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None, "Zakaz topilmadi"

    old_status = order.status
    new_status = data.new_status

    # Bir xil status — keraksiz
    if old_status == new_status:
        return None, f"Zakaz allaqachon '{new_status.value}' holatida"

    # Transition tekshiruvi
    allowed = ALLOWED_TRANSITIONS.get(old_status, [])
    if new_status not in allowed:
        allowed_names = [s.value for s in allowed]
        return None, (
            f"'{old_status.value}' holatidan '{new_status.value}' holatiga "
            f"o'tish mumkin emas. Ruxsat etilganlar: {allowed_names}"
        )

    # Statusni yangilash
    order.status = new_status

    # Vaqt stampini yangilash
    if new_status in STATUS_TIMESTAMP_MAP:
        ts_field = STATUS_TIMESTAMP_MAP[new_status]
        setattr(order, ts_field, utc_now())

    # ── Status tarixi — MAJBURIY ──────────────────────────────
    history_entry = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=changed_by.id,
        old_status=old_status,
        new_status=new_status,
        comment=data.comment,
    )
    db.add(history_entry)

    # ── DELIVERED: ustaga komisyon hisoblash ─────────────────
    if new_status == OrderStatus.DELIVERED and order.master_id:
        await _calculate_master_commission(db, order)

    # ── CANCELLED: arxivga o'tkazish ─────────────────────────
    if new_status == OrderStatus.CANCELLED:
        order.is_archived = True
        order.cancel_reason = data.comment

    await db.commit()

    # Qayta yuklash
    fresh_result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    fresh_order = fresh_result.scalar_one()

    logger.info(
        f"🔄 Status o'zgardi: {order.order_number} | "
        f"{old_status.value} → {new_status.value} | "
        f"Kim: {changed_by.username} | "
        f"Izoh: {data.comment or '-'}"
    )

    return _build_order_response(fresh_order), None


async def _calculate_master_commission(
    db: AsyncSession,
    order: Order,
) -> None:
    """
    Zakaz topshirilganda ustaning komisyon ulushini hisoblaydi va balansiga qo'shadi.
    Faqat final_price > 0 bo'lsa ishlaydi.
    """
    if not order.master_id or order.final_price <= 0:
        return

    master_result = await db.execute(
        select(User).where(User.id == order.master_id)
    )
    master = master_result.scalar_one_or_none()
    if not master or master.commission_percent <= 0:
        return

    commission = round(order.final_price * master.commission_percent / 100, 2)
    order.master_commission = commission
    master.balance += commission

    logger.info(
        f"💰 Komisyon hisoblandi: usta={master.full_name} | "
        f"summa={commission:,.0f} so'm ({master.commission_percent}%) | "
        f"zakaz={order.order_number}"
    )


# ================================================================
#  6. TO'LOV QABUL QILISH
# ================================================================

async def process_payment(
    db: AsyncSession,
    order_id: int,
    data: OrderPaymentRequest,
    received_by: User,
) -> tuple[Optional[OrderResponse], Optional[str]]:
    """
    Zakaz to'lovini qabul qiladi.

    Mantiq:
      1. Zakaz DONE holatida bo'lishi kerak
      2. Allaqachon to'lanmagan bo'lishi kerak
      3. final_price ni saqlaydi
      4. is_paid = True qiladi
      5. Kassa jadvaliga kirim yozadi
      6. Statusni DELIVERED ga o'tkazadi
    """
    result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        return None, "Zakaz topilmadi"

    if order.is_paid:
        return None, "Bu zakaz allaqachon to'langan"

    if order.status != OrderStatus.DONE:
        return None, (
            f"To'lov faqat 'done' holatidagi zakaz uchun qabul qilinadi. "
            f"Hozirgi holat: '{order.status.value}'"
        )

    # To'lov ma'lumotlarini saqlash
    order.final_price    = data.final_price
    order.is_paid        = True
    order.payment_method = data.payment_method

    # Kassaga kirim yozish
    transaction = FinanceTransaction(
        transaction_type=TransactionType.INCOME,
        amount=data.final_price,
        description=f"Zakaz to'lovi: {order.order_number}",
        notes=data.comment,
        performed_by_id=received_by.id,
        order_id=order.id,
        payment_method=data.payment_method,
    )
    db.add(transaction)

    # Statusni DELIVERED ga o'tkazish + tarix
    order.status       = OrderStatus.DELIVERED
    order.delivered_at = utc_now()

    history = OrderStatusHistory(
        order_id=order.id,
        changed_by_id=received_by.id,
        old_status=OrderStatus.DONE,
        new_status=OrderStatus.DELIVERED,
        comment=f"To'lov qabul qilindi: {data.final_price:,.0f} so'm ({data.payment_method.value})",
    )
    db.add(history)

    # Ustaga komisyon
    await _calculate_master_commission(db, order)

    # Mijoz umumiy xarajatini yangilash
    client_result = await db.execute(
        select(Client).where(Client.id == order.client_id)
    )
    client = client_result.scalar_one_or_none()
    if client:
        client.total_spent += data.final_price

    await db.commit()

    fresh_result = await db.execute(
        _order_query_with_relations().where(Order.id == order_id)
    )
    fresh_order = fresh_result.scalar_one()

    logger.info(
        f"💳 To'lov qabul qilindi: {order.order_number} | "
        f"{data.final_price:,.0f} so'm | "
        f"{data.payment_method.value} | "
        f"Kim: {received_by.username}"
    )

    return _build_order_response(fresh_order), None


# ================================================================
#  7. DEADLINE ALERT — OGOHLANTIRISH TIZIMI
# ================================================================

async def get_deadline_alerts(
    db: AsyncSession,
    warning_hours: float = 24.0,
) -> list[OrderDeadlineAlertResponse]:
    """
    Muddati o'tgan YOKI yaqinlashgan zakazlar ro'yxatini qaytaradi.

    Kimlar kiradi:
      - Muddati o'tgan (overdue) — har qanday aktiv status
      - warning_hours ichida muddati yetadigan zakazlar

    Yakuniy holatlardagilar (DELIVERED, CANCELLED) kirmaydi.

    Args:
        warning_hours: Necha soat qolganda ogohlantirish beriladi (default: 24)

    Returns:
        Ogohlantirish ro'yxati — eng kritiklari birinchi
    """
    now = utc_now()
    alert_threshold = now + timedelta(hours=warning_hours)

    # Aktiv zakazlardan deadline yaqinlashganlarini topish
    active_statuses = [
        OrderStatus.NEW,
        OrderStatus.ACCEPTED,
        OrderStatus.DIAGNOSING,
        OrderStatus.WAITING,
        OrderStatus.ON_THE_WAY,   # ← Yo'ldagi zakazlar ham nazoratda
        OrderStatus.IN_REPAIR,
        OrderStatus.DONE,
    ]

    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.client),
            selectinload(Order.master),
        )
        .where(
            and_(
                Order.status.in_(active_statuses),
                Order.is_archived == False,
                Order.deadline <= alert_threshold,   # Yaqinlashgan yoki o'tib ketgan
            )
        )
        .order_by(Order.deadline.asc())   # Eng kritiklari birinchi
    )
    orders = result.scalars().all()

    alerts = []
    for order in orders:
        deadline_aware = make_aware(order.deadline)
        d_info = get_deadline_info(deadline_aware)

        tv_parts = filter(None, [order.tv_brand, order.tv_model, order.tv_diagonal])
        tv_info  = " | ".join(tv_parts) or "TV ma'lumoti yo'q"

        alerts.append(
            OrderDeadlineAlertResponse(
                order_id=order.id,
                order_number=order.order_number,
                client_name=order.client.full_name,
                tv_info=tv_info,
                status=order.status,
                deadline=deadline_aware,
                is_overdue=d_info["is_overdue"],
                hours_remaining=d_info["hours_remaining"],
                master_name=order.master.full_name if order.master else None,
            )
        )

    overdue  = [a for a in alerts if a.is_overdue]
    upcoming = [a for a in alerts if not a.is_overdue]

    logger.debug(
        f"🔔 Deadline alertlar: {len(overdue)} muddati o'tgan, "
        f"{len(upcoming)} yaqinlashgan"
    )

    # Avval muddati o'tganlar, keyin yaqinlashganlar
    return overdue + upcoming


# ================================================================
#  8. STATISTIKA (Dashboard uchun)
# ================================================================

async def get_order_stats(db: AsyncSession) -> OrderStatsResponse:
    """
    Dashboard uchun bugungi va umumiy zakaz statistikasi.
    """
    now  = utc_now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

    async def count_by_status(status: OrderStatus, archived: bool = False) -> int:
        r = await db.execute(
            select(func.count(Order.id)).where(
                and_(Order.status == status, Order.is_archived == archived)
            )
        )
        return r.scalar_one()

    async def count_today_by_status(status: OrderStatus) -> int:
        r = await db.execute(
            select(func.count(Order.id)).where(
                and_(
                    Order.status == status,
                    Order.updated_at >= today_start,
                )
            )
        )
        return r.scalar_one()

    # Umumiy
    total   = await db.execute(select(func.count(Order.id)).where(Order.is_archived == False))
    new_cnt = await count_by_status(OrderStatus.NEW)

    in_progress = 0
    for s in [OrderStatus.ACCEPTED, OrderStatus.DIAGNOSING,
              OrderStatus.WAITING, OrderStatus.ON_THE_WAY,
              OrderStatus.IN_REPAIR]:
        in_progress += await count_by_status(s)

    # Bugun
    completed_today = await count_today_by_status(OrderStatus.DONE)
    delivered_today = await count_today_by_status(OrderStatus.DELIVERED)
    cancelled_today = await count_today_by_status(OrderStatus.CANCELLED)

    # Muddati o'tgan
    overdue_r = await db.execute(
        select(func.count(Order.id)).where(
            and_(
                Order.is_archived == False,
                Order.deadline < now,
                Order.status.notin_([
                    OrderStatus.DELIVERED,
                    OrderStatus.CANCELLED,
                ]),
            )
        )
    )
    overdue_count = overdue_r.scalar_one()

    # Bugungi daromad
    revenue_r = await db.execute(
        select(func.coalesce(func.sum(Order.final_price), 0.0)).where(
            and_(
                Order.is_paid == True,
                Order.delivered_at >= today_start,
            )
        )
    )
    revenue_today = revenue_r.scalar_one()

    return OrderStatsResponse(
        total_orders=total.scalar_one(),
        new_orders=new_cnt,
        in_progress=in_progress,
        completed_today=completed_today,
        delivered_today=delivered_today,
        cancelled_today=cancelled_today,
        overdue_count=overdue_count,
        total_revenue_today=float(revenue_today),
    )
TVCRM_EOF

  cat > 'tv-crm/backend/app/services/worker_service.py' << 'TVCRM_EOF'
# ================================================
# services/worker_service.py — Ishchilar biznes logikasi
#
# Tarkib:
#   1. Ishchi yaratish (Admin only)
#   2. Ishchi o'qish — bitta / ro'yxat
#   3. Ishchi ma'lumotlarini yangilash
#   4. Ishchini faolsizlantirish (o'chirmasdan bloklash)
#   5. Komisyon hisoblash + usta balansiga qo'shish
#      + kassadan chiqim yozish  ← 3-qoida
#   6. Ish haqi to'lash + balansdan ayirish + kassaga chiqim
#   7. Balansni qo'lda to'g'irlash (bonus/jarima)
#   8. Ishchi balans tarixi (komisyon + to'lovlar)
#   9. Barcha ustalar umumiy statistikasi
# ================================================

import math
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func, and_

from app.database.models import (
    User, UserRole,
    Order, OrderStatus,
    SalaryPayment, PaymentMethod,
    FinanceTransaction, TransactionType,
    ShopSettings,
)
from app.schemas.worker import (
    WorkerCreateRequest,
    WorkerUpdateRequest,
    SalaryPaymentRequest,
    BalanceAdjustRequest,
    WorkerResponse,
    WorkerListResponse,
    CommissionDetailResponse,
    SalaryPaymentHistoryResponse,
    WorkerBalanceHistoryResponse,
    SalaryPaymentResponse,
    CommissionEventResponse,
)
from app.utils.auth import hash_password
from app.utils.logger import logger


# ================================================================
#  YORDAMCHI: User → WorkerResponse (statistika bilan)
# ================================================================

async def _build_worker_response(
    db: AsyncSession,
    user: User,
) -> WorkerResponse:
    """
    User ob'ektini WorkerResponse ga o'giradi.
    Qo'shimcha: DB dan statistika hisoblanadi.
    """
    # Jami bitirgan zakazlar soni (DELIVERED holati, ushbu usta)
    done_result = await db.execute(
        select(func.count(Order.id)).where(
            and_(
                Order.master_id == user.id,
                Order.status == OrderStatus.DELIVERED,
            )
        )
    )
    total_orders_done = done_result.scalar_one() or 0

    # Jami ishlab topilgan komisyon (barcha zakazlardan)
    earned_result = await db.execute(
        select(func.coalesce(func.sum(Order.master_commission), 0.0)).where(
            and_(
                Order.master_id == user.id,
                Order.master_commission > 0,
            )
        )
    )
    total_earned = float(earned_result.scalar_one())

    # Jami to'lab berilgan (SalaryPayment jadvali)
    paid_result = await db.execute(
        select(func.coalesce(func.sum(SalaryPayment.amount), 0.0)).where(
            SalaryPayment.worker_id == user.id
        )
    )
    total_paid_out = float(paid_result.scalar_one())

    return WorkerResponse(
        id=user.id,
        full_name=user.full_name,
        username=user.username,
        phone=user.phone,
        role=user.role,
        is_active=user.is_active,
        balance=user.balance,
        commission_percent=user.commission_percent,
        salary_rate=user.salary_rate,
        total_orders_done=total_orders_done,
        total_earned=total_earned,
        total_paid_out=total_paid_out,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


# ================================================================
#  YORDAMCHI: Kassa (ShopSettings) balansini yangilash
# ================================================================

async def _get_or_create_shop(db: AsyncSession) -> ShopSettings:
    """ShopSettings ni qaytaradi, yo'q bo'lsa yaratadi"""
    result = await db.execute(select(ShopSettings))
    shop = result.scalar_one_or_none()
    if not shop:
        shop = ShopSettings()
        db.add(shop)
        await db.flush()
    return shop


# ================================================================
#  1. ISHCHI YARATISH
# ================================================================

async def create_worker(
    db: AsyncSession,
    data: WorkerCreateRequest,
    created_by: User,
) -> tuple[Optional[WorkerResponse], Optional[str]]:
    """
    Yangi usta yoki operator yaratadi.

    Tekshiruvlar:
      - Username band emasligini tekshiradi
      - Admin rolini yaratishga yo'l qo'ymaydi (schema'da ham tekshiriladi)

    Returns:
        (WorkerResponse, None)   — muvaffaqiyatli
        (None, "xato sababi")    — xatolik
    """
    # Username band emasligini tekshirish
    existing = await db.execute(
        select(User).where(User.username == data.username)
    )
    if existing.scalar_one_or_none():
        return None, f"'{data.username}' username allaqachon band"

    worker = User(
        full_name=data.full_name,
        username=data.username,
        hashed_password=hash_password(data.password),
        phone=data.phone,
        role=data.role,
        commission_percent=data.commission_percent,
        salary_rate=data.salary_rate,
        balance=0.0,
        is_active=True,
    )
    db.add(worker)
    await db.commit()
    await db.refresh(worker)

    logger.info(
        f"👤 Yangi ishchi yaratildi: {worker.full_name} "
        f"(username={worker.username}, rol={worker.role.value}, "
        f"komisyon={worker.commission_percent}%) | "
        f"Kim yaratdi: {created_by.username}"
    )

    return await _build_worker_response(db, worker), None


# ================================================================
#  2. ISHCHI O'QISH — BITTA
# ================================================================

async def get_worker_by_id(
    db: AsyncSession,
    worker_id: int,
) -> Optional[WorkerResponse]:
    """ID bo'yicha ishchini topadi (statistika bilan)"""
    result = await db.execute(
        select(User).where(User.id == worker_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        return None
    return await _build_worker_response(db, user)


# ================================================================
#  3. ISHCHILAR RO'YXATI
# ================================================================

async def get_workers_list(
    db: AsyncSession,
    role: Optional[UserRole] = None,
    is_active: Optional[bool] = None,
    page: int = 1,
    page_size: int = 50,
) -> WorkerListResponse:
    """
    Ishchilar ro'yxati — filtrlash bilan.
    Admin ko'radi: barcha ishchilar
    Operator ko'radi: faqat ustalar ro'yxati

    Filtrlar:
      role      — master / operator
      is_active — faol / bloklangan
    """
    base_q = select(User).where(User.role != UserRole.ADMIN)

    if role:
        base_q = base_q.where(User.role == role)
    if is_active is not None:
        base_q = base_q.where(User.is_active == is_active)

    # Jami soni
    count_result = await db.execute(
        select(func.count()).select_from(base_q.subquery())
    )
    total = count_result.scalar_one()

    # Sahifalash
    offset = (page - 1) * page_size
    paginated = base_q.order_by(User.full_name.asc()).offset(offset).limit(page_size)
    result = await db.execute(paginated)
    users = result.scalars().all()

    # Ustalar va operatorlar sonini alohida hisoblaymiz
    masters_r = await db.execute(
        select(func.count(User.id)).where(
            and_(User.role == UserRole.MASTER, User.is_active == True)
        )
    )
    operators_r = await db.execute(
        select(func.count(User.id)).where(
            and_(User.role == UserRole.OPERATOR, User.is_active == True)
        )
    )

    items = [await _build_worker_response(db, u) for u in users]

    return WorkerListResponse(
        items=items,
        total=total,
        masters=masters_r.scalar_one(),
        operators=operators_r.scalar_one(),
    )


# ================================================================
#  4. ISHCHI MA'LUMOTLARINI YANGILASH
# ================================================================

async def update_worker(
    db: AsyncSession,
    worker_id: int,
    data: WorkerUpdateRequest,
    updated_by: User,
) -> tuple[Optional[WorkerResponse], Optional[str]]:
    """
    Ishchi ma'lumotlarini yangilaydi (PATCH).
    commission_percent o'zgarganda log yoziladi.
    """
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()

    if not worker:
        return None, "Ishchi topilmadi"

    if worker.role == UserRole.ADMIN:
        return None, "Admin ma'lumotlarini bu endpoint orqali o'zgartirish mumkin emas"

    update_data = data.model_dump(exclude_unset=True)

    # Komisyon foizi o'zgarsa — alohida log
    if "commission_percent" in update_data:
        old_pct = worker.commission_percent
        new_pct = update_data["commission_percent"]
        logger.info(
            f"💱 Komisyon foizi o'zgardi: {worker.full_name} | "
            f"{old_pct}% → {new_pct}% | "
            f"Kim o'zgartirdi: {updated_by.username}"
        )

    for field, value in update_data.items():
        setattr(worker, field, value)

    await db.commit()
    await db.refresh(worker)

    logger.info(
        f"✏️  Ishchi yangilandi: {worker.full_name} | "
        f"Maydonlar: {list(update_data.keys())} | "
        f"Kim: {updated_by.username}"
    )

    return await _build_worker_response(db, worker), None


# ================================================================
#  5. KOMISYON HISOBLASH
#     Zakaz DELIVERED bo'lganda chaqiriladi (order_service ham chaqiradi)
#     Bu yerda: kassa chiqimi ham yoziladi
# ================================================================

async def apply_commission(
    db: AsyncSession,
    order: Order,
) -> Optional[CommissionEventResponse]:
    """
    Zakaz topshirilganda (DELIVERED) ustaga komisyon hisoblaydi.

    Mantiq (3-qoida):
      1. Ustaning commission_percent ni oladi
      2. Komisyon = final_price × commission_percent / 100
      3. Komisyon summasi → Ustaning balance ga QO'SHILADI
      4. Kassadan (ShopSettings.total_balance) AYIRILADI
      5. FinanceTransaction ga CHIQIM yoziladi (audit uchun)
      6. Barcha amallar commit qilinadi

    Bu funksiya order_service.process_payment ichida chaqiriladi,
    lekin worker_service orqali ham to'g'ridan-to'g'ri chaqirish mumkin.

    Returns:
        CommissionEventResponse — muvaffaqiyatli
        None                    — usta yo'q yoki komisyon 0
    """
    if not order.master_id:
        return None

    # Ustani DB dan yangi o'qiymiz (cache emas)
    master_result = await db.execute(
        select(User).where(User.id == order.master_id)
    )
    master = master_result.scalar_one_or_none()

    if not master:
        logger.warning(f"⚠️  Zakaz {order.order_number}: usta id={order.master_id} topilmadi")
        return None

    if master.commission_percent <= 0 or order.final_price <= 0:
        logger.debug(
            f"Komisyon hisoblanmadi: {order.order_number} | "
            f"foiz={master.commission_percent}% | "
            f"narx={order.final_price}"
        )
        return None

    # ── Komisyon hisoblash ────────────────────────────────────
    commission = round(order.final_price * master.commission_percent / 100, 2)

    # Eski qiymatlar (log uchun)
    old_balance = master.balance

    # ── 3a. Usta balansiga QO'SHISH ──────────────────────────
    master.balance += commission
    order.master_commission = commission

    # ── 3b. Kassadan AYIRISH ──────────────────────────────────
    shop = await _get_or_create_shop(db)
    shop.total_balance -= commission

    # ── 3c. FinanceTransaction — CHIQIM yozuvi ───────────────
    finance_entry = FinanceTransaction(
        transaction_type=TransactionType.SALARY,
        amount=commission,
        description=(
            f"Komisyon: {master.full_name} — "
            f"zakaz {order.order_number} "
            f"({master.commission_percent}% × {order.final_price:,.0f} so'm)"
        ),
        notes=f"Avtomatik hisoblangan komisyon. Zakaz: {order.order_number}",
        performed_by_id=master.id,
        order_id=order.id,
        payment_method=PaymentMethod.TRANSFER,
    )
    db.add(finance_entry)

    # ── Commit ────────────────────────────────────────────────
    await db.commit()

    logger.info(
        f"💰 Komisyon hisoblandi:\n"
        f"   Usta    : {master.full_name} (id={master.id})\n"
        f"   Zakaz   : {order.order_number}\n"
        f"   Narx    : {order.final_price:,.0f} so'm\n"
        f"   Foiz    : {master.commission_percent}%\n"
        f"   Komisyon: {commission:,.0f} so'm\n"
        f"   Balans  : {old_balance:,.0f} → {master.balance:,.0f} so'm\n"
        f"   Kassa   : -{commission:,.0f} so'm"
    )

    return CommissionEventResponse(
        worker_id=master.id,
        worker_name=master.full_name,
        order_number=order.order_number,
        final_price=order.final_price,
        commission_percent=master.commission_percent,
        commission_amount=commission,
        new_balance=master.balance,
        kassa_deducted=commission,
    )


# ================================================================
#  6. ISH HAQI TO'LASH
# ================================================================

async def pay_salary(
    db: AsyncSession,
    worker_id: int,
    data: SalaryPaymentRequest,
    paid_by: User,
) -> tuple[Optional[SalaryPaymentResponse], Optional[str]]:
    """
    Ishchiga ish haqi to'laydi.

    Mantiq:
      1. Ishchini topadi va faolligini tekshiradi
      2. To'lov summasi balansdan ko'p bo'lmasligi tekshiriladi
         (manfiy balansga yo'l qo'ymaydi)
      3. Ishchining balance dan AYIRADI
      4. SalaryPayment jadvaliga yozadi (to'lov tarixi)
      5. Kassaga CHIQIM yozadi (FinanceTransaction)

    Returns:
        (SalaryPaymentResponse, None)  — muvaffaqiyatli
        (None, "xato sababi")          — xatolik
    """
    # Ishchini topish
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()

    if not worker:
        return None, "Ishchi topilmadi"

    if not worker.is_active:
        return None, f"'{worker.full_name}' hisobi bloklangan, to'lov amalga oshirib bo'lmaydi"

    # Balans yetarliligini tekshirish
    if data.amount > worker.balance:
        return None, (
            f"Balans yetarli emas. "
            f"Joriy balans: {worker.balance:,.0f} so'm, "
            f"So'ralgan: {data.amount:,.0f} so'm"
        )

    old_balance = worker.balance

    # ── Balansdan ayirish ─────────────────────────────────────
    worker.balance -= data.amount

    # ── SalaryPayment tarixi ──────────────────────────────────
    salary_record = SalaryPayment(
        worker_id=worker.id,
        amount=data.amount,
        payment_method=data.payment_method,
        notes=data.notes,
        paid_by_id=paid_by.id,
    )
    db.add(salary_record)

    # ── Kassaga chiqim yozish ─────────────────────────────────
    finance_entry = FinanceTransaction(
        transaction_type=TransactionType.SALARY,
        amount=data.amount,
        description=f"Ish haqi: {worker.full_name}",
        notes=data.notes or f"Ish haqi to'lovi. {worker.role.value}: {worker.full_name}",
        performed_by_id=paid_by.id,
        payment_method=data.payment_method,
    )
    db.add(finance_entry)

    await db.commit()

    logger.info(
        f"💳 Ish haqi to'landi:\n"
        f"   Ishchi : {worker.full_name} (id={worker.id})\n"
        f"   Summa  : {data.amount:,.0f} so'm ({data.payment_method.value})\n"
        f"   Balans : {old_balance:,.0f} → {worker.balance:,.0f} so'm\n"
        f"   Kim to'ladi: {paid_by.username}\n"
        f"   Izoh   : {data.notes or '-'}"
    )

    return SalaryPaymentResponse(
        success=True,
        message=f"{worker.full_name}ga {data.amount:,.0f} so'm muvaffaqiyatli to'landi",
        worker_name=worker.full_name,
        amount_paid=data.amount,
        new_balance=worker.balance,
        payment_method=data.payment_method,
    ), None


# ================================================================
#  7. BALANSNI QO'LDA TO'G'IRLASH (ADMIN)
# ================================================================

async def adjust_balance(
    db: AsyncSession,
    worker_id: int,
    data: BalanceAdjustRequest,
    adjusted_by: User,
) -> tuple[Optional[WorkerResponse], Optional[str]]:
    """
    Admin ishchi balansini qo'lda o'zgartiradi (bonus / tuzatish).

    Manfiy miqdor — balansdan ayiradi (jarima / tuzatish).
    Musbat miqdor — balansga qo'shadi (bonus / to'ldirish).

    Har qanday o'zgarish FinanceTransaction ga yoziladi (audit).
    """
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()

    if not worker:
        return None, "Ishchi topilmadi"

    # Manfiy miqdor: natija balans 0 dan past bo'lmasligi tekshiriladi
    if data.amount < 0 and (worker.balance + data.amount) < 0:
        return None, (
            f"Balans manfiyga tushmaydi. "
            f"Joriy: {worker.balance:,.0f} so'm, "
            f"Ayirilmoqchi: {abs(data.amount):,.0f} so'm"
        )

    old_balance = worker.balance
    worker.balance += data.amount

    # Audit izi uchun FinanceTransaction
    t_type = TransactionType.INCOME if data.amount > 0 else TransactionType.EXPENSE
    finance_entry = FinanceTransaction(
        transaction_type=t_type,
        amount=abs(data.amount),
        description=f"Balans tuzatish: {worker.full_name} — {data.reason}",
        notes=f"Admin tomonidan qo'lda amalga oshirildi. Sabab: {data.reason}",
        performed_by_id=adjusted_by.id,
        payment_method=PaymentMethod.TRANSFER,
    )
    db.add(finance_entry)

    await db.commit()
    await db.refresh(worker)

    sign = "+" if data.amount >= 0 else ""
    logger.info(
        f"🔧 Balans tuzatildi: {worker.full_name} | "
        f"{old_balance:,.0f} → {worker.balance:,.0f} so'm "
        f"({sign}{data.amount:,.0f}) | "
        f"Sabab: {data.reason} | "
        f"Admin: {adjusted_by.username}"
    )

    return await _build_worker_response(db, worker), None


# ================================================================
#  8. ISHCHI BALANS TARIXI
# ================================================================

async def get_worker_balance_history(
    db: AsyncSession,
    worker_id: int,
) -> Optional[WorkerBalanceHistoryResponse]:
    """
    Ishchining to'liq moliyaviy tarixi:
      - Hisoblangan komisyonlar (zakaz bo'yicha)
      - To'langan ish haqlar

    Dashboard'dagi "Mening balansim" va
    Admin panelida "Ishchi hisoboti" uchun ishlatiladi.
    """
    result = await db.execute(select(User).where(User.id == worker_id))
    worker = result.scalar_one_or_none()
    if not worker:
        return None

    # ── Komisyon tarixi ───────────────────────────────────────
    from sqlalchemy.orm import selectinload
    orders_result = await db.execute(
        select(Order)
        .options(selectinload(Order.client))
        .where(
            and_(
                Order.master_id == worker_id,
                Order.master_commission > 0,
            )
        )
        .order_by(Order.delivered_at.desc().nulls_last())
    )
    orders = orders_result.scalars().all()

    commissions = []
    total_earned = 0.0
    for o in orders:
        tv_parts = filter(None, [o.tv_brand, o.tv_model, o.tv_diagonal])
        tv_info  = " | ".join(tv_parts) or "TV ma'lumoti yo'q"

        commissions.append(CommissionDetailResponse(
            order_id=o.id,
            order_number=o.order_number,
            order_date=o.delivered_at or o.updated_at,
            final_price=o.final_price,
            commission_percent=o.master_commission / o.final_price * 100
                               if o.final_price > 0 else worker.commission_percent,
            commission_amount=o.master_commission,
            client_name=o.client.full_name if o.client else "—",
            tv_info=tv_info,
        ))
        total_earned += o.master_commission

    # ── Ish haqi tarixi ───────────────────────────────────────
    salary_result = await db.execute(
        select(SalaryPayment)
        .where(SalaryPayment.worker_id == worker_id)
        .order_by(SalaryPayment.created_at.desc())
    )
    salary_records = salary_result.scalars().all()

    salary_payments = []
    total_paid_out = 0.0

    # paid_by nomlarini bir so'rovda olamiz
    paid_by_ids = {s.paid_by_id for s in salary_records if s.paid_by_id}
    paid_by_map: dict[int, str] = {}
    if paid_by_ids:
        pb_result = await db.execute(
            select(User.id, User.full_name).where(User.id.in_(paid_by_ids))
        )
        paid_by_map = {row[0]: row[1] for row in pb_result.all()}

    for s in salary_records:
        salary_payments.append(SalaryPaymentHistoryResponse(
            id=s.id,
            amount=s.amount,
            payment_method=s.payment_method,
            notes=s.notes,
            paid_by=paid_by_map.get(s.paid_by_id) if s.paid_by_id else None,
            created_at=s.created_at,
        ))
        total_paid_out += s.amount

    return WorkerBalanceHistoryResponse(
        worker_id=worker.id,
        worker_name=worker.full_name,
        balance=worker.balance,
        commissions=commissions,
        total_earned=round(total_earned, 2),
        salary_payments=salary_payments,
        total_paid_out=round(total_paid_out, 2),
    )


# ================================================================
#  9. UMUMIY STATISTIKA (Admin dashboard uchun)
# ================================================================

async def get_workers_finance_summary(db: AsyncSession) -> dict:
    """
    Barcha ishchilar moliyaviy xulosasi.
    Admin dashboard'ining "Ishchilar" kartasida ko'rsatiladi.

    Qaytaradi:
      - total_workers    : jami faol ishchilar
      - total_balance    : barcha ishchilar balanslari yig'indisi
                           (to'lanmagan komisyon qoldig'i)
      - total_earned     : jami hisoblangan komisyonlar
      - total_paid_out   : jami to'langan ish haqlar
      - pending_payout   : hali to'lanmagan (balansda turibdi)
      - workers_detail   : har bir ishchining qisqacha holati
    """
    # Faol ishchilar (admin bundan mustasno)
    workers_result = await db.execute(
        select(User).where(
            and_(
                User.role != UserRole.ADMIN,
                User.is_active == True,
            )
        ).order_by(User.full_name)
    )
    workers = workers_result.scalars().all()

    # Yig'ma ko'rsatkichlar
    total_balance  = sum(w.balance for w in workers)

    earned_r = await db.execute(
        select(func.coalesce(func.sum(Order.master_commission), 0.0)).where(
            Order.master_commission > 0
        )
    )
    total_earned = float(earned_r.scalar_one())

    paid_r = await db.execute(
        select(func.coalesce(func.sum(SalaryPayment.amount), 0.0))
    )
    total_paid_out = float(paid_r.scalar_one())

    # Har bir ishchining qisqacha holati
    workers_detail = []
    for w in workers:
        w_done_r = await db.execute(
            select(func.count(Order.id)).where(
                and_(
                    Order.master_id == w.id,
                    Order.status == OrderStatus.DELIVERED,
                )
            )
        )
        workers_detail.append({
            "id":                 w.id,
            "full_name":          w.full_name,
            "role":               w.role.value,
            "balance":            w.balance,
            "commission_percent": w.commission_percent,
            "orders_done":        w_done_r.scalar_one(),
        })

    return {
        "total_workers":  len(workers),
        "total_balance":  round(total_balance, 2),
        "total_earned":   round(total_earned, 2),
        "total_paid_out": round(total_paid_out, 2),
        "pending_payout": round(total_balance, 2),
        "workers_detail": workers_detail,
    }
TVCRM_EOF

  cat > 'tv-crm/backend/app/services/location_service.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/utils/__init__.py' << 'TVCRM_EOF'
# Utility functions package
TVCRM_EOF

  cat > 'tv-crm/backend/app/utils/auth.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/utils/dependencies.py' << 'TVCRM_EOF'
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
TVCRM_EOF

  cat > 'tv-crm/backend/app/utils/helpers.py' << 'TVCRM_EOF'
# ================================================
# utils/helpers.py — Umumiy yordamchi funksiyalar
#
# Tarkib:
#   1. Zakaz raqami generatori  (TV-2025-0001)
#   2. Deadline tekshiruvchi    (o'tganmi? qancha qoldi?)
#   3. Deadline ogohlantirish   (CRITICAL / WARNING / OK)
#   4. Vaqt formatlash yordamchilari
# ================================================

from datetime import datetime, timezone, timedelta
from typing import Optional
from enum import Enum


# ================================================================
#  1. ZAKAZ RAQAMI GENERATORI
# ================================================================

def generate_order_number(counter: int, year: Optional[int] = None) -> str:
    """
    Inson o'qiy oladigan zakaz raqamini yaratadi.

    Format: TV-{YIL}-{TARTIB_RAQAM}
    Misol:  TV-2025-0001, TV-2025-0042, TV-2025-1000

    Args:
        counter : ShopSettings.order_counter dan olingan qiymat
        year    : Yil (None bo'lsa joriy yil ishlatiladi)

    Returns:
        "TV-2025-0001" ko'rinishidagi string
    """
    if year is None:
        year = datetime.now(timezone.utc).year
    return f"TV-{year}-{counter:04d}"


# ================================================================
#  2. DEADLINE HOLATI ENUM
# ================================================================

class DeadlineStatus(str, Enum):
    """
    Deadline holati — rang va ogohlantirish darajasi uchun.
    Frontend bu qiymatni olib, rangni o'zi belgilaydi.
    """
    OK        = "ok"        # ✅ 24+ soat qoldi — xavfsiz
    WARNING   = "warning"   # ⚠️  24 soatdan kam qoldi — diqqat
    CRITICAL  = "critical"  # 🔴 2 soatdan kam qoldi — shoshilish kerak
    OVERDUE   = "overdue"   # ❌ Muddat o'tib ketdi


# ================================================================
#  3. DEADLINE TEKSHIRUVCHI
# ================================================================

def get_deadline_info(deadline: datetime) -> dict:
    """
    Berilgan deadline uchun to'liq ma'lumot paketini qaytaradi.

    Returns dict:
        is_overdue        (bool)  — muddat o'tib ketganmi
        hours_remaining   (float) — qancha soat qoldi (manfiy = o'tib ketgan)
        minutes_remaining (int)   — qancha daqiqa qoldi
        status            (DeadlineStatus) — OK / WARNING / CRITICAL / OVERDUE
        status_label      (str)   — O'zbek tilida tavsif
        alert_message     (str)   — Ogohlantirish xabari
    """
    now = datetime.now(timezone.utc)

    # Deadline timezone-aware bo'lishini ta'minlaymiz
    if deadline.tzinfo is None:
        deadline = deadline.replace(tzinfo=timezone.utc)

    delta: timedelta = deadline - now
    total_seconds = delta.total_seconds()
    hours_remaining = total_seconds / 3600
    minutes_remaining = int(total_seconds / 60)

    # Holat aniqlash
    if total_seconds <= 0:
        status = DeadlineStatus.OVERDUE
        overdue_hours = abs(hours_remaining)
        if overdue_hours < 1:
            label = f"Muddat {abs(minutes_remaining)} daqiqa oldin o'tdi"
        elif overdue_hours < 24:
            label = f"Muddat {overdue_hours:.1f} soat oldin o'tdi"
        else:
            overdue_days = overdue_hours / 24
            label = f"Muddat {overdue_days:.1f} kun oldin o'tdi"
        alert = f"❌ MUDDATI O'TDI: {label}"

    elif hours_remaining <= 2:
        status = DeadlineStatus.CRITICAL
        label = f"{minutes_remaining} daqiqa qoldi"
        alert = f"🔴 SHOSHILISH KERAK: Faqat {label}!"

    elif hours_remaining <= 24:
        status = DeadlineStatus.WARNING
        label = f"{hours_remaining:.1f} soat qoldi"
        alert = f"⚠️  DIQQAT: {label}"

    else:
        status = DeadlineStatus.OK
        days = hours_remaining / 24
        if days >= 1:
            label = f"{days:.1f} kun qoldi"
        else:
            label = f"{hours_remaining:.1f} soat qoldi"
        alert = f"✅ Vaqt bor: {label}"

    return {
        "is_overdue":        total_seconds <= 0,
        "hours_remaining":   round(hours_remaining, 2),
        "minutes_remaining": minutes_remaining,
        "status":            status,
        "status_label":      label,
        "alert_message":     alert,
    }


def is_overdue(deadline: datetime) -> bool:
    """Deadline o'tib ketganini tez tekshirish (bool)"""
    now = datetime.now(timezone.utc)
    if deadline.tzinfo is None:
        deadline = deadline.replace(tzinfo=timezone.utc)
    return deadline <= now


def hours_until_deadline(deadline: datetime) -> float:
    """
    Deadline gacha qancha soat qolganini qaytaradi.
    Manfiy = muddat o'tib ketgan.
    """
    now = datetime.now(timezone.utc)
    if deadline.tzinfo is None:
        deadline = deadline.replace(tzinfo=timezone.utc)
    delta = deadline - now
    return round(delta.total_seconds() / 3600, 2)


# ================================================================
#  4. OGOHLANTIRISH CHEGARALARI
#     Bu qiymatlarni sozlamalar orqali o'zgartirish mumkin
# ================================================================

DEADLINE_THRESHOLDS = {
    "critical_hours": 2,   # 2 soatdan kam qolsa — CRITICAL
    "warning_hours":  24,  # 24 soatdan kam qolsa — WARNING
}


def get_alert_level(deadline: datetime) -> DeadlineStatus:
    """Faqat DeadlineStatus enum qaytaradi (filtrlash uchun qulay)"""
    info = get_deadline_info(deadline)
    return info["status"]


# ================================================================
#  5. VAQT FORMATLASH YORDAMCHILARI
# ================================================================

def format_datetime_uz(dt: Optional[datetime]) -> Optional[str]:
    """
    Datetime ni O'zbek formatiga o'tkazadi.
    Misol: "20-iyun 2025, 18:00"
    """
    if dt is None:
        return None
    months_uz = [
        "yanvar", "fevral", "mart", "aprel", "may", "iyun",
        "iyul", "avgust", "sentabr", "oktabr", "noyabr", "dekabr"
    ]
    return f"{dt.day}-{months_uz[dt.month - 1]} {dt.year}, {dt.strftime('%H:%M')}"


def utc_now() -> datetime:
    """Joriy UTC vaqtini qaytaradi (timezone-aware)"""
    return datetime.now(timezone.utc)


def make_aware(dt: datetime) -> datetime:
    """Timezone-naive datetime ni UTC-aware ga o'tkazadi"""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt
TVCRM_EOF

  cat > 'tv-crm/backend/app/utils/logger.py' << 'TVCRM_EOF'
# ================================================
# utils/logger.py — Logging sozlamalari
# Loguru kutubxonasi asosida professional logging
# ================================================

import sys
from loguru import logger
from app.config import settings


def setup_logger() -> None:
    """
    Loguru logger'ini sozlaydi.
    Konsolga va faylga yozadi.
    """
    # Standart handler'ni o'chiramiz
    logger.remove()

    # --- Konsol handler (rangli, o'qish uchun qulay) ---
    log_format = (
        "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )

    logger.add(
        sys.stdout,
        format=log_format,
        level="DEBUG" if settings.debug else "INFO",
        colorize=True,
    )

    # --- Fayl handler (arxiv, 10MB dan katta bo'lsa yangi fayl) ---
    logger.add(
        "logs/crm_{time:YYYY-MM-DD}.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
        level="INFO",
        rotation="10 MB",       # 10 MB dan katta bo'lsa yangi fayl
        retention="30 days",    # 30 kundan eski loglar o'chiriladi
        compression="zip",      # Eski loglarni zip qiladi
        encoding="utf-8",
    )

    # --- Xato handler (faqat ERROR va CRITICAL) ---
    logger.add(
        "logs/errors_{time:YYYY-MM-DD}.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}\n{exception}",
        level="ERROR",
        rotation="5 MB",
        retention="90 days",
        compression="zip",
        encoding="utf-8",
    )

    logger.info("Logger sozlandi ✅")


# Global logger export
__all__ = ["logger", "setup_logger"]
TVCRM_EOF

  cat > 'tv-crm/backend/app/integrations/__init__.py' << 'TVCRM_EOF'
# External integrations package (Telegram, Instagram, SIP)
TVCRM_EOF

  cat > 'tv-crm/backend/tests/__init__.py' << 'TVCRM_EOF'
# Tests package
TVCRM_EOF

  cat > 'tv-crm/frontend/index.html' << 'TVCRM_EOF'
<!DOCTYPE html>
<html lang="uz">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="TV Ta'mirlash Ustaxonasi — CRM Boshqaruv Tizimi" />

    <!-- Favicon -->
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />

    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
      rel="stylesheet"
    />

    <title>📺 TV CRM — Boshqaruv Tizimi</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
TVCRM_EOF

  cat > 'tv-crm/frontend/package.json' << 'TVCRM_EOF'
{
  "name": "tv-crm-frontend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev":     "vite",
    "build":   "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react":            "^18.3.1",
    "react-dom":        "^18.3.1",
    "react-router-dom": "^6.24.0",
    "axios":            "^1.7.2",
    "zustand":          "^4.5.2",
    "dayjs":            "^1.11.11",
    "react-hot-toast":  "^2.4.1"
  },
  "devDependencies": {
    "@types/react":          "^18.3.3",
    "@types/react-dom":      "^18.3.0",
    "@vitejs/plugin-react":  "^4.3.1",
    "vite":                  "^5.3.1",
    "tailwindcss":           "^3.4.4",
    "autoprefixer":          "^10.4.19",
    "postcss":               "^8.4.39"
  }
}
TVCRM_EOF

  cat > 'tv-crm/frontend/vite.config.js' << 'TVCRM_EOF'
// vite.config.js — Vite sozlamalari
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],

  resolve: {
    alias: {
      // @ = src/ — import '@/api/axiosInstance' yozish uchun
      '@': path.resolve(__dirname, './src'),
    },
  },

  server: {
    port: 5173,
    // Backend API ga proxy — CORS muammosini hal qiladi
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        secure: false,
      },
    },
  },
});
TVCRM_EOF

  cat > 'tv-crm/frontend/tailwind.config.js' << 'TVCRM_EOF'
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Asosiy brend ranglar
        primary: {
          50:  '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a8a',
        },
        // Sidebar qoʻngʻir-koʻk
        sidebar: {
          bg:     '#0f172a',
          hover:  '#1e293b',
          active: '#1d4ed8',
          text:   '#94a3b8',
          light:  '#f1f5f9',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        card: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        modal: '0 25px 50px -12px rgb(0 0 0 / 0.25)',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'slide-in':   'slideIn 0.2s ease-out',
        'fade-in':    'fadeIn 0.15s ease-out',
      },
      keyframes: {
        slideIn: {
          '0%':   { transform: 'translateX(-10px)', opacity: '0' },
          '100%': { transform: 'translateX(0)',     opacity: '1' },
        },
        fadeIn: {
          '0%':   { opacity: '0', transform: 'scale(0.97)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
      },
    },
  },
  plugins: [],
};
TVCRM_EOF

  cat > 'tv-crm/frontend/postcss.config.js' << 'TVCRM_EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
TVCRM_EOF

  cat > 'tv-crm/frontend/src/main.jsx' << 'TVCRM_EOF'
// ================================================
// main.jsx — React ilovasining kirish nuqtasi
// ================================================

import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import '@/styles/main.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
TVCRM_EOF

  cat > 'tv-crm/frontend/src/App.jsx' << 'TVCRM_EOF'
// ================================================
// App.jsx — Markaziy routing va sahifalar
// ================================================

import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';

import MainLayout from '@/components/Layout/MainLayout';
import Login      from '@/pages/Login';
import Dashboard  from '@/pages/Dashboard';
import Orders     from '@/pages/Orders';

// ── Placeholder sahifalar (keyingi bosqichlar uchun) ─────────────
function ComingSoon({ title, icon }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      justifyContent: 'center', minHeight: 400, gap: 16,
      color: '#94a3b8',
    }}>
      <div style={{ fontSize: 64 }}>{icon}</div>
      <h2 style={{ fontSize: 22, fontWeight: 700, color: '#64748b' }}>
        {title}
      </h2>
      <p style={{ fontSize: 14 }}>
        Bu sahifa keyingi bosqichda quriladi
      </p>
      <div style={{
        display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center',
      }}>
        {['Backend API', 'Jadval', 'Modallar', 'Filtrlar'].map((item) => (
          <span
            key={item}
            style={{
              padding: '4px 12px', borderRadius: 20,
              background: '#f1f5f9', color: '#64748b',
              fontSize: 12, fontWeight: 500,
            }}
          >
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}

// ── Auth Guard — himoyalangan sahifalar ──────────────────────────
function ProtectedRoute({ children }) {
  return <MainLayout>{children}</MainLayout>;
}

export default function App() {
  return (
    <BrowserRouter>
      {/* Toast bildirishnomalar */}
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 4000,
          style: {
            fontFamily: 'Inter, sans-serif',
            fontSize:   '13.5px',
            fontWeight: '500',
            borderRadius: '10px',
            boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
            padding: '12px 16px',
          },
          success: {
            style: {
              background: '#f0fdf4',
              color:      '#15803d',
              border:     '1px solid #bbf7d0',
            },
            iconTheme: { primary: '#16a34a', secondary: '#dcfce7' },
          },
          error: {
            duration: 6000,
            style: {
              background: '#fef2f2',
              color:      '#dc2626',
              border:     '1px solid #fca5a5',
            },
            iconTheme: { primary: '#dc2626', secondary: '#fee2e2' },
          },
        }}
      />

      <Routes>
        {/* ── Public ─────────────────────────────────────────── */}
        <Route path="/login" element={<Login />} />

        {/* ── Asosiy sahifalar ────────────────────────────────── */}
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/orders"
          element={
            <ProtectedRoute>
              <Orders />
            </ProtectedRoute>
          }
        />

        {/* ── Keyingi bosqichlarda to'liq quriladi ─────────────── */}
        <Route
          path="/workers"
          element={
            <ProtectedRoute>
              <ComingSoon title="Ishchilar" icon="👷" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/clients"
          element={
            <ProtectedRoute>
              <ComingSoon title="Mijozlar" icon="👥" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/warehouse"
          element={
            <ProtectedRoute>
              <ComingSoon title="Ombor" icon="🏪" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/finance"
          element={
            <ProtectedRoute>
              <ComingSoon title="Moliya" icon="💰" />
            </ProtectedRoute>
          }
        />
        <Route
          path="/archive"
          element={
            <ProtectedRoute>
              <ComingSoon title="Arxiv" icon="📦" />
            </ProtectedRoute>
          }
        />

        {/* ── Redirect'lar ────────────────────────────────────── */}
        <Route path="/"     element={<Navigate to="/dashboard" replace />} />
        <Route path="*"     element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/styles/main.css' << 'TVCRM_EOF'
/* ================================================
   main.css — Global uslublar
   Tailwind direktivalar + CSS o'zgaruvchilar + utility classlar
   ================================================ */

/* ── Google Font import — @import BIRINCHI bo'lishi shart ── */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

/* ================================================================
   CSS O'ZGARUVCHILAR (Design Tokens)
   ================================================================ */
:root {
  /* Ranglar */
  --color-primary:       #2563eb;
  --color-primary-dark:  #1d4ed8;
  --color-primary-light: #dbeafe;

  --color-success:       #16a34a;
  --color-success-light: #dcfce7;
  --color-warning:       #d97706;
  --color-warning-light: #fef3c7;
  --color-danger:        #dc2626;
  --color-danger-light:  #fee2e2;
  --color-info:          #0891b2;
  --color-info-light:    #cffafe;

  /* Sidebar */
  --sidebar-width:       260px;
  --sidebar-bg:          #0f172a;
  --sidebar-hover:       #1e293b;
  --sidebar-active:      #1d4ed8;
  --sidebar-text:        #94a3b8;
  --sidebar-text-light:  #f1f5f9;

  /* Layout */
  --header-height:       64px;
  --content-padding:     24px;

  /* Radius */
  --radius-sm:  4px;
  --radius-md:  8px;
  --radius-lg:  12px;
  --radius-xl:  16px;
  --radius-2xl: 24px;

  /* Shadow */
  --shadow-sm:   0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md:   0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg:   0 10px 15px -3px rgb(0 0 0 / 0.1);
  --shadow-xl:   0 20px 25px -5px rgb(0 0 0 / 0.15);
  --shadow-modal: 0 25px 50px -12px rgb(0 0 0 / 0.35);

  /* Transition */
  --transition-fast:   150ms ease;
  --transition-normal: 200ms ease;
  --transition-slow:   300ms ease;
}

/* ================================================================
   BASE RESET & GLOBAL
   ================================================================ */
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  font-size: 16px;
  -webkit-text-size-adjust: 100%;
  scroll-behavior: smooth;
}

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  font-size: 14px;
  line-height: 1.5;
  color: #1e293b;
  background-color: #f8fafc;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Scrollbar uslubi */
::-webkit-scrollbar        { width: 6px; height: 6px; }
::-webkit-scrollbar-track  { background: #f1f5f9; }
::-webkit-scrollbar-thumb  { background: #cbd5e1; border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: #94a3b8; }

/* ================================================================
   LAYOUT KOMPONENTLAR
   ================================================================ */

/* App wrapper */
.app-layout {
  display: flex;
  min-height: 100vh;
}

/* Sidebar */
.sidebar {
  width: var(--sidebar-width);
  min-height: 100vh;
  background: var(--sidebar-bg);
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  z-index: 40;
  transition: transform var(--transition-normal);
}

.sidebar-logo {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 20px 20px 16px;
  border-bottom: 1px solid #1e293b;
}

.sidebar-logo-icon {
  width: 38px;
  height: 38px;
  background: var(--color-primary);
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
}

.sidebar-logo-text {
  flex: 1;
}

.sidebar-logo-title {
  font-size: 14px;
  font-weight: 700;
  color: #f1f5f9;
  line-height: 1.2;
}

.sidebar-logo-sub {
  font-size: 11px;
  color: var(--sidebar-text);
  margin-top: 1px;
}

/* Nav */
.sidebar-nav {
  flex: 1;
  padding: 12px 0;
  overflow-y: auto;
}

.nav-section-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #475569;
  padding: 12px 20px 4px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 20px;
  color: var(--sidebar-text);
  text-decoration: none;
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all var(--transition-fast);
  border-left: 3px solid transparent;
  position: relative;
}

.nav-item:hover {
  background: var(--sidebar-hover);
  color: #e2e8f0;
}

.nav-item.active {
  background: rgba(37, 99, 235, 0.15);
  color: #93c5fd;
  border-left-color: var(--color-primary);
}

.nav-item .nav-icon {
  width: 18px;
  height: 18px;
  opacity: 0.8;
  flex-shrink: 0;
}

.nav-item .nav-badge {
  margin-left: auto;
  background: var(--color-danger);
  color: white;
  font-size: 10px;
  font-weight: 700;
  padding: 1px 6px;
  border-radius: 10px;
  min-width: 18px;
  text-align: center;
}

/* Sidebar footer */
.sidebar-footer {
  padding: 12px 16px;
  border-top: 1px solid #1e293b;
}

.sidebar-user {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: background var(--transition-fast);
}

.sidebar-user:hover { background: var(--sidebar-hover); }

.sidebar-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: var(--color-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  color: white;
  flex-shrink: 0;
}

.sidebar-user-info { flex: 1; overflow: hidden; }

.sidebar-user-name {
  font-size: 13px;
  font-weight: 600;
  color: #e2e8f0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.sidebar-user-role {
  font-size: 11px;
  color: var(--sidebar-text);
  margin-top: 1px;
}

/* Main content */
.main-content {
  margin-left: var(--sidebar-width);
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

/* Header */
.header {
  height: var(--header-height);
  background: white;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  position: sticky;
  top: 0;
  z-index: 30;
  gap: 16px;
}

.header-left  { display: flex; align-items: center; gap: 12px; }
.header-right { display: flex; align-items: center; gap: 8px; }

.header-title {
  font-size: 17px;
  font-weight: 700;
  color: #0f172a;
}

.header-breadcrumb {
  font-size: 13px;
  color: #94a3b8;
}

/* Page content wrapper */
.page-content {
  flex: 1;
  padding: var(--content-padding);
}

/* ================================================================
   KARD KOMPONENTLAR
   ================================================================ */

.card {
  background: white;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  border: 1px solid #f1f5f9;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px 0;
}

.card-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.card-body { padding: 16px 20px 20px; }

/* Stat kard */
.stat-card {
  background: white;
  border-radius: var(--radius-lg);
  padding: 20px;
  border: 1px solid #f1f5f9;
  box-shadow: var(--shadow-sm);
  display: flex;
  align-items: flex-start;
  gap: 14px;
  transition: box-shadow var(--transition-fast);
}

.stat-card:hover { box-shadow: var(--shadow-md); }

.stat-icon {
  width: 46px;
  height: 46px;
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
}

.stat-icon.blue   { background: #dbeafe; }
.stat-icon.green  { background: #dcfce7; }
.stat-icon.yellow { background: #fef3c7; }
.stat-icon.red    { background: #fee2e2; }
.stat-icon.purple { background: #f3e8ff; }
.stat-icon.cyan   { background: #cffafe; }

.stat-body    { flex: 1; }
.stat-label   { font-size: 12px; font-weight: 500; color: #64748b; margin-bottom: 4px; }
.stat-value   { font-size: 26px; font-weight: 800; color: #0f172a; line-height: 1; }
.stat-sub     { font-size: 11px; color: #94a3b8; margin-top: 4px; }

/* ================================================================
   TUGMALAR
   ================================================================ */

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 16px;
  border-radius: var(--radius-md);
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  border: none;
  transition: all var(--transition-fast);
  white-space: nowrap;
  text-decoration: none;
  outline: none;
}

.btn:disabled { opacity: 0.6; cursor: not-allowed; }

.btn-primary {
  background: var(--color-primary);
  color: white;
}
.btn-primary:hover:not(:disabled) { background: var(--color-primary-dark); }

.btn-secondary {
  background: #f1f5f9;
  color: #475569;
}
.btn-secondary:hover:not(:disabled) { background: #e2e8f0; }

.btn-danger {
  background: #fee2e2;
  color: #dc2626;
}
.btn-danger:hover:not(:disabled) { background: #fecaca; }

.btn-success {
  background: #dcfce7;
  color: #16a34a;
}
.btn-success:hover:not(:disabled) { background: #bbf7d0; }

.btn-ghost {
  background: transparent;
  color: #64748b;
}
.btn-ghost:hover:not(:disabled) { background: #f1f5f9; }

.btn-sm { padding: 5px 10px; font-size: 12px; }
.btn-lg { padding: 11px 22px; font-size: 15px; }
.btn-icon { padding: 8px; width: 36px; height: 36px; }

/* ================================================================
   FORMALAR
   ================================================================ */

.form-group { margin-bottom: 16px; }

.form-label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #374151;
  margin-bottom: 6px;
}

.form-label .required { color: #dc2626; margin-left: 3px; }

.form-input,
.form-select,
.form-textarea {
  width: 100%;
  padding: 9px 12px;
  border: 1.5px solid #e2e8f0;
  border-radius: var(--radius-md);
  font-size: 14px;
  font-family: inherit;
  color: #1e293b;
  background: white;
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
  outline: none;
}

.form-input:focus,
.form-select:focus,
.form-textarea:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}

.form-input::placeholder { color: #94a3b8; }

.form-input.error { border-color: #dc2626; }

.form-error {
  font-size: 12px;
  color: #dc2626;
  margin-top: 4px;
}

.form-textarea { resize: vertical; min-height: 80px; }

/* Input guruhi (icon bilan) */
.input-group {
  position: relative;
}

.input-group .input-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  pointer-events: none;
}

.input-group .form-input { padding-left: 38px; }

.input-group .input-icon-right {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  cursor: pointer;
}

/* ================================================================
   JADVALLAR
   ================================================================ */

.table-wrapper {
  overflow-x: auto;
  border-radius: var(--radius-lg);
  border: 1px solid #f1f5f9;
}

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13.5px;
}

.table thead tr {
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.table th {
  padding: 11px 14px;
  text-align: left;
  font-size: 11.5px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #64748b;
  white-space: nowrap;
}

.table td {
  padding: 13px 14px;
  color: #374151;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.table tbody tr {
  transition: background var(--transition-fast);
}

.table tbody tr:hover { background: #fafafa; }

.table tbody tr:last-child td { border-bottom: none; }

.table-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}

/* ================================================================
   STATUS BADGE'LAR
   ================================================================ */

.badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 9px;
  border-radius: 20px;
  font-size: 11.5px;
  font-weight: 600;
  white-space: nowrap;
}

/* Zakaz statuslari */
.badge-new        { background: #f0f9ff; color: #0369a1; border: 1px solid #bae6fd; }
.badge-accepted   { background: #f0fdf4; color: #15803d; border: 1px solid #bbf7d0; }
.badge-diagnosing { background: #fefce8; color: #a16207; border: 1px solid #fde68a; }
.badge-waiting    { background: #fff7ed; color: #c2410c; border: 1px solid #fed7aa; }
.badge-on_the_way { background: #f5f3ff; color: #6d28d9; border: 1px solid #ddd6fe; }
.badge-in_repair  { background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }
.badge-done       { background: #f0fdf4; color: #166534; border: 1px solid #86efac; }
.badge-delivered  { background: #f0fdf4; color: #14532d; border: 1px solid #4ade80; }
.badge-cancelled  { background: #fef2f2; color: #991b1b; border: 1px solid #fca5a5; }

/* Deadline badge'lar */
.deadline-ok       { background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; }
.deadline-warning  { background: #fefce8; color: #d97706; border: 1px solid #fde68a; }
.deadline-critical { background: #fff7ed; color: #ea580c; border: 1px solid #fed7aa; }
.deadline-overdue  {
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fca5a5;
  animation: pulse-border 2s ease infinite;
}

@keyframes pulse-border {
  0%, 100% { border-color: #fca5a5; }
  50%       { border-color: #f87171; box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1); }
}

/* Rol badge'lari */
.badge-admin    { background: #fdf4ff; color: #7e22ce; border: 1px solid #e9d5ff; }
.badge-operator { background: #f0f9ff; color: #0369a1; border: 1px solid #bae6fd; }
.badge-master   { background: #fff7ed; color: #c2410c; border: 1px solid #fed7aa; }

/* ================================================================
   MODAL
   ================================================================ */

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  animation: fadeIn 0.15s ease-out;
}

.modal {
  background: white;
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-modal);
  width: 100%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  animation: slideUp 0.2s ease-out;
}

@keyframes slideUp {
  from { transform: translateY(16px); opacity: 0; }
  to   { transform: translateY(0);    opacity: 1; }
}

.modal-sm  { max-width: 400px; }
.modal-md  { max-width: 560px; }
.modal-lg  { max-width: 720px; }
.modal-xl  { max-width: 900px; }

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 0;
  flex-shrink: 0;
}

.modal-title {
  font-size: 17px;
  font-weight: 700;
  color: #0f172a;
}

.modal-close {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-md);
  border: none;
  background: #f1f5f9;
  color: #64748b;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  transition: all var(--transition-fast);
  flex-shrink: 0;
}

.modal-close:hover { background: #e2e8f0; color: #374151; }

.modal-body {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
}

.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 0 24px 20px;
  flex-shrink: 0;
  border-top: 1px solid #f1f5f9;
  padding-top: 16px;
}

/* ================================================================
   ALERT / OGOHLANTIRISH
   ================================================================ */

.alert {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 16px;
  border-radius: var(--radius-md);
  font-size: 13.5px;
  border: 1px solid transparent;
}

.alert-icon { font-size: 16px; flex-shrink: 0; margin-top: 1px; }
.alert-text { flex: 1; }
.alert-title { font-weight: 600; margin-bottom: 2px; }

.alert-warning {
  background: #fffbeb;
  color: #92400e;
  border-color: #fde68a;
}

.alert-danger {
  background: #fff1f2;
  color: #9f1239;
  border-color: #fecdd3;
}

.alert-info {
  background: #eff6ff;
  color: #1e40af;
  border-color: #bfdbfe;
}

.alert-success {
  background: #f0fdf4;
  color: #14532d;
  border-color: #bbf7d0;
}

/* Overdue signal banner */
.overdue-banner {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 18px;
  background: linear-gradient(135deg, #fef2f2, #fff1f2);
  border: 1px solid #fca5a5;
  border-radius: var(--radius-lg);
  color: #991b1b;
}

.overdue-banner-pulse {
  width: 10px;
  height: 10px;
  background: #dc2626;
  border-radius: 50%;
  animation: ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;
  flex-shrink: 0;
}

@keyframes ping {
  75%, 100% { transform: scale(2); opacity: 0; }
}

/* ================================================================
   LOADER / SPINNER
   ================================================================ */

.spinner {
  width: 20px;
  height: 20px;
  border: 2px solid #e2e8f0;
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
  display: inline-block;
}

@keyframes spin { to { transform: rotate(360deg); } }

.page-loader {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 300px;
  gap: 12px;
  color: #94a3b8;
  font-size: 14px;
}

.page-loader .spinner {
  width: 36px;
  height: 36px;
  border-width: 3px;
}

/* ================================================================
   BO'SH HOLAT
   ================================================================ */

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
  color: #94a3b8;
}

.empty-icon { font-size: 48px; margin-bottom: 12px; opacity: 0.7; }
.empty-title { font-size: 16px; font-weight: 600; color: #64748b; margin-bottom: 6px; }
.empty-text  { font-size: 13.5px; }

/* ================================================================
   SEARCH INPUT
   ================================================================ */

.search-bar {
  position: relative;
  max-width: 300px;
}

.search-bar .search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  font-size: 15px;
}

.search-bar input {
  width: 100%;
  padding: 8px 12px 8px 34px;
  border: 1.5px solid #e2e8f0;
  border-radius: var(--radius-md);
  font-size: 13.5px;
  font-family: inherit;
  color: #374151;
  outline: none;
  transition: border-color var(--transition-fast);
  background: white;
}

.search-bar input:focus { border-color: var(--color-primary); }
.search-bar input::placeholder { color: #94a3b8; }

/* ================================================================
   PAGINATION
   ================================================================ */

.pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  border-top: 1px solid #f1f5f9;
  font-size: 13px;
  color: #64748b;
}

.pagination-btns { display: flex; gap: 4px; }

.pg-btn {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-md);
  border: 1px solid #e2e8f0;
  background: white;
  color: #374151;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--transition-fast);
}

.pg-btn:hover:not(:disabled)  { background: #f8fafc; border-color: #cbd5e1; }
.pg-btn.active { background: var(--color-primary); color: white; border-color: var(--color-primary); }
.pg-btn:disabled { opacity: 0.4; cursor: not-allowed; }

/* ================================================================
   LOGIN SAHIFASI
   ================================================================ */

.login-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  position: relative;
  overflow: hidden;
}

/* Orqa fon animatsiya naqshlari */
.login-bg-circle {
  position: absolute;
  border-radius: 50%;
  background: rgba(37, 99, 235, 0.07);
  animation: float 8s ease-in-out infinite;
}

.login-bg-circle:nth-child(1) { width: 300px; height: 300px; top: -80px;  left: -80px; animation-delay: 0s; }
.login-bg-circle:nth-child(2) { width: 200px; height: 200px; bottom: -60px; right: -60px; animation-delay: 3s; }
.login-bg-circle:nth-child(3) { width: 150px; height: 150px; top: 40%; left: 60%; animation-delay: 1.5s; }

@keyframes float {
  0%, 100% { transform: translateY(0) scale(1); }
  50%       { transform: translateY(-20px) scale(1.05); }
}

.login-card {
  width: 100%;
  max-width: 420px;
  background: white;
  border-radius: var(--radius-2xl);
  box-shadow: var(--shadow-modal);
  padding: 36px 32px;
  position: relative;
  z-index: 1;
  animation: slideUp 0.3s ease-out;
}

.login-header {
  text-align: center;
  margin-bottom: 28px;
}

.login-logo {
  width: 64px;
  height: 64px;
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
  border-radius: var(--radius-xl);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  margin: 0 auto 16px;
  box-shadow: 0 8px 20px rgba(37, 99, 235, 0.35);
}

.login-title {
  font-size: 22px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 4px;
}

.login-subtitle {
  font-size: 13px;
  color: #64748b;
}

/* ================================================================
   DASHBOARD GRID
   ================================================================ */

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.dashboard-grid .full-width { grid-column: 1 / -1; }

@media (max-width: 1100px) {
  .dashboard-grid { grid-template-columns: 1fr; }
}

/* ================================================================
   FILTER BAR
   ================================================================ */

.filter-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 6px 14px;
  border-radius: 20px;
  border: 1.5px solid #e2e8f0;
  background: white;
  font-size: 12.5px;
  font-weight: 600;
  color: #64748b;
  cursor: pointer;
  transition: all var(--transition-fast);
  white-space: nowrap;
}

.filter-btn:hover { border-color: #cbd5e1; background: #f8fafc; }

.filter-btn.active {
  background: var(--color-primary);
  border-color: var(--color-primary);
  color: white;
}

/* ================================================================
   DROPDOWN MENU
   ================================================================ */

.dropdown {
  position: relative;
  display: inline-block;
}

.dropdown-menu {
  position: absolute;
  top: calc(100% + 4px);
  right: 0;
  min-width: 180px;
  background: white;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-xl);
  border: 1px solid #f1f5f9;
  z-index: 100;
  overflow: hidden;
  animation: fadeIn 0.12s ease-out;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  font-size: 13.5px;
  color: #374151;
  cursor: pointer;
  transition: background var(--transition-fast);
}

.dropdown-item:hover { background: #f8fafc; }

.dropdown-item.danger { color: #dc2626; }
.dropdown-item.danger:hover { background: #fef2f2; }

.dropdown-divider { height: 1px; background: #f1f5f9; margin: 4px 0; }

/* ================================================================
   TOOLTIP
   ================================================================ */

[data-tooltip] {
  position: relative;
  cursor: default;
}

[data-tooltip]::after {
  content: attr(data-tooltip);
  position: absolute;
  bottom: calc(100% + 6px);
  left: 50%;
  transform: translateX(-50%);
  background: #0f172a;
  color: white;
  font-size: 11.5px;
  padding: 5px 10px;
  border-radius: var(--radius-sm);
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  transition: opacity var(--transition-fast);
  z-index: 200;
}

[data-tooltip]:hover::after { opacity: 1; }

/* ================================================================
   UTILITY CLASSLAR
   ================================================================ */

.text-truncate {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.flex-center { display: flex; align-items: center; justify-content: center; }
.flex-between { display: flex; align-items: center; justify-content: space-between; }
.flex-gap-2 { display: flex; align-items: center; gap: 8px; }

.divider { height: 1px; background: #f1f5f9; margin: 16px 0; }

.text-muted { color: #94a3b8; }
.text-small { font-size: 12px; }
.font-mono  { font-family: 'Courier New', monospace; }

/* Animatsiyalar */
.animate-fade-in { animation: fadeIn 0.15s ease-out; }

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.97); }
  to   { opacity: 1; transform: scale(1); }
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/api/axiosInstance.js' << 'TVCRM_EOF'
// ================================================
// axiosInstance.js — Markaziy Axios sozlamalari
// Barcha API so'rovlari shu instance orqali o'tadi
// ================================================

import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

const api = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

// ── Request interceptor: tokenni qo'shadi ──────────────────
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// ── Response interceptor: xatolarni markaziy ushlaydi ──────
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;

    // 401 — Token muddati o'tgan yoki noto'g'ri
    if (status === 401) {
      localStorage.removeItem('access_token');
      localStorage.removeItem('user');
      // Login sahifasiga yo'naltirish
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }

    // Xato xabarini standartlashtirish
    const message =
      error.response?.data?.detail ||
      error.response?.data?.message ||
      error.message ||
      'Noma\'lum xato yuz berdi';

    return Promise.reject({ ...error, message });
  },
);

export default api;
TVCRM_EOF

  cat > 'tv-crm/frontend/src/api/authApi.js' << 'TVCRM_EOF'
// ================================================
// authApi.js — Autentifikatsiya API funksiyalari
// POST /auth/login, GET /auth/me, POST /auth/logout
// ================================================

import api from './axiosInstance';

const authApi = {
  // Tizimga kirish
  login: async (username, password) => {
    const { data } = await api.post('/auth/login', { username, password });
    return data;   // { access_token, token_type, expires_in, user }
  },

  // Tizimdan chiqish
  logout: async () => {
    try {
      await api.post('/auth/logout');
    } finally {
      localStorage.removeItem('access_token');
      localStorage.removeItem('user');
    }
  },

  // Joriy foydalanuvchi ma'lumoti
  getMe: async () => {
    const { data } = await api.get('/auth/me');
    return data;
  },

  // Tokenni yangilash
  refreshToken: async () => {
    const { data } = await api.post('/auth/refresh');
    return data;
  },

  // Parolni o'zgartirish
  changePassword: async (currentPassword, newPassword, confirmPassword) => {
    const { data } = await api.post('/auth/change-password', {
      current_password: currentPassword,
      new_password:     newPassword,
      confirm_password: confirmPassword,
    });
    return data;
  },
};

export default authApi;
TVCRM_EOF

  cat > 'tv-crm/frontend/src/api/ordersApi.js' << 'TVCRM_EOF'
// ================================================
// ordersApi.js — Zakazlar API funksiyalari
// ================================================

import api from './axiosInstance';

const ordersApi = {
  // ── Ro'yxat (filter + pagination) ──────────────────────────
  getList: async (params = {}) => {
    // params: { page, page_size, status, master_id, search, is_archived, only_overdue }
    const { data } = await api.get('/orders/', { params });
    return data;   // OrderListResponse
  },

  // ── Bitta zakaz ─────────────────────────────────────────────
  getById: async (id) => {
    const { data } = await api.get(`/orders/${id}`);
    return data;
  },

  // Raqam bo'yicha (TV-2025-0001)
  getByNumber: async (orderNumber) => {
    const { data } = await api.get(`/orders/by-number/${orderNumber}`);
    return data;
  },

  // ── Yaratish ────────────────────────────────────────────────
  create: async (orderData) => {
    const { data } = await api.post('/orders/', orderData);
    return data;
  },

  // ── Yangilash (PATCH) ───────────────────────────────────────
  update: async (id, updateData) => {
    const { data } = await api.patch(`/orders/${id}`, updateData);
    return data;
  },

  // ── Status o'zgartirish ─────────────────────────────────────
  changeStatus: async (id, newStatus, comment = '') => {
    const { data } = await api.post(`/orders/${id}/status`, {
      new_status: newStatus,
      comment:    comment || undefined,
    });
    return data;
  },

  // ── To'lov qabul qilish ─────────────────────────────────────
  acceptPayment: async (id, finalPrice, paymentMethod, comment = '') => {
    const { data } = await api.post(`/orders/${id}/payment`, {
      final_price:    finalPrice,
      payment_method: paymentMethod,
      comment:        comment || undefined,
    });
    return data;
  },

  // ── Arxivlash ───────────────────────────────────────────────
  archive: async (id) => {
    const { data } = await api.post(`/orders/${id}/archive`);
    return data;
  },

  // ── Statistika (Dashboard) ──────────────────────────────────
  getStats: async () => {
    const { data } = await api.get('/orders/stats');
    return data;
  },

  // ── Deadline ogohlantirishlari ──────────────────────────────
  getDeadlineAlerts: async (warningHours = 24) => {
    const { data } = await api.get('/orders/alerts/deadline', {
      params: { warning_hours: warningHours },
    });
    return data;   // OrderDeadlineAlertResponse[]
  },
};

export default ordersApi;
TVCRM_EOF

  cat > 'tv-crm/frontend/src/api/workersApi.js' << 'TVCRM_EOF'
// ================================================
// workersApi.js — Ishchilar API funksiyalari
// ================================================

import api from './axiosInstance';

const workersApi = {
  // ── Ro'yxat ─────────────────────────────────────────────────
  getList: async (params = {}) => {
    // params: { role, is_active, page, page_size }
    const { data } = await api.get('/workers/', { params });
    return data;   // WorkerListResponse
  },

  // ── Bitta ishchi ────────────────────────────────────────────
  getById: async (id) => {
    const { data } = await api.get(`/workers/${id}`);
    return data;
  },

  // ── Yaratish [Admin] ────────────────────────────────────────
  create: async (workerData) => {
    const { data } = await api.post('/workers/', workerData);
    return data;
  },

  // ── Yangilash [Admin] ───────────────────────────────────────
  update: async (id, updateData) => {
    const { data } = await api.patch(`/workers/${id}`, updateData);
    return data;
  },

  // ── Bloklash / Faollashtirish [Admin] ───────────────────────
  deactivate: async (id) => {
    const { data } = await api.delete(`/workers/${id}`);
    return data;
  },

  activate: async (id) => {
    const { data } = await api.post(`/workers/${id}/activate`);
    return data;
  },

  // ── Balans tarixi ───────────────────────────────────────────
  getBalanceHistory: async (id) => {
    const { data } = await api.get(`/workers/${id}/balance`);
    return data;
  },

  // ── O'z balansi (Usta uchun) ─────────────────────────────────
  getMyBalance: async () => {
    const { data } = await api.get('/workers/me/balance');
    return data;
  },

  // ── Ish haqi to'lash [Admin] ────────────────────────────────
  paySalary: async (id, amount, paymentMethod, notes = '') => {
    const { data } = await api.post(`/workers/${id}/salary`, {
      amount,
      payment_method: paymentMethod,
      notes: notes || undefined,
    });
    return data;
  },

  // ── Balans tuzatish [Admin] ─────────────────────────────────
  adjustBalance: async (id, amount, reason) => {
    const { data } = await api.post(`/workers/${id}/balance/adjust`, {
      amount,
      reason,
    });
    return data;
  },

  // ── Moliyaviy xulosa [Admin] ────────────────────────────────
  getFinanceSummary: async () => {
    const { data } = await api.get('/workers/summary');
    return data;
  },
};

export default workersApi;
TVCRM_EOF

  cat > 'tv-crm/frontend/src/store/authStore.js' << 'TVCRM_EOF'
// ================================================
// authStore.js — Zustand autentifikatsiya store
// Login, logout, token va user holati saqlanadi
// ================================================

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import authApi from '@/api/authApi';

const useAuthStore = create(
  persist(
    (set, get) => ({
      // ── Holat ────────────────────────────────────────────────
      user:        null,    // { id, username, full_name, role, balance, ... }
      token:       null,    // JWT string
      isLoading:   false,
      error:       null,
      isLoggedIn:  false,

      // ── Login ────────────────────────────────────────────────
      login: async (username, password) => {
        set({ isLoading: true, error: null });
        try {
          const data = await authApi.login(username, password);

          // Token va user'ni localStorage + state ga saqlash
          localStorage.setItem('access_token', data.access_token);
          localStorage.setItem('user', JSON.stringify(data.user));

          set({
            user:       data.user,
            token:      data.access_token,
            isLoggedIn: true,
            isLoading:  false,
            error:      null,
          });

          return { success: true, user: data.user };
        } catch (err) {
          const message = err.message || 'Login amalga oshmadi';
          set({ isLoading: false, error: message, isLoggedIn: false });
          return { success: false, error: message };
        }
      },

      // ── Logout ───────────────────────────────────────────────
      logout: async () => {
        try { await authApi.logout(); } catch (_) {}
        localStorage.removeItem('access_token');
        localStorage.removeItem('user');
        set({ user: null, token: null, isLoggedIn: false, error: null });
      },

      // ── Profilni yangilash ───────────────────────────────────
      refreshUser: async () => {
        try {
          const user = await authApi.getMe();
          set({ user });
          localStorage.setItem('user', JSON.stringify(user));
        } catch (_) {}
      },

      // ── Xatoni tozalash ──────────────────────────────────────
      clearError: () => set({ error: null }),

      // ── Ruxsatlarni tekshirish ───────────────────────────────
      isAdmin:    () => get().user?.role === 'admin',
      isOperator: () => get().user?.role === 'operator',
      isMaster:   () => get().user?.role === 'master',
      isAdminOrOperator: () =>
        ['admin', 'operator'].includes(get().user?.role),
    }),
    {
      name:    'tv-crm-auth',          // localStorage key
      partialize: (state) => ({        // Faqat shu maydonlar saqlanadi
        user:       state.user,
        token:      state.token,
        isLoggedIn: state.isLoggedIn,
      }),
    },
  ),
);

export default useAuthStore;
TVCRM_EOF

  cat > 'tv-crm/frontend/src/store/orderStore.js' << 'TVCRM_EOF'
// ================================================
// orderStore.js — Zakazlar global holati
// ================================================

import { create } from 'zustand';
import ordersApi from '@/api/ordersApi';

const useOrderStore = create((set, get) => ({
  // ── Holat ────────────────────────────────────────────────────
  orders:         [],
  total:          0,
  totalPages:     1,
  currentPage:    1,
  overdueCount:   0,
  stats:          null,
  deadlineAlerts: [],
  isLoading:      false,
  error:          null,

  // Aktiv filterlar
  filters: {
    status:       '',
    search:       '',
    only_overdue: false,
    is_archived:  false,
    page:         1,
    page_size:    20,
  },

  // ── Ro'yxatni yuklash ────────────────────────────────────────
  fetchOrders: async (extraFilters = {}) => {
    set({ isLoading: true, error: null });
    try {
      const filters = { ...get().filters, ...extraFilters };
      // Bo'sh qiymatlarni olib tashlash
      const params = Object.fromEntries(
        Object.entries(filters).filter(([, v]) => v !== '' && v !== false && v != null)
      );
      const data = await ordersApi.getList(params);
      set({
        orders:       data.items,
        total:        data.total,
        totalPages:   data.total_pages,
        currentPage:  data.page,
        overdueCount: data.overdue_count,
        isLoading:    false,
        filters,
      });
    } catch (err) {
      set({ isLoading: false, error: err.message });
    }
  },

  // ── Filterlarni o'zgartirish ─────────────────────────────────
  setFilter: (key, value) => {
    set((s) => ({
      filters: { ...s.filters, [key]: value, page: 1 },
    }));
  },

  setPage: (page) => {
    set((s) => ({ filters: { ...s.filters, page } }));
  },

  // ── Statistika ────────────────────────────────────────────────
  fetchStats: async () => {
    try {
      const stats = await ordersApi.getStats();
      set({ stats });
    } catch (_) {}
  },

  // ── Deadline alertlar ─────────────────────────────────────────
  fetchDeadlineAlerts: async () => {
    try {
      const alerts = await ordersApi.getDeadlineAlerts(24);
      set({ deadlineAlerts: alerts });
    } catch (_) {}
  },

  // ── Zakaz statusini o'zgartirish ──────────────────────────────
  changeStatus: async (id, newStatus, comment) => {
    try {
      const updated = await ordersApi.changeStatus(id, newStatus, comment);
      // Ro'yxatdagi zakazni yangilash
      set((s) => ({
        orders: s.orders.map((o) => (o.id === id ? updated : o)),
      }));
      return { success: true, data: updated };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  // ── Xatoni tozalash ───────────────────────────────────────────
  clearError: () => set({ error: null }),
}));

export default useOrderStore;
TVCRM_EOF

  cat > 'tv-crm/frontend/src/utils/formatters.js' << 'TVCRM_EOF'
// ================================================
// formatters.js — Formatlash yordamchi funksiyalari
// Sana, pul, status matnlari
// ================================================

import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/uz';

dayjs.extend(relativeTime);
dayjs.locale('uz');

// ================================================================
//  PUL FORMATLASH
// ================================================================

/**
 * Sonni pul formatida ko'rsatadi
 * formatMoney(1500000) → "1 500 000 so'm"
 */
export const formatMoney = (amount, currency = "so'm") => {
  if (amount == null || isNaN(amount)) return `0 ${currency}`;
  return (
    Number(amount)
      .toLocaleString('uz-UZ', { maximumFractionDigits: 0 })
      .replace(/,/g, ' ') +
    ` ${currency}`
  );
};

/**
 * Qisqa format: 1500000 → "1.5M" yoki "1 500 000"
 */
export const formatMoneyShort = (amount) => {
  if (!amount) return "0";
  if (amount >= 1_000_000)
    return `${(amount / 1_000_000).toFixed(1)}M so'm`;
  if (amount >= 1_000)
    return `${(amount / 1_000).toFixed(0)}K so'm`;
  return `${amount} so'm`;
};

// ================================================================
//  SANA VA VAQT FORMATLASH
// ================================================================

/**
 * Standart sana-vaqt formati
 * formatDate("2025-06-15T14:30:00") → "15-iyun 2025, 14:30"
 */
export const formatDate = (dateStr) => {
  if (!dateStr) return '—';
  const months = [
    'yan', 'fev', 'mar', 'apr', 'may', 'iyun',
    'iyul', 'avg', 'sen', 'okt', 'noy', 'dek',
  ];
  const d = dayjs(dateStr);
  if (!d.isValid()) return '—';
  return `${d.date()}-${months[d.month()]} ${d.year()}, ${d.format('HH:mm')}`;
};

/**
 * Faqat sana
 * formatDateOnly("2025-06-15T14:30:00") → "15.06.2025"
 */
export const formatDateOnly = (dateStr) => {
  if (!dateStr) return '—';
  return dayjs(dateStr).format('DD.MM.YYYY');
};

/**
 * Qancha vaqt avval / keyin
 * formatRelative("2025-06-14T10:00:00") → "2 soat avval"
 */
export const formatRelative = (dateStr) => {
  if (!dateStr) return '—';
  return dayjs(dateStr).fromNow();
};

/**
 * Deadline uchun maxsus format — qolgan vaqtni ko'rsatadi
 * formatDeadline(iso, hours_remaining)
 * → { label, className, icon, isOverdue }
 */
export const formatDeadline = (deadlineStr, hoursRemaining) => {
  if (!deadlineStr) return { label: '—', className: '', icon: '', isOverdue: false };

  const h = hoursRemaining ?? 999;
  const isOverdue = h < 0;
  const absH = Math.abs(h);

  let label, className, icon;

  if (isOverdue) {
    const overdueH = absH;
    if (overdueH < 1)
      label = `${Math.round(overdueH * 60)} daq. o'tdi`;
    else if (overdueH < 24)
      label = `${overdueH.toFixed(0)} soat o'tdi`;
    else
      label = `${(overdueH / 24).toFixed(0)} kun o'tdi`;
    className = 'deadline-overdue';
    icon = '❌';
  } else if (h <= 2) {
    label = `${Math.round(h * 60)} daqiqa`;
    className = 'deadline-critical';
    icon = '🔴';
  } else if (h <= 24) {
    label = `${h.toFixed(0)} soat`;
    className = 'deadline-warning';
    icon = '⚠️';
  } else {
    const days = h / 24;
    label = days >= 1 ? `${days.toFixed(0)} kun` : `${h.toFixed(0)} soat`;
    className = 'deadline-ok';
    icon = '✅';
  }

  return { label, className, icon, isOverdue };
};

// ================================================================
//  STATUS TARJIMALARI
// ================================================================

export const ORDER_STATUS_LABELS = {
  new:         'Yangi',
  accepted:    'Qabul qilindi',
  diagnosing:  'Diagnostika',
  waiting:     'Kutilmoqda',
  on_the_way:  'Yo\'lda',
  in_repair:   'Ta\'mirda',
  done:        'Tayyor',
  delivered:   'Topshirildi',
  cancelled:   'Bekor qilindi',
};

export const ORDER_STATUS_COLORS = {
  new:         'badge-new',
  accepted:    'badge-accepted',
  diagnosing:  'badge-diagnosing',
  waiting:     'badge-waiting',
  on_the_way:  'badge-on_the_way',
  in_repair:   'badge-in_repair',
  done:        'badge-done',
  delivered:   'badge-delivered',
  cancelled:   'badge-cancelled',
};

export const ORDER_STATUS_ICONS = {
  new:         '🆕',
  accepted:    '✅',
  diagnosing:  '🔍',
  waiting:     '⏳',
  on_the_way:  '🚗',
  in_repair:   '🔧',
  done:        '✔️',
  delivered:   '🎉',
  cancelled:   '❌',
};

export const ROLE_LABELS = {
  admin:    'Admin',
  operator: 'Operator',
  master:   'Usta',
};

export const ROLE_COLORS = {
  admin:    'badge-admin',
  operator: 'badge-operator',
  master:   'badge-master',
};

export const PAYMENT_METHOD_LABELS = {
  cash:     'Naqd',
  card:     'Karta',
  transfer: "O'tkazma",
};

export const ORDER_SOURCE_LABELS = {
  walk_in:   'Bevosita',
  phone:     'Telefon',
  telegram:  'Telegram',
  instagram: 'Instagram',
  other:     'Boshqa',
};

// ================================================================
//  STATUS O'TISH (TRANSITIONS) — Frontend uchun
// ================================================================

export const ALLOWED_TRANSITIONS = {
  new:        ['accepted', 'cancelled'],
  accepted:   ['diagnosing', 'on_the_way', 'cancelled'],
  diagnosing: ['waiting', 'in_repair', 'on_the_way', 'cancelled'],
  waiting:    ['in_repair', 'on_the_way', 'cancelled'],
  on_the_way: ['in_repair', 'accepted', 'diagnosing', 'cancelled'],
  in_repair:  ['done', 'waiting', 'on_the_way', 'cancelled'],
  done:       ['delivered', 'cancelled'],
  delivered:  [],
  cancelled:  [],
};

/**
 * Berilgan statusdan o'tish mumkin bo'lgan statuslar ro'yxati
 */
export const getAllowedNextStatuses = (currentStatus) => {
  return (ALLOWED_TRANSITIONS[currentStatus] || []).map((s) => ({
    value: s,
    label: ORDER_STATUS_LABELS[s],
    icon:  ORDER_STATUS_ICONS[s],
  }));
};

// ================================================================
//  QISQARTIRISH
// ================================================================

/**
 * Uzun matnni qisqartiradi
 * truncate("Ekran yonmayapti...", 30) → "Ekran yonmayapti..."
 */
export const truncate = (str, maxLen = 40) => {
  if (!str) return '—';
  return str.length > maxLen ? str.slice(0, maxLen) + '…' : str;
};

/**
 * Ism-familiyadan bosh harflarni oladi
 * getInitials("Sardor Toshmatov") → "ST"
 */
export const getInitials = (name) => {
  if (!name) return '?';
  return name
    .split(' ')
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() || '')
    .join('');
};

/**
 * TV ma'lumotlarini bitta qatorda chiqaradi
 * formatTvInfo({ tv_brand, tv_model, tv_diagonal }) → "Samsung UA55TU8000 55\""
 */
export const formatTvInfo = (order) => {
  const parts = [order?.tv_brand, order?.tv_model, order?.tv_diagonal].filter(Boolean);
  return parts.join(' ') || 'TV ma\'lumoti yo\'q';
};

/**
 * Telefon raqamni formatlaydi
 * formatPhone("+998901234567") → "+998 90 123 45 67"
 */
export const formatPhone = (phone) => {
  if (!phone) return '—';
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('998') && cleaned.length === 12) {
    return `+998 ${cleaned.slice(3, 5)} ${cleaned.slice(5, 8)} ${cleaned.slice(8, 10)} ${cleaned.slice(10)}`;
  }
  return phone;
};
TVCRM_EOF

  cat > 'tv-crm/frontend/src/utils/hooks.js' << 'TVCRM_EOF'
// ================================================
// hooks.js — Qayta ishlatiladigan React Hook'lar
// ================================================

import { useState, useEffect, useCallback, useRef } from 'react';

// ── Debounce hook (qidiruv uchun) ───────────────────────────────
export const useDebounce = (value, delay = 400) => {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debounced;
};

// ── Modal holati hook ───────────────────────────────────────────
export const useModal = (initial = false) => {
  const [isOpen, setIsOpen] = useState(initial);
  const [data, setData] = useState(null);

  const open  = useCallback((payload = null) => { setData(payload); setIsOpen(true);  }, []);
  const close = useCallback(() => { setIsOpen(false); setData(null); }, []);

  // ESC tugmasi bilan yopish
  useEffect(() => {
    if (!isOpen) return;
    const handler = (e) => { if (e.key === 'Escape') close(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [isOpen, close]);

  return { isOpen, data, open, close };
};

// ── Polling hook (avtomatik yangilash) ──────────────────────────
export const usePolling = (fn, intervalMs = 30000, enabled = true) => {
  useEffect(() => {
    if (!enabled) return;
    fn(); // Darhol chaqirish
    const id = setInterval(fn, intervalMs);
    return () => clearInterval(id);
  }, [fn, intervalMs, enabled]);
};

// ── Click outside hook (dropdown/modal yopish) ─────────────────
export const useClickOutside = (handler) => {
  const ref = useRef(null);
  useEffect(() => {
    const listener = (e) => {
      if (!ref.current || ref.current.contains(e.target)) return;
      handler();
    };
    document.addEventListener('mousedown', listener);
    return () => document.removeEventListener('mousedown', listener);
  }, [handler]);
  return ref;
};

// ── Local storage hook ──────────────────────────────────────────
export const useLocalStorage = (key, initialValue) => {
  const [value, setValue] = useState(() => {
    try {
      const item = localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch { return initialValue; }
  });

  const setStored = useCallback((newValue) => {
    try {
      setValue(newValue);
      localStorage.setItem(key, JSON.stringify(newValue));
    } catch {}
  }, [key]);

  return [value, setStored];
};

// ── Sahifa sarlavhasi hook ───────────────────────────────────────
export const usePageTitle = (title) => {
  useEffect(() => {
    document.title = title ? `${title} — TV CRM` : 'TV CRM';
    return () => { document.title = 'TV CRM'; };
  }, [title]);
};

// ── Async holat hook (loading/error/data) ───────────────────────
export const useAsync = (asyncFn, immediate = true) => {
  const [state, setState] = useState({
    data:      null,
    isLoading: immediate,
    error:     null,
  });

  const execute = useCallback(async (...args) => {
    setState((s) => ({ ...s, isLoading: true, error: null }));
    try {
      const data = await asyncFn(...args);
      setState({ data, isLoading: false, error: null });
      return data;
    } catch (err) {
      setState((s) => ({ ...s, isLoading: false, error: err.message }));
      throw err;
    }
  }, [asyncFn]);

  useEffect(() => {
    if (immediate) execute();
  }, []); // eslint-disable-line

  return { ...state, execute };
};
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/Layout/MainLayout.jsx' << 'TVCRM_EOF'
// ================================================
// MainLayout.jsx — Asosiy sahifa tuzilishi
// Sidebar + Header + sahifa kontenti
// ================================================

import { useEffect } from 'react';
import { useLocation, Navigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import useOrderStore from '@/store/orderStore';
import { usePolling } from '@/utils/hooks';
import Sidebar from './Sidebar';
import Header  from './Header';

export default function MainLayout({ children }) {
  const location  = useLocation();
  const { isLoggedIn } = useAuthStore();
  const { fetchDeadlineAlerts, fetchStats } = useOrderStore();

  // Tizimga kirmagan bo'lsa login sahifasiga yo'naltir
  if (!isLoggedIn) {
    return <Navigate to="/login" replace />;
  }

  // Deadline alertlarni har 60 sekundda avtomatik yangilash
  usePolling(fetchDeadlineAlerts, 60_000, true);

  // Statistikani yuklash (sahifa o'zgarganda)
  useEffect(() => {
    fetchStats();
  }, [location.pathname]);

  return (
    <div className="app-layout">
      <Sidebar />
      <div className="main-content">
        <Header pathname={location.pathname} />
        <main className="page-content animate-fade-in">
          {children}
        </main>
      </div>
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/Layout/Sidebar.jsx' << 'TVCRM_EOF'
// ================================================
// Sidebar.jsx — Chap panel navigatsiya
// ================================================

import { NavLink, useNavigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import { getInitials, ROLE_LABELS } from '@/utils/formatters';
import useOrderStore from '@/store/orderStore';

// Nav elementlari konfiguratsiyasi
const NAV_ITEMS = [
  {
    section: 'Asosiy',
    items: [
      { to: '/dashboard', icon: '📊', label: 'Dashboard' },
      { to: '/orders',    icon: '📋', label: 'Zakazlar',  badgeKey: 'overdueCount' },
    ],
  },
  {
    section: 'Boshqaruv',
    items: [
      { to: '/workers',   icon: '👷', label: 'Ishchilar',  adminOnly: true },
      { to: '/clients',   icon: '👥', label: 'Mijozlar' },
      { to: '/warehouse', icon: '🏪', label: 'Ombor',      adminOnly: true },
      { to: '/finance',   icon: '💰', label: 'Moliya',     adminOnly: true },
    ],
  },
  {
    section: 'Arxiv',
    items: [
      { to: '/archive',   icon: '📦', label: 'Arxiv' },
    ],
  },
];

export default function Sidebar() {
  const navigate    = useNavigate();
  const { user, logout, isAdmin } = useAuthStore();
  const { overdueCount } = useOrderStore();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const roleLabel = ROLE_LABELS[user?.role] || user?.role;
  const initials  = getInitials(user?.full_name);

  return (
    <aside className="sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="sidebar-logo-icon">📺</div>
        <div className="sidebar-logo-text">
          <div className="sidebar-logo-title">TV CRM</div>
          <div className="sidebar-logo-sub">Boshqaruv tizimi</div>
        </div>
      </div>

      {/* Navigatsiya */}
      <nav className="sidebar-nav">
        {NAV_ITEMS.map((section) => {
          // Admin-only elementlarni filtr
          const visibleItems = section.items.filter(
            (item) => !item.adminOnly || isAdmin()
          );
          if (!visibleItems.length) return null;

          return (
            <div key={section.section}>
              <div className="nav-section-label">{section.section}</div>
              {visibleItems.map((item) => {
                const badge = item.badgeKey === 'overdueCount' ? overdueCount : 0;
                return (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    className={({ isActive }) =>
                      `nav-item${isActive ? ' active' : ''}`
                    }
                  >
                    <span className="nav-icon">{item.icon}</span>
                    <span style={{ flex: 1 }}>{item.label}</span>
                    {badge > 0 && (
                      <span className="nav-badge">{badge > 99 ? '99+' : badge}</span>
                    )}
                  </NavLink>
                );
              })}
            </div>
          );
        })}
      </nav>

      {/* Footer — foydalanuvchi */}
      <div className="sidebar-footer">
        <div className="sidebar-user" onClick={handleLogout} title="Tizimdan chiqish">
          <div className="sidebar-avatar">{initials}</div>
          <div className="sidebar-user-info">
            <div className="sidebar-user-name">{user?.full_name || 'Foydalanuvchi'}</div>
            <div className="sidebar-user-role">{roleLabel} · Chiqish</div>
          </div>
          <span style={{ color: '#475569', fontSize: 14 }}>→</span>
        </div>
      </div>
    </aside>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/Layout/Header.jsx' << 'TVCRM_EOF'
// ================================================
// Header.jsx — Yuqori panel
// Sahifa sarlavhasi, qidiruv, bildirishnomalar
// ================================================

import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import useOrderStore from '@/store/orderStore';
import { useClickOutside } from '@/utils/hooks';
import { formatMoney } from '@/utils/formatters';

// Sahifa sarlavhalari
const PAGE_TITLES = {
  '/dashboard': { title: 'Dashboard',   icon: '📊' },
  '/orders':    { title: 'Zakazlar',    icon: '📋' },
  '/workers':   { title: 'Ishchilar',   icon: '👷' },
  '/clients':   { title: 'Mijozlar',    icon: '👥' },
  '/warehouse': { title: 'Ombor',       icon: '🏪' },
  '/finance':   { title: 'Moliya',      icon: '💰' },
  '/archive':   { title: 'Arxiv',       icon: '📦' },
};

export default function Header({ pathname }) {
  const navigate  = useNavigate();
  const { user, logout, isAdmin } = useAuthStore();
  const { overdueCount, deadlineAlerts } = useOrderStore();

  const [showNotif,   setShowNotif]   = useState(false);
  const [showProfile, setShowProfile] = useState(false);

  const notifRef   = useClickOutside(() => setShowNotif(false));
  const profileRef = useClickOutside(() => setShowProfile(false));

  const pageInfo = PAGE_TITLES[pathname] || { title: 'Sahifa', icon: '📄' };

  const handleLogout = useCallback(async () => {
    await logout();
    navigate('/login');
  }, [logout, navigate]);

  return (
    <header className="header">
      {/* Chap: sahifa nomi */}
      <div className="header-left">
        <span style={{ fontSize: 20 }}>{pageInfo.icon}</span>
        <h1 className="header-title">{pageInfo.title}</h1>

        {/* Overdue badge */}
        {overdueCount > 0 && (
          <span
            className="badge deadline-overdue"
            style={{ cursor: 'pointer' }}
            onClick={() => navigate('/orders?only_overdue=true')}
          >
            🔴 {overdueCount} ta muddati o'tgan
          </span>
        )}
      </div>

      {/* O'ng: amallar */}
      <div className="header-right">

        {/* Balans (faqat admin) */}
        {isAdmin() && user?.balance !== undefined && (
          <div
            style={{
              padding: '6px 14px',
              background: '#f0fdf4',
              border: '1px solid #bbf7d0',
              borderRadius: 20,
              fontSize: 13,
              fontWeight: 600,
              color: '#16a34a',
              cursor: 'pointer',
            }}
            onClick={() => navigate('/finance')}
            title="Moliya sahifasiga o'tish"
          >
            💰 {formatMoney(user.balance)}
          </div>
        )}

        {/* Bildirishnomalar */}
        <div ref={notifRef} className="dropdown">
          <button
            className="btn btn-ghost btn-icon"
            style={{ position: 'relative' }}
            onClick={() => { setShowNotif((p) => !p); setShowProfile(false); }}
            title="Bildirishnomalar"
          >
            🔔
            {overdueCount > 0 && (
              <span
                style={{
                  position: 'absolute', top: 4, right: 4,
                  width: 8, height: 8,
                  background: '#dc2626', borderRadius: '50%',
                  border: '1.5px solid white',
                }}
              />
            )}
          </button>

          {showNotif && (
            <div className="dropdown-menu" style={{ width: 320 }}>
              <div style={{ padding: '12px 14px 8px', borderBottom: '1px solid #f1f5f9' }}>
                <span style={{ fontWeight: 700, fontSize: 14 }}>
                  Bildirishnomalar
                </span>
                {overdueCount > 0 && (
                  <span
                    className="badge deadline-overdue"
                    style={{ marginLeft: 8, fontSize: 11 }}
                  >
                    {overdueCount} ta
                  </span>
                )}
              </div>

              <div style={{ maxHeight: 280, overflowY: 'auto' }}>
                {deadlineAlerts.length === 0 ? (
                  <div style={{ padding: '20px 14px', textAlign: 'center', color: '#94a3b8', fontSize: 13 }}>
                    Bildirishnomalar yo'q ✅
                  </div>
                ) : (
                  deadlineAlerts.slice(0, 8).map((alert) => (
                    <div
                      key={alert.order_id}
                      className="dropdown-item"
                      style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 2 }}
                      onClick={() => {
                        navigate(`/orders`);
                        setShowNotif(false);
                      }}
                    >
                      <div style={{ fontWeight: 600, fontSize: 13 }}>
                        {alert.is_overdue ? '❌' : '⚠️'} {alert.order_number}
                      </div>
                      <div style={{ fontSize: 12, color: '#64748b' }}>
                        {alert.client_name} · {alert.tv_info}
                      </div>
                      <div
                        style={{
                          fontSize: 11,
                          color: alert.is_overdue ? '#dc2626' : '#d97706',
                          fontWeight: 600,
                        }}
                      >
                        {alert.is_overdue
                          ? `${Math.abs(alert.hours_remaining).toFixed(0)} soat oldin o'tdi`
                          : `${alert.hours_remaining.toFixed(0)} soat qoldi`}
                      </div>
                    </div>
                  ))
                )}
              </div>

              {deadlineAlerts.length > 0 && (
                <div
                  style={{
                    padding: '10px 14px',
                    borderTop: '1px solid #f1f5f9',
                    textAlign: 'center',
                  }}
                >
                  <button
                    className="btn btn-ghost btn-sm"
                    style={{ width: '100%', justifyContent: 'center' }}
                    onClick={() => { navigate('/orders?only_overdue=true'); setShowNotif(false); }}
                  >
                    Barchasini ko'rish →
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Profil */}
        <div ref={profileRef} className="dropdown">
          <button
            className="btn btn-ghost"
            style={{ padding: '4px 8px', gap: 8 }}
            onClick={() => { setShowProfile((p) => !p); setShowNotif(false); }}
          >
            <div
              style={{
                width: 30, height: 30, borderRadius: '50%',
                background: '#2563eb', color: 'white',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 12, fontWeight: 700,
              }}
            >
              {user?.full_name?.[0]?.toUpperCase() || 'U'}
            </div>
            <span style={{ fontSize: 13, fontWeight: 600, color: '#374151' }}>
              {user?.full_name?.split(' ')[0] || 'Foydalanuvchi'}
            </span>
            <span style={{ fontSize: 11, color: '#94a3b8' }}>▾</span>
          </button>

          {showProfile && (
            <div className="dropdown-menu">
              <div
                style={{
                  padding: '10px 14px 8px',
                  borderBottom: '1px solid #f1f5f9',
                }}
              >
                <div style={{ fontWeight: 600, fontSize: 13 }}>{user?.full_name}</div>
                <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 2 }}>
                  @{user?.username} · {user?.role}
                </div>
              </div>
              <div
                className="dropdown-item"
                onClick={() => { navigate('/dashboard'); setShowProfile(false); }}
              >
                📊 Dashboard
              </div>
              <div className="dropdown-divider" />
              <div className="dropdown-item danger" onClick={handleLogout}>
                🚪 Tizimdan chiqish
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/Orders/NewOrderModal.jsx' << 'TVCRM_EOF'
// ================================================
// NewOrderModal.jsx — Yangi zakaz qo'shish modali
// ================================================

import { useState, useEffect } from 'react';
import ordersApi  from '@/api/ordersApi';
import workersApi from '@/api/workersApi';
import { ORDER_SOURCE_LABELS } from '@/utils/formatters';
import toast from 'react-hot-toast';

const SOURCES = Object.entries(ORDER_SOURCE_LABELS);
const TV_BRANDS = ['Samsung', 'LG', 'Sony', 'Philips', 'TCL', 'Hisense', 'Artel', 'Boshqa'];

// Bugundan N kun keyingi datetime-local qiymat
const defaultDeadline = (daysAhead = 3) => {
  const d = new Date();
  d.setDate(d.getDate() + daysAhead);
  d.setHours(18, 0, 0, 0);
  return d.toISOString().slice(0, 16);
};

export default function NewOrderModal({ onClose, onCreated }) {
  const [masters,  setMasters]  = useState([]);
  const [saving,   setSaving]   = useState(false);
  const [errors,   setErrors]   = useState({});

  const [form, setForm] = useState({
    // Mijoz
    client_name:  '',
    client_phone: '',
    // TV
    tv_brand:         '',
    tv_model:         '',
    tv_diagonal:      '',
    tv_serial_number: '',
    // Zakaz
    problem_description: '',
    source:              'walk_in',
    estimated_price:     '',
    master_id:           '',
    // Deadline — MAJBURIY
    deadline: defaultDeadline(3),
  });

  // Ustalar ro'yxatini yuklash
  useEffect(() => {
    workersApi.getList({ role: 'master', is_active: true, page_size: 50 })
      .then((d) => setMasters(d.items || []))
      .catch(() => {});
  }, []);

  const set = (field, value) => {
    setForm((p) => ({ ...p, [field]: value }));
    if (errors[field]) setErrors((p) => ({ ...p, [field]: '' }));
  };

  // ── Validatsiya ─────────────────────────────────────────────
  const validate = () => {
    const e = {};
    if (!form.client_name.trim())          e.client_name  = 'Mijoz ismi kiritilishi shart';
    if (!form.problem_description.trim() || form.problem_description.length < 5)
      e.problem_description = "Nosozlik tavsifi kamida 5 ta belgi bo'lishi kerak";
    if (!form.deadline)                    e.deadline     = 'Deadline kiritilishi shart';
    else {
      const dl = new Date(form.deadline);
      if (dl <= new Date())                e.deadline     = "Deadline o'tgan vaqt bo'lishi mumkin emas";
    }
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  // ── Saqlash ──────────────────────────────────────────────────
  const handleSave = async () => {
    if (!validate()) return;
    setSaving(true);
    try {
      const payload = {
        client_name:         form.client_name.trim(),
        client_phone:        form.client_phone.trim() || undefined,
        tv_brand:            form.tv_brand || undefined,
        tv_model:            form.tv_model.trim() || undefined,
        tv_diagonal:         form.tv_diagonal.trim() || undefined,
        tv_serial_number:    form.tv_serial_number.trim() || undefined,
        problem_description: form.problem_description.trim(),
        source:              form.source,
        estimated_price:     parseFloat(form.estimated_price) || 0,
        master_id:           form.master_id ? parseInt(form.master_id) : undefined,
        deadline:            new Date(form.deadline).toISOString(),
      };
      const created = await ordersApi.create(payload);
      toast.success(`✅ Zakaz yaratildi: ${created.order_number}`);
      onCreated?.(created);
      onClose();
    } catch (err) {
      toast.error(err.message || 'Zakaz yaratishda xato');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal modal-lg">
        {/* Header */}
        <div className="modal-header">
          <h2 className="modal-title">📋 Yangi Zakaz</h2>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>

        {/* Body */}
        <div className="modal-body">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 20px' }}>

            {/* ── Mijoz ma'lumotlari ─────────────────────────── */}
            <div style={{ gridColumn: '1 / -1' }}>
              <div style={{
                fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
                letterSpacing: '0.06em', color: '#64748b', marginBottom: 12,
              }}>
                👤 Mijoz ma'lumotlari
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">
                Ismi-familiyasi <span className="required">*</span>
              </label>
              <input
                className={`form-input${errors.client_name ? ' error' : ''}`}
                placeholder="Alisher Karimov"
                value={form.client_name}
                onChange={(e) => set('client_name', e.target.value)}
              />
              {errors.client_name && <div className="form-error">{errors.client_name}</div>}
            </div>

            <div className="form-group">
              <label className="form-label">Telefon raqami</label>
              <input
                className="form-input"
                placeholder="+998 90 123 45 67"
                value={form.client_phone}
                onChange={(e) => set('client_phone', e.target.value)}
              />
            </div>

            {/* ── Televizor ma'lumotlari ─────────────────────── */}
            <div style={{ gridColumn: '1 / -1', marginTop: 8 }}>
              <div style={{
                fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
                letterSpacing: '0.06em', color: '#64748b', marginBottom: 12,
              }}>
                📺 Televizor ma'lumotlari
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Brand</label>
              <select
                className="form-select"
                value={form.tv_brand}
                onChange={(e) => set('tv_brand', e.target.value)}
              >
                <option value="">— Brand tanlang —</option>
                {TV_BRANDS.map((b) => (
                  <option key={b} value={b === 'Boshqa' ? '' : b}>{b}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Model</label>
              <input
                className="form-input"
                placeholder="UA55TU8000"
                value={form.tv_model}
                onChange={(e) => set('tv_model', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Diagonali</label>
              <input
                className="form-input"
                placeholder='55"'
                value={form.tv_diagonal}
                onChange={(e) => set('tv_diagonal', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Seriya raqami</label>
              <input
                className="form-input"
                placeholder="0X4T3CXBA..."
                value={form.tv_serial_number}
                onChange={(e) => set('tv_serial_number', e.target.value)}
              />
            </div>

            {/* ── Nosozlik ───────────────────────────────────── */}
            <div style={{ gridColumn: '1 / -1', marginTop: 8 }}>
              <div style={{
                fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
                letterSpacing: '0.06em', color: '#64748b', marginBottom: 12,
              }}>
                🔧 Zakaz tafsilotlari
              </div>
            </div>

            <div className="form-group" style={{ gridColumn: '1 / -1' }}>
              <label className="form-label">
                Nosozlik tavsifi <span className="required">*</span>
              </label>
              <textarea
                className={`form-textarea${errors.problem_description ? ' error' : ''}`}
                rows={3}
                placeholder="Ekran yonmayapti, ovoz bor lekin tasvir yo'q..."
                value={form.problem_description}
                onChange={(e) => set('problem_description', e.target.value)}
              />
              {errors.problem_description && (
                <div className="form-error">{errors.problem_description}</div>
              )}
            </div>

            <div className="form-group">
              <label className="form-label">Manba</label>
              <select
                className="form-select"
                value={form.source}
                onChange={(e) => set('source', e.target.value)}
              >
                {SOURCES.map(([val, label]) => (
                  <option key={val} value={val}>{label}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Taxminiy narx (so'm)</label>
              <input
                className="form-input"
                type="number"
                min="0"
                placeholder="150000"
                value={form.estimated_price}
                onChange={(e) => set('estimated_price', e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Usta tayinlash</label>
              <select
                className="form-select"
                value={form.master_id}
                onChange={(e) => set('master_id', e.target.value)}
              >
                <option value="">— Keyinroq tayinlanadi —</option>
                {masters.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.full_name} ({m.commission_percent}%)
                  </option>
                ))}
              </select>
            </div>

            {/* ── Deadline — MAJBURIY ────────────────────────── */}
            <div className="form-group">
              <label className="form-label">
                ⏰ Deadline (muddat) <span className="required">*</span>
              </label>
              <input
                className={`form-input${errors.deadline ? ' error' : ''}`}
                type="datetime-local"
                value={form.deadline}
                min={new Date().toISOString().slice(0, 16)}
                onChange={(e) => set('deadline', e.target.value)}
              />
              {errors.deadline ? (
                <div className="form-error">{errors.deadline}</div>
              ) : (
                <div style={{ fontSize: 11.5, color: '#94a3b8', marginTop: 4 }}>
                  Zakaz shu vaqtga qadar tayyor bo'lishi kerak
                </div>
              )}
            </div>

          </div>{/* /grid */}
        </div>

        {/* Footer */}
        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose} disabled={saving}>
            Bekor qilish
          </button>
          <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
            {saving ? (
              <><span className="spinner" style={{ width: 14, height: 14 }} /> Saqlanmoqda...</>
            ) : (
              '✅ Zakaz yaratish'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/Orders/OrderDetailModal.jsx' << 'TVCRM_EOF'
// ================================================
// OrderDetailModal.jsx — Zakaz to'liq ma'lumoti
// ================================================

import {
  formatMoney, formatDate, formatDeadline,
  ORDER_STATUS_LABELS, ORDER_STATUS_COLORS, ORDER_STATUS_ICONS,
  PAYMENT_METHOD_LABELS, ORDER_SOURCE_LABELS,
} from '@/utils/formatters';

function InfoRow({ label, value, mono }) {
  if (!value && value !== 0) return null;
  return (
    <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
      <span style={{ color: '#64748b', fontSize: 13, minWidth: 140, flexShrink: 0 }}>
        {label}
      </span>
      <span style={{
        fontSize: 13, fontWeight: 500, color: '#0f172a',
        fontFamily: mono ? 'monospace' : 'inherit',
      }}>
        {value}
      </span>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 20 }}>
      <div style={{
        fontSize: 11, fontWeight: 700, textTransform: 'uppercase',
        letterSpacing: '0.06em', color: '#94a3b8', marginBottom: 12,
        paddingBottom: 6, borderBottom: '1px solid #f1f5f9',
      }}>
        {title}
      </div>
      {children}
    </div>
  );
}

export default function OrderDetailModal({ order, onClose, onChangeStatus }) {
  const { label: dlLabel, className: dlClass } =
    formatDeadline(order.deadline, order.hours_until_deadline);

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal modal-xl">
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <h2 className="modal-title">
              📋 {order.order_number}
            </h2>
            <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
              {ORDER_STATUS_ICONS[order.status]} {ORDER_STATUS_LABELS[order.status]}
            </span>
            <span className={`badge ${dlClass}`} style={{ fontSize: 11 }}>
              ⏰ {dlLabel}
            </span>
          </div>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>

        <div className="modal-body">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 32px' }}>

            {/* ── Chap ustun ──────────────────────────────────── */}
            <div>
              <Section title="👤 Mijoz">
                <InfoRow label="Ismi"     value={order.client?.full_name} />
                <InfoRow label="Telefon"  value={order.client?.phone} />
                <InfoRow label="Manba"    value={ORDER_SOURCE_LABELS[order.source]} />
              </Section>

              <Section title="📺 Televizor">
                <InfoRow label="Brand"      value={order.tv_brand} />
                <InfoRow label="Model"      value={order.tv_model} />
                <InfoRow label="Diagonali"  value={order.tv_diagonal} />
                <InfoRow label="Seriya #"   value={order.tv_serial_number} mono />
              </Section>

              <Section title="🔧 Nosozlik">
                <div style={{
                  fontSize: 13, color: '#374151', lineHeight: 1.6,
                  background: '#fafafa', padding: 12, borderRadius: 8,
                  border: '1px solid #f1f5f9',
                }}>
                  {order.problem_description || '—'}
                </div>
                {order.master_diagnosis && (
                  <div style={{ marginTop: 10 }}>
                    <div style={{ fontSize: 11.5, color: '#64748b', marginBottom: 4, fontWeight: 600 }}>
                      Usta tashxisi:
                    </div>
                    <div style={{
                      fontSize: 13, color: '#374151', lineHeight: 1.6,
                      background: '#f0fdf4', padding: 12, borderRadius: 8,
                      border: '1px solid #bbf7d0',
                    }}>
                      {order.master_diagnosis}
                    </div>
                  </div>
                )}
                {order.work_done && (
                  <div style={{ marginTop: 10 }}>
                    <div style={{ fontSize: 11.5, color: '#64748b', marginBottom: 4, fontWeight: 600 }}>
                      Bajarilgan ishlar:
                    </div>
                    <div style={{
                      fontSize: 13, color: '#374151', lineHeight: 1.6,
                      background: '#eff6ff', padding: 12, borderRadius: 8,
                      border: '1px solid #bfdbfe',
                    }}>
                      {order.work_done}
                    </div>
                  </div>
                )}
              </Section>
            </div>

            {/* ── O'ng ustun ──────────────────────────────────── */}
            <div>
              <Section title="👷 Ishchilar">
                <InfoRow label="Operator"  value={order.operator?.full_name} />
                <InfoRow label="Usta"      value={order.master?.full_name || 'Tayinlanmagan'} />
                <InfoRow label="Komisyon"  value={order.master_commission > 0
                  ? formatMoney(order.master_commission) : undefined} />
              </Section>

              <Section title="💰 Moliya">
                <InfoRow label="Taxminiy narx"  value={formatMoney(order.estimated_price)} />
                <InfoRow label="Zapchastlar"     value={formatMoney(order.parts_cost)} />
                <InfoRow label="Yakuniy narx"    value={formatMoney(order.final_price)} />
                <InfoRow label="To'lov holati"   value={
                  order.is_paid
                    ? `✅ To'langan (${PAYMENT_METHOD_LABELS[order.payment_method] || ''})`
                    : "⏳ To'lanmagan"
                } />
              </Section>

              <Section title="⏰ Vaqt belgilari">
                <InfoRow label="Qabul qilingan"  value={formatDate(order.created_at)} />
                <InfoRow label="Deadline"
                  value={
                    <span className={`badge ${dlClass}`} style={{ fontSize: 11 }}>
                      ⏰ {dlLabel}
                    </span>
                  }
                />
                <InfoRow label="Qabul vaqti"     value={formatDate(order.accepted_at)} />
                <InfoRow label="Tugallangan"      value={formatDate(order.completed_at)} />
                <InfoRow label="Topshirilgan"     value={formatDate(order.delivered_at)} />
                {order.cancel_reason && (
                  <InfoRow label="Bekor sababi"   value={order.cancel_reason} />
                )}
              </Section>

              {/* Status tarixi */}
              {order.status_history?.length > 0 && (
                <Section title="📜 Status tarixi">
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    {[...order.status_history].reverse().map((h) => (
                      <div
                        key={h.id}
                        style={{
                          display: 'flex', gap: 8,
                          padding: '8px 12px',
                          background: '#fafafa', borderRadius: 8,
                          border: '1px solid #f1f5f9',
                          fontSize: 12,
                        }}
                      >
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                            {h.old_status && (
                              <>
                                <span className={`badge ${ORDER_STATUS_COLORS[h.old_status]}`}
                                  style={{ fontSize: 10 }}>
                                  {ORDER_STATUS_LABELS[h.old_status]}
                                </span>
                                <span style={{ color: '#94a3b8' }}>→</span>
                              </>
                            )}
                            <span className={`badge ${ORDER_STATUS_COLORS[h.new_status]}`}
                              style={{ fontSize: 10 }}>
                              {ORDER_STATUS_LABELS[h.new_status]}
                            </span>
                          </div>
                          {h.comment && (
                            <div style={{ color: '#64748b', marginTop: 3 }}>{h.comment}</div>
                          )}
                        </div>
                        <div style={{ color: '#94a3b8', fontSize: 11, flexShrink: 0, textAlign: 'right' }}>
                          {h.changed_by?.full_name && (
                            <div style={{ fontWeight: 600, color: '#64748b' }}>
                              {h.changed_by.full_name}
                            </div>
                          )}
                          {formatDate(h.created_at)}
                        </div>
                      </div>
                    ))}
                  </div>
                </Section>
              )}
            </div>
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose}>Yopish</button>
          {!['delivered','cancelled'].includes(order.status) && (
            <button
              className="btn btn-primary"
              onClick={() => { onClose(); onChangeStatus?.(order); }}
            >
              🔄 Holat o'zgartirish
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/Orders/StatusModal.jsx' << 'TVCRM_EOF'
// ================================================
// StatusModal.jsx — Status o'zgartirish modali
// ================================================

import { useState } from 'react';
import ordersApi from '@/api/ordersApi';
import {
  getAllowedNextStatuses,
  ORDER_STATUS_LABELS,
  ORDER_STATUS_ICONS,
  ORDER_STATUS_COLORS,
  formatMoney,
  PAYMENT_METHOD_LABELS,
} from '@/utils/formatters';
import toast from 'react-hot-toast';

export default function StatusModal({ order, onClose, onUpdated }) {
  const [selected,      setSelected]      = useState('');
  const [comment,       setComment]       = useState('');
  const [saving,        setSaving]        = useState(false);
  // To'lov modali (faqat done → delivered)
  const [showPayment,   setShowPayment]   = useState(false);
  const [finalPrice,    setFinalPrice]    = useState(
    order.final_price > 0 ? String(order.final_price) : String(order.estimated_price || '')
  );
  const [payMethod,     setPayMethod]     = useState('cash');
  const [payComment,    setPayComment]    = useState('');

  const nextStatuses = getAllowedNextStatuses(order.status);

  // ── Status o'zgartirish ──────────────────────────────────────
  const handleStatusChange = async () => {
    if (!selected) { toast.error('Yangi holat tanlang'); return; }
    setSaving(true);
    try {
      // DONE → DELIVERED holati to'lov orqali amalga oshiriladi
      if (selected === 'delivered') {
        setShowPayment(true);
        setSaving(false);
        return;
      }
      const updated = await ordersApi.changeStatus(order.id, selected, comment);
      toast.success(`✅ Holat o'zgardi: ${ORDER_STATUS_LABELS[updated.status]}`);
      onUpdated?.(updated);
      onClose();
    } catch (err) {
      toast.error(err.message || 'Xato yuz berdi');
    } finally {
      setSaving(false);
    }
  };

  // ── To'lov qabul qilish ──────────────────────────────────────
  const handlePayment = async () => {
    const price = parseFloat(finalPrice);
    if (!price || price <= 0) { toast.error("To'lov summasi kiritilishi shart"); return; }
    setSaving(true);
    try {
      const updated = await ordersApi.acceptPayment(
        order.id, price, payMethod, payComment
      );
      toast.success(`💳 To'lov qabul qilindi: ${formatMoney(price)}`);
      onUpdated?.(updated);
      onClose();
    } catch (err) {
      toast.error(err.message || "To'lovda xato");
    } finally {
      setSaving(false);
    }
  };

  // ── To'lov formasi ───────────────────────────────────────────
  if (showPayment) {
    return (
      <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
        <div className="modal modal-sm">
          <div className="modal-header">
            <h2 className="modal-title">💳 To'lov qabul qilish</h2>
            <button className="modal-close" onClick={onClose}>✕</button>
          </div>
          <div className="modal-body">
            <div className="alert alert-info" style={{ marginBottom: 16 }}>
              <span className="alert-icon">ℹ️</span>
              <div className="alert-text">
                <b>{order.order_number}</b> — {order.client?.full_name}
                <br />
                <span style={{ fontSize: 12 }}>Taxminiy narx: {formatMoney(order.estimated_price)}</span>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">
                Yakuniy summa (so'm) <span className="required">*</span>
              </label>
              <input
                className="form-input"
                type="number" min="0"
                value={finalPrice}
                onChange={(e) => setFinalPrice(e.target.value)}
                autoFocus
              />
            </div>

            <div className="form-group">
              <label className="form-label">To'lov usuli</label>
              <select
                className="form-select"
                value={payMethod}
                onChange={(e) => setPayMethod(e.target.value)}
              >
                {Object.entries(PAYMENT_METHOD_LABELS).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Izoh</label>
              <input
                className="form-input"
                placeholder="Mijoz to'liq to'ladi..."
                value={payComment}
                onChange={(e) => setPayComment(e.target.value)}
              />
            </div>
          </div>
          <div className="modal-footer">
            <button className="btn btn-secondary" onClick={() => setShowPayment(false)}>
              ← Orqaga
            </button>
            <button className="btn btn-success" onClick={handlePayment} disabled={saving}>
              {saving
                ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Saqlanmoqda...</>
                : '💳 To\'lovni qabul qilish'
              }
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ── Asosiy status tanlash modali ─────────────────────────────
  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal modal-sm">
        <div className="modal-header">
          <h2 className="modal-title">🔄 Holat o'zgartirish</h2>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        <div className="modal-body">
          {/* Joriy holat */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 14px', background: '#f8fafc',
            borderRadius: 8, marginBottom: 16,
          }}>
            <span style={{ fontSize: 13, color: '#64748b' }}>Hozirgi holat:</span>
            <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
              {ORDER_STATUS_ICONS[order.status]} {ORDER_STATUS_LABELS[order.status]}
            </span>
          </div>

          {/* Yangi holat tanlash */}
          {nextStatuses.length === 0 ? (
            <div className="alert alert-info">
              <span className="alert-icon">ℹ️</span>
              <div className="alert-text">Bu holat yakuniy — o'zgartirib bo'lmaydi.</div>
            </div>
          ) : (
            <div className="form-group">
              <label className="form-label">
                Yangi holat <span className="required">*</span>
              </label>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {nextStatuses.map((s) => (
                  <label
                    key={s.value}
                    style={{
                      display: 'flex', alignItems: 'center', gap: 10,
                      padding: '10px 14px',
                      border: `2px solid ${selected === s.value ? '#2563eb' : '#e2e8f0'}`,
                      borderRadius: 8, cursor: 'pointer',
                      background: selected === s.value ? '#eff6ff' : 'white',
                      transition: 'all 0.15s',
                    }}
                  >
                    <input
                      type="radio"
                      name="status"
                      value={s.value}
                      checked={selected === s.value}
                      onChange={() => setSelected(s.value)}
                      style={{ accentColor: '#2563eb' }}
                    />
                    <span style={{ fontSize: 16 }}>{s.icon}</span>
                    <span style={{ fontWeight: 600, fontSize: 13 }}>{s.label}</span>
                    {s.value === 'cancelled' && (
                      <span className="badge badge-cancelled" style={{ marginLeft: 'auto', fontSize: 10 }}>
                        Arxivlanadi
                      </span>
                    )}
                    {s.value === 'delivered' && (
                      <span className="badge badge-accepted" style={{ marginLeft: 'auto', fontSize: 10 }}>
                        To'lov kerak
                      </span>
                    )}
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* Izoh */}
          {nextStatuses.length > 0 && (
            <div className="form-group" style={{ marginTop: 4 }}>
              <label className="form-label">Izoh (ixtiyoriy)</label>
              <textarea
                className="form-textarea"
                rows={2}
                placeholder="Sabab yoki qo'shimcha ma'lumot..."
                value={comment}
                onChange={(e) => setComment(e.target.value)}
              />
            </div>
          )}
        </div>

        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={onClose} disabled={saving}>
            Bekor qilish
          </button>
          {nextStatuses.length > 0 && (
            <button
              className="btn btn-primary"
              onClick={handleStatusChange}
              disabled={saving || !selected}
            >
              {saving
                ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Saqlanmoqda...</>
                : '✅ Tasdiqlash'
              }
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/common/Modal.jsx' << 'TVCRM_EOF'
// ================================================
// Modal.jsx — Qayta ishlatiladigan modal wrapper
// ================================================

import { useEffect } from 'react';

export default function Modal({
  isOpen,
  onClose,
  title,
  size = 'md',       // sm | md | lg | xl
  children,
  footer,
  hideClose = false,
}) {
  // Body scroll'ni bloklash
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => { document.body.style.overflow = ''; };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      className="modal-overlay"
      onClick={(e) => e.target === e.currentTarget && onClose?.()}
    >
      <div className={`modal modal-${size}`}>
        {/* Header */}
        {(title || !hideClose) && (
          <div className="modal-header">
            {title && <h2 className="modal-title">{title}</h2>}
            {!hideClose && (
              <button className="modal-close" onClick={onClose}>✕</button>
            )}
          </div>
        )}

        {/* Body */}
        <div className="modal-body">{children}</div>

        {/* Footer */}
        {footer && <div className="modal-footer">{footer}</div>}
      </div>
    </div>
  );
}

// ── Confirm dialog ───────────────────────────────────────────────
export function ConfirmModal({
  isOpen,
  onClose,
  onConfirm,
  title    = 'Tasdiqlash',
  message,
  confirmLabel = 'Tasdiqlash',
  cancelLabel  = 'Bekor qilish',
  variant  = 'danger',   // danger | warning | primary
  loading  = false,
}) {
  if (!isOpen) return null;

  const btnClass =
    variant === 'danger'  ? 'btn-danger'  :
    variant === 'warning' ? 'btn-secondary' :
    'btn-primary';

  const icon =
    variant === 'danger'  ? '⚠️' :
    variant === 'warning' ? '❕' :
    'ℹ️';

  return (
    <div
      className="modal-overlay"
      onClick={(e) => e.target === e.currentTarget && onClose?.()}
    >
      <div className="modal modal-sm">
        <div className="modal-body" style={{ paddingTop: 24, textAlign: 'center' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>{icon}</div>
          <h3 style={{ fontSize: 17, fontWeight: 700, marginBottom: 8 }}>{title}</h3>
          {message && (
            <p style={{ fontSize: 14, color: '#64748b', lineHeight: 1.6 }}>{message}</p>
          )}
        </div>
        <div className="modal-footer" style={{ justifyContent: 'center', gap: 12 }}>
          <button className="btn btn-secondary" onClick={onClose} disabled={loading}>
            {cancelLabel}
          </button>
          <button className={`btn ${btnClass}`} onClick={onConfirm} disabled={loading}>
            {loading
              ? <><span className="spinner" style={{ width: 14, height: 14 }} /> Kutilmoqda...</>
              : confirmLabel
            }
          </button>
        </div>
      </div>
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/common/Button.jsx' << 'TVCRM_EOF'
// ================================================
// Button.jsx — Qayta ishlatiladigan tugma komponenti
// ================================================

export default function Button({
  children,
  variant  = 'primary',  // primary | secondary | danger | success | ghost
  size     = 'md',       // sm | md | lg | icon
  loading  = false,
  disabled = false,
  icon,
  onClick,
  type     = 'button',
  className = '',
  style,
  title,
  ...rest
}) {
  return (
    <button
      type={type}
      className={`btn btn-${variant} btn-${size} ${className}`}
      disabled={disabled || loading}
      onClick={onClick}
      title={title}
      style={style}
      {...rest}
    >
      {loading ? (
        <>
          <span className="spinner" style={{ width: 14, height: 14 }} />
          {children && <span>Yuklanmoqda...</span>}
        </>
      ) : (
        <>
          {icon && <span>{icon}</span>}
          {children}
        </>
      )}
    </button>
  );
}

// ── Icon tugma ───────────────────────────────────────────────────
export function IconButton({ icon, onClick, title, variant = 'ghost', disabled }) {
  return (
    <button
      type="button"
      className={`btn btn-${variant} btn-icon`}
      onClick={onClick}
      title={title}
      disabled={disabled}
    >
      {icon}
    </button>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/common/Table.jsx' << 'TVCRM_EOF'
// ================================================
// Table.jsx — Qayta ishlatiladigan jadval komponentlari
// ================================================

// ── Asosiy jadval wrapper ────────────────────────────────────────
export function Table({ children, className = '' }) {
  return (
    <div className={`table-wrapper ${className}`}>
      <table className="table">{children}</table>
    </div>
  );
}

// ── Bo'sh holat ──────────────────────────────────────────────────
export function EmptyState({ icon = '📭', title, text, action }) {
  return (
    <div className="empty-state">
      <div className="empty-icon">{icon}</div>
      {title && <div className="empty-title">{title}</div>}
      {text  && <div className="empty-text">{text}</div>}
      {action && <div style={{ marginTop: 16 }}>{action}</div>}
    </div>
  );
}

// ── Yuklanish skeleton ───────────────────────────────────────────
export function TableSkeleton({ rows = 5, cols = 6 }) {
  return (
    <table className="table">
      <tbody>
        {Array.from({ length: rows }).map((_, i) => (
          <tr key={i}>
            {Array.from({ length: cols }).map((_, j) => (
              <td key={j}>
                <div
                  style={{
                    height: 14,
                    borderRadius: 4,
                    background: 'linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%)',
                    backgroundSize: '200% 100%',
                    animation: 'shimmer 1.5s infinite',
                    width: j === 0 ? '80%' : j === cols - 1 ? '60%' : '90%',
                  }}
                />
              </td>
            ))}
          </tr>
        ))}
      </tbody>
      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
      `}</style>
    </table>
  );
}

// ── Pagination ───────────────────────────────────────────────────
export function Pagination({ currentPage, totalPages, total, pageSize, onPageChange }) {
  if (totalPages <= 1) return null;

  const from = (currentPage - 1) * pageSize + 1;
  const to   = Math.min(currentPage * pageSize, total);

  // Ko'rsatiladigan sahifalar (max 7)
  const getPages = () => {
    if (totalPages <= 7) return Array.from({ length: totalPages }, (_, i) => i + 1);
    const pages = [];
    const delta = 2;
    for (let i = 1; i <= totalPages; i++) {
      if (
        i === 1 || i === totalPages ||
        (i >= currentPage - delta && i <= currentPage + delta)
      ) {
        pages.push(i);
      } else if (pages[pages.length - 1] !== '...') {
        pages.push('...');
      }
    }
    return pages;
  };

  return (
    <div className="pagination">
      <span style={{ fontSize: 13, color: '#64748b' }}>
        {total} ta yozuvdan <b>{from}–{to}</b> ko'rsatilmoqda
      </span>
      <div className="pagination-btns">
        <button
          className="pg-btn"
          disabled={currentPage === 1}
          onClick={() => onPageChange(currentPage - 1)}
        >‹</button>

        {getPages().map((page, idx) =>
          page === '...' ? (
            <span
              key={`dots-${idx}`}
              style={{ padding: '0 4px', color: '#94a3b8', lineHeight: '32px' }}
            >…</span>
          ) : (
            <button
              key={page}
              className={`pg-btn${currentPage === page ? ' active' : ''}`}
              onClick={() => onPageChange(page)}
            >
              {page}
            </button>
          )
        )}

        <button
          className="pg-btn"
          disabled={currentPage === totalPages}
          onClick={() => onPageChange(currentPage + 1)}
        >›</button>
      </div>
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/components/common/StatusBadge.jsx' << 'TVCRM_EOF'
// ================================================
// StatusBadge.jsx — Holat va deadline badge'lari
// ================================================

import {
  ORDER_STATUS_LABELS,
  ORDER_STATUS_COLORS,
  ORDER_STATUS_ICONS,
  ROLE_LABELS,
  ROLE_COLORS,
  formatDeadline,
} from '@/utils/formatters';

// ── Zakaz status badge ───────────────────────────────────────────
export function OrderStatusBadge({ status, showIcon = true }) {
  if (!status) return null;
  return (
    <span className={`badge ${ORDER_STATUS_COLORS[status] || ''}`}>
      {showIcon && ORDER_STATUS_ICONS[status]} {ORDER_STATUS_LABELS[status] || status}
    </span>
  );
}

// ── Deadline badge ───────────────────────────────────────────────
export function DeadlineBadge({ deadline, hoursRemaining, compact = false }) {
  if (!deadline) return null;
  const { label, className, icon } = formatDeadline(deadline, hoursRemaining);
  return (
    <span className={`badge ${className}`} style={{ fontSize: compact ? 11 : undefined }}>
      {!compact && `${icon} `}{label}
    </span>
  );
}

// ── Rol badge ────────────────────────────────────────────────────
export function RoleBadge({ role }) {
  if (!role) return null;
  return (
    <span className={`badge badge-${role}`}>
      {ROLE_LABELS[role] || role}
    </span>
  );
}

// ── To'lov holati badge ──────────────────────────────────────────
export function PaymentBadge({ isPaid, paymentMethod }) {
  const LABELS = { cash: 'Naqd', card: 'Karta', transfer: "O'tkazma" };
  if (isPaid) {
    return (
      <span className="badge badge-accepted">
        ✅ To'langan{paymentMethod ? ` (${LABELS[paymentMethod]})` : ''}
      </span>
    );
  }
  return <span className="badge badge-waiting">⏳ To'lanmagan</span>;
}

// ── Faollik badge ────────────────────────────────────────────────
export function ActiveBadge({ isActive }) {
  return isActive
    ? <span className="badge badge-accepted">✅ Faol</span>
    : <span className="badge badge-cancelled">🔒 Bloklangan</span>;
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/pages/Login.jsx' << 'TVCRM_EOF'
// ================================================
// Login.jsx — Tizimga kirish sahifasi
// ================================================

import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import useAuthStore from '@/store/authStore';
import { usePageTitle } from '@/utils/hooks';

export default function Login() {
  usePageTitle('Kirish');
  const navigate = useNavigate();
  const { login, isLoading, error, isLoggedIn, clearError } = useAuthStore();

  const [form, setForm]           = useState({ username: '', password: '' });
  const [showPass, setShowPass]   = useState(false);
  const [fieldErr, setFieldErr]   = useState({});

  // Allaqachon kirgan bo'lsa — dashboard ga
  useEffect(() => {
    if (isLoggedIn) navigate('/dashboard', { replace: true });
  }, [isLoggedIn, navigate]);

  // Xatolarni tozalash
  useEffect(() => {
    if (error) {
      const t = setTimeout(clearError, 5000);
      return () => clearTimeout(t);
    }
  }, [error, clearError]);

  // ── Forma o'zgarishi ──────────────────────────────────────────
  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((p) => ({ ...p, [name]: value }));
    if (fieldErr[name]) setFieldErr((p) => ({ ...p, [name]: '' }));
  };

  // ── Validatsiya ───────────────────────────────────────────────
  const validate = () => {
    const errs = {};
    if (!form.username.trim()) errs.username = 'Login kiritilishi shart';
    else if (form.username.length < 3)
      errs.username = "Login kamida 3 ta belgi bo'lishi kerak";
    if (!form.password)         errs.password = 'Parol kiritilishi shart';
    else if (form.password.length < 4)
      errs.password = "Parol kamida 4 ta belgi bo'lishi kerak";
    setFieldErr(errs);
    return Object.keys(errs).length === 0;
  };

  // ── Submit ────────────────────────────────────────────────────
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    const result = await login(form.username.trim().toLowerCase(), form.password);
    if (result.success) navigate('/dashboard', { replace: true });
  };

  // ── Enter tugmasi ─────────────────────────────────────────────
  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleSubmit(e);
  };

  return (
    <div className="login-page">
      {/* Fon animatsiya doiralari */}
      <div className="login-bg-circle" />
      <div className="login-bg-circle" />
      <div className="login-bg-circle" />

      <div className="login-card">
        {/* Logo va sarlavha */}
        <div className="login-header">
          <div className="login-logo">📺</div>
          <h1 className="login-title">TV CRM</h1>
          <p className="login-subtitle">
            Ustaxona boshqaruv tizimiga xush kelibsiz
          </p>
        </div>

        {/* Xato xabari */}
        {error && (
          <div className="alert alert-danger" style={{ marginBottom: 16 }}>
            <span className="alert-icon">⚠️</span>
            <div className="alert-text">{error}</div>
          </div>
        )}

        {/* Forma */}
        <form onSubmit={handleSubmit} noValidate>
          {/* Username */}
          <div className="form-group">
            <label className="form-label">
              Foydalanuvchi nomi
              <span className="required"> *</span>
            </label>
            <div className="input-group">
              <span className="input-icon">👤</span>
              <input
                className={`form-input${fieldErr.username ? ' error' : ''}`}
                type="text"
                name="username"
                value={form.username}
                onChange={handleChange}
                onKeyDown={handleKeyDown}
                placeholder="admin"
                autoComplete="username"
                autoFocus
                disabled={isLoading}
              />
            </div>
            {fieldErr.username && (
              <div className="form-error">{fieldErr.username}</div>
            )}
          </div>

          {/* Parol */}
          <div className="form-group">
            <label className="form-label">
              Parol
              <span className="required"> *</span>
            </label>
            <div className="input-group">
              <span className="input-icon">🔒</span>
              <input
                className={`form-input${fieldErr.password ? ' error' : ''}`}
                type={showPass ? 'text' : 'password'}
                name="password"
                value={form.password}
                onChange={handleChange}
                onKeyDown={handleKeyDown}
                placeholder="••••••••"
                autoComplete="current-password"
                disabled={isLoading}
                style={{ paddingRight: 40 }}
              />
              <button
                type="button"
                className="input-icon-right"
                onClick={() => setShowPass((p) => !p)}
                tabIndex={-1}
                style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16 }}
                title={showPass ? "Parolni yashirish" : "Parolni ko'rsatish"}
              >
                {showPass ? '🙈' : '👁️'}
              </button>
            </div>
            {fieldErr.password && (
              <div className="form-error">{fieldErr.password}</div>
            )}
          </div>

          {/* Kirish tugmasi */}
          <button
            type="submit"
            className="btn btn-primary btn-lg"
            style={{ width: '100%', marginTop: 8, justifyContent: 'center' }}
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <span className="spinner" style={{ width: 16, height: 16 }} />
                Kirilmoqda...
              </>
            ) : (
              <>
                🔐 Tizimga kirish
              </>
            )}
          </button>
        </form>

        {/* Footer */}
        <div
          style={{
            marginTop: 24,
            paddingTop: 16,
            borderTop: '1px solid #f1f5f9',
            textAlign: 'center',
          }}
        >
          <p style={{ fontSize: 12, color: '#94a3b8', lineHeight: 1.6 }}>
            📺 TV Ta'mirlash Ustaxonasi
            <br />
            <span style={{ color: '#cbd5e1' }}>
              CRM Boshqaruv Tizimi v1.0
            </span>
          </p>
        </div>

        {/* Demo hisob ma'lumoti (faqat development) */}
        {import.meta.env.DEV && (
          <div
            style={{
              marginTop: 12,
              padding: '10px 14px',
              background: '#f0f9ff',
              border: '1px solid #bae6fd',
              borderRadius: 8,
            }}
          >
            <p style={{ fontSize: 11.5, color: '#0369a1', marginBottom: 6, fontWeight: 600 }}>
              🧪 Test hisob:
            </p>
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                type="button"
                style={{
                  flex: 1, padding: '6px 10px',
                  background: '#e0f2fe', border: '1px solid #7dd3fc',
                  borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#0369a1',
                }}
                onClick={() => setForm({ username: 'admin', password: 'admin123' })}
              >
                👑 Admin
              </button>
              <button
                type="button"
                style={{
                  flex: 1, padding: '6px 10px',
                  background: '#e0f2fe', border: '1px solid #7dd3fc',
                  borderRadius: 6, fontSize: 12, cursor: 'pointer', color: '#0369a1',
                }}
                onClick={() => setForm({ username: 'operator1', password: 'pass123' })}
              >
                🖥️ Operator
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/pages/Dashboard.jsx' << 'TVCRM_EOF'
// ================================================
// Dashboard.jsx — Bosh sahifa
// Stat kartalar, deadline signal, ustalar jadvali
// ================================================

import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import useAuthStore  from '@/store/authStore';
import useOrderStore from '@/store/orderStore';
import workersApi    from '@/api/workersApi';
import ordersApi     from '@/api/ordersApi';
import {
  formatMoney, formatDate, formatDeadline,
  ORDER_STATUS_LABELS, ORDER_STATUS_COLORS, ORDER_STATUS_ICONS,
  ROLE_LABELS, formatTvInfo, getInitials,
} from '@/utils/formatters';
import { usePageTitle, usePolling } from '@/utils/hooks';

// ================================================================
//  KICHIK KOMPONENTLAR
// ================================================================

function StatCard({ icon, iconBg, label, value, sub, onClick }) {
  return (
    <div className="stat-card" style={{ cursor: onClick ? 'pointer' : 'default' }} onClick={onClick}>
      <div className={`stat-icon ${iconBg}`}>{icon}</div>
      <div className="stat-body">
        <div className="stat-label">{label}</div>
        <div className="stat-value">{value ?? '—'}</div>
        {sub && <div className="stat-sub">{sub}</div>}
      </div>
    </div>
  );
}

function SectionHeader({ title, action, actionLabel }) {
  return (
    <div className="card-header" style={{ marginBottom: 0 }}>
      <h2 className="card-title">{title}</h2>
      {action && (
        <button className="btn btn-ghost btn-sm" onClick={action}>
          {actionLabel} →
        </button>
      )}
    </div>
  );
}

// ── Deadline alert qatori ──────────────────────────────────────
function AlertRow({ alert, onClick }) {
  const { label, className, icon } = formatDeadline(alert.deadline, alert.hours_remaining);
  return (
    <div
      onClick={onClick}
      style={{
        display: 'flex', alignItems: 'center', gap: 12,
        padding: '11px 20px', borderBottom: '1px solid #f8fafc',
        cursor: 'pointer', transition: 'background 0.15s',
      }}
      onMouseEnter={(e) => e.currentTarget.style.background = '#fafafa'}
      onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
    >
      {/* Puls indikator */}
      <div style={{ position: 'relative', width: 10, height: 10, flexShrink: 0 }}>
        <div style={{
          width: 10, height: 10, borderRadius: '50%',
          background: alert.is_overdue ? '#dc2626' : '#d97706',
          position: 'absolute',
        }} />
        {alert.is_overdue && (
          <div style={{
            width: 10, height: 10, borderRadius: '50%',
            background: '#dc2626', opacity: 0.4,
            position: 'absolute', animation: 'ping 1.5s infinite',
            transform: 'scale(1)',
          }} />
        )}
      </div>

      {/* Asosiy ma'lumot */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
          <span style={{ fontWeight: 700, fontSize: 13, color: '#0f172a' }}>
            {alert.order_number}
          </span>
          <span className={`badge ${className}`} style={{ fontSize: 11 }}>
            {icon} {label}
          </span>
        </div>
        <div style={{ fontSize: 12, color: '#64748b', marginTop: 2 }}>
          {alert.client_name}
          {alert.tv_info && alert.tv_info !== "TV ma'lumoti yo'q"
            ? ` · ${alert.tv_info}` : ''}
        </div>
      </div>

      {/* Usta */}
      {alert.master_name && (
        <div style={{
          fontSize: 12, color: '#64748b',
          background: '#f1f5f9', padding: '3px 8px', borderRadius: 12,
          flexShrink: 0,
        }}>
          👷 {alert.master_name}
        </div>
      )}
    </div>
  );
}

// ── Zakaz holati kartasi ───────────────────────────────────────
function OrderStatusCard({ status, count, onClick }) {
  return (
    <div
      onClick={onClick}
      style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '10px 12px',
        background: '#fafafa', borderRadius: 8,
        border: '1px solid #f1f5f9',
        cursor: 'pointer', transition: 'all 0.15s',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.background = '#f1f5f9';
        e.currentTarget.style.borderColor = '#e2e8f0';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.background = '#fafafa';
        e.currentTarget.style.borderColor = '#f1f5f9';
      }}
    >
      <span style={{ fontSize: 18 }}>{ORDER_STATUS_ICONS[status]}</span>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 12, color: '#64748b' }}>{ORDER_STATUS_LABELS[status]}</div>
        <div style={{ fontSize: 20, fontWeight: 800, color: '#0f172a', lineHeight: 1.1 }}>
          {count}
        </div>
      </div>
    </div>
  );
}

// ── Usta qatori ────────────────────────────────────────────────
function WorkerRow({ worker, onClick }) {
  const initials = getInitials(worker.full_name);
  return (
    <tr
      style={{ cursor: 'pointer' }}
      onClick={onClick}
    >
      <td>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: '50%',
            background: '#2563eb', color: 'white',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 12, fontWeight: 700, flexShrink: 0,
          }}>
            {initials}
          </div>
          <div>
            <div style={{ fontWeight: 600, fontSize: 13 }}>{worker.full_name}</div>
            <div style={{ fontSize: 11, color: '#94a3b8' }}>@{worker.username}</div>
          </div>
        </div>
      </td>
      <td>
        <span className={`badge badge-${worker.role}`}>
          {ROLE_LABELS[worker.role] || worker.role}
        </span>
      </td>
      <td style={{ fontWeight: 700, color: '#16a34a' }}>
        {formatMoney(worker.balance)}
      </td>
      <td>
        <span style={{ fontWeight: 600, color: '#0f172a' }}>
          {worker.total_orders_done ?? 0}
        </span>
        <span style={{ color: '#94a3b8', fontSize: 12 }}> ta</span>
      </td>
      <td>
        <span style={{
          display: 'inline-flex', alignItems: 'center', gap: 4,
          fontSize: 12, fontWeight: 600,
          color: worker.commission_percent > 0 ? '#2563eb' : '#94a3b8',
        }}>
          {worker.commission_percent > 0
            ? `${worker.commission_percent}%`
            : '—'}
        </span>
      </td>
      <td>
        <span className={`badge ${worker.is_active ? 'badge-accepted' : 'badge-cancelled'}`}>
          {worker.is_active ? '✅ Faol' : '🔒 Bloklangan'}
        </span>
      </td>
    </tr>
  );
}

// ── Oxirgi zakazlar qatori ─────────────────────────────────────
function RecentOrderRow({ order, onClick }) {
  const { label, className } = formatDeadline(order.deadline, order.hours_until_deadline);
  return (
    <tr onClick={onClick} style={{ cursor: 'pointer' }}>
      <td>
        <span style={{ fontFamily: 'monospace', fontWeight: 700, color: '#2563eb' }}>
          {order.order_number}
        </span>
      </td>
      <td>
        <div style={{ fontWeight: 600, fontSize: 13 }}>{order.client?.full_name}</div>
        <div style={{ fontSize: 11, color: '#94a3b8' }}>{order.client?.phone || '—'}</div>
      </td>
      <td style={{ maxWidth: 180 }}>
        <div style={{ fontSize: 12, color: '#374151', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {formatTvInfo(order)}
        </div>
      </td>
      <td>
        <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
          {ORDER_STATUS_ICONS[order.status]} {ORDER_STATUS_LABELS[order.status]}
        </span>
      </td>
      <td>
        <span className={`badge ${className}`} style={{ fontSize: 11 }}>
          {label}
        </span>
      </td>
      <td style={{ fontSize: 12, color: '#64748b' }}>
        {order.master?.full_name || <span style={{ color: '#cbd5e1' }}>Tayinlanmagan</span>}
      </td>
    </tr>
  );
}

// ================================================================
//  ASOSIY KOMPONENT
// ================================================================

export default function Dashboard() {
  usePageTitle('Dashboard');
  const navigate   = useNavigate();
  const { user, isAdmin } = useAuthStore();
  const { stats, deadlineAlerts, fetchStats, fetchDeadlineAlerts } = useOrderStore();

  const [workers,      setWorkers]      = useState([]);
  const [recentOrders, setRecentOrders] = useState([]);
  const [statusCounts, setStatusCounts] = useState({});
  const [loading,      setLoading]      = useState(true);

  // ── Ma'lumotlarni yuklash ──────────────────────────────────
  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [workersRes, ordersRes] = await Promise.all([
        workersApi.getList({ is_active: true, page_size: 10 }),
        ordersApi.getList({ page: 1, page_size: 8, is_archived: false }),
      ]);
      setWorkers(workersRes.items || []);
      setRecentOrders(ordersRes.items || []);

      // Status bo'yicha hisoblash
      const counts = {};
      (ordersRes.items || []).forEach((o) => {
        counts[o.status] = (counts[o.status] || 0) + 1;
      });
      setStatusCounts(counts);
    } catch (err) {
      console.error('Dashboard yuklash xatosi:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    fetchStats();
    fetchDeadlineAlerts();
  }, []);

  // Har 60 sekundda yangilash
  usePolling(fetchDeadlineAlerts, 60_000, true);
  usePolling(fetchStats,          60_000, true);

  // ── Yuklanish holati ──────────────────────────────────────
  if (loading && !stats) {
    return (
      <div className="page-loader">
        <div className="spinner" />
        <span>Dashboard yuklanmoqda...</span>
      </div>
    );
  }

  const overdueAlerts  = deadlineAlerts.filter((a) => a.is_overdue);
  const warningAlerts  = deadlineAlerts.filter((a) => !a.is_overdue);

  return (
    <div>
      {/* ── Overdue Banner ────────────────────────────────────── */}
      {overdueAlerts.length > 0 && (
        <div
          className="overdue-banner"
          style={{ marginBottom: 20, cursor: 'pointer' }}
          onClick={() => navigate('/orders?only_overdue=true')}
        >
          <div className="overdue-banner-pulse" />
          <div style={{ flex: 1 }}>
            <span style={{ fontWeight: 700 }}>
              ❌ {overdueAlerts.length} ta zakazning muddati o'tib ketdi!
            </span>
            <span style={{ fontSize: 13, marginLeft: 8, opacity: 0.8 }}>
              Darhol ko'rish uchun bosing
            </span>
          </div>
          <span style={{ fontWeight: 600, fontSize: 13 }}>→</span>
        </div>
      )}

      {/* ── Stat kartalar ─────────────────────────────────────── */}
      <div className="stats-grid">
        <StatCard
          icon="📋" iconBg="blue"
          label="Jami faol zakazlar"
          value={stats?.total_orders ?? 0}
          sub="Arxivlanmaganlar"
          onClick={() => navigate('/orders')}
        />
        <StatCard
          icon="🆕" iconBg="cyan"
          label="Yangi zakazlar"
          value={stats?.new_orders ?? 0}
          sub="Kutmoqda"
          onClick={() => navigate('/orders?status=new')}
        />
        <StatCard
          icon="🔧" iconBg="yellow"
          label="Jarayonda"
          value={stats?.in_progress ?? 0}
          sub="Qabul, diagnostika, ta'mir"
          onClick={() => navigate('/orders')}
        />
        <StatCard
          icon="🎉" iconBg="green"
          label="Bugun topshirildi"
          value={stats?.delivered_today ?? 0}
          sub={`Daromad: ${formatMoney(stats?.total_revenue_today ?? 0)}`}
        />
        <StatCard
          icon="⚠️" iconBg="red"
          label="Muddati o'tgan"
          value={stats?.overdue_count ?? 0}
          sub="Shoshilish kerak"
          onClick={() => navigate('/orders?only_overdue=true')}
        />
        <StatCard
          icon="💰" iconBg="green"
          label="Bugungi daromad"
          value={formatMoney(stats?.total_revenue_today ?? 0)}
          sub="Topshirilgan zakazlar"
          onClick={() => navigate('/finance')}
        />
      </div>

      {/* ── Asosiy grid ───────────────────────────────────────── */}
      <div className="dashboard-grid">

        {/* ── Deadline alertlar ─────────────────────────────── */}
        <div className="card">
          <SectionHeader
            title={`⏰ Deadline nazorat ${deadlineAlerts.length > 0 ? `(${deadlineAlerts.length})` : ''}`}
            action={() => navigate('/orders?only_overdue=true')}
            actionLabel="Barchasi"
          />
          <div style={{ marginTop: 4 }}>
            {deadlineAlerts.length === 0 ? (
              <div className="empty-state" style={{ padding: '40px 20px' }}>
                <div className="empty-icon">✅</div>
                <div className="empty-title">Barcha zakazlar vaqtida!</div>
                <div className="empty-text">Muddati o'tayotgan zakazlar yo'q</div>
              </div>
            ) : (
              <>
                {overdueAlerts.slice(0, 4).map((a) => (
                  <AlertRow
                    key={a.order_id}
                    alert={a}
                    onClick={() => navigate('/orders')}
                  />
                ))}
                {warningAlerts.slice(0, 3).map((a) => (
                  <AlertRow
                    key={a.order_id}
                    alert={a}
                    onClick={() => navigate('/orders')}
                  />
                ))}
                {deadlineAlerts.length > 7 && (
                  <div
                    style={{
                      padding: '10px 20px', textAlign: 'center',
                      fontSize: 13, color: '#64748b', borderTop: '1px solid #f8fafc',
                      cursor: 'pointer',
                    }}
                    onClick={() => navigate('/orders?only_overdue=true')}
                  >
                    + {deadlineAlerts.length - 7} ta ko'proq →
                  </div>
                )}
              </>
            )}
          </div>
        </div>

        {/* ── Holat bo'yicha statistika ──────────────────────── */}
        <div className="card">
          <SectionHeader
            title="📊 Zakazlar holati"
            action={() => navigate('/orders')}
            actionLabel="Barchasi"
          />
          <div className="card-body">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {['new','accepted','diagnosing','waiting',
                'on_the_way','in_repair','done','delivered'].map((status) => (
                <OrderStatusCard
                  key={status}
                  status={status}
                  count={
                    status === 'new'       ? (stats?.new_orders      ?? 0) :
                    status === 'delivered' ? (stats?.delivered_today ?? 0) :
                    (statusCounts[status]  ?? 0)
                  }
                  onClick={() => navigate(`/orders?status=${status}`)}
                />
              ))}
            </div>
          </div>
        </div>

        {/* ── Oxirgi zakazlar ───────────────────────────────── */}
        <div className="card full-width">
          <SectionHeader
            title="📋 Oxirgi zakazlar"
            action={() => navigate('/orders')}
            actionLabel="Barchasi"
          />
          <div className="table-wrapper" style={{ margin: '12px 0 0', border: 'none', borderRadius: 0 }}>
            {recentOrders.length === 0 ? (
              <div className="empty-state">
                <div className="empty-icon">📋</div>
                <div className="empty-title">Zakazlar yo'q</div>
                <div className="empty-text">Hali birorta zakaz qo'shilmagan</div>
              </div>
            ) : (
              <table className="table">
                <thead>
                  <tr>
                    <th>Raqam</th>
                    <th>Mijoz</th>
                    <th>Televizor</th>
                    <th>Holat</th>
                    <th>Deadline</th>
                    <th>Usta</th>
                  </tr>
                </thead>
                <tbody>
                  {recentOrders.map((order) => (
                    <RecentOrderRow
                      key={order.id}
                      order={order}
                      onClick={() => navigate('/orders')}
                    />
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* ── Ustalar jadvali ───────────────────────────────── */}
        {isAdmin() && (
          <div className="card full-width">
            <SectionHeader
              title="👷 Ishchilar holati"
              action={() => navigate('/workers')}
              actionLabel="Barchasi"
            />
            <div className="table-wrapper" style={{ margin: '12px 0 0', border: 'none', borderRadius: 0 }}>
              {workers.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-icon">👷</div>
                  <div className="empty-title">Ishchilar yo'q</div>
                </div>
              ) : (
                <table className="table">
                  <thead>
                    <tr>
                      <th>Ishchi</th>
                      <th>Rol</th>
                      <th>Balans</th>
                      <th>Bitirgan</th>
                      <th>Komisyon</th>
                      <th>Holat</th>
                    </tr>
                  </thead>
                  <tbody>
                    {workers.map((worker) => (
                      <WorkerRow
                        key={worker.id}
                        worker={worker}
                        onClick={() => navigate('/workers')}
                      />
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        )}

      </div>{/* /dashboard-grid */}
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/frontend/src/pages/Orders.jsx' << 'TVCRM_EOF'
// ================================================
// Orders.jsx — Zakazlar boshqaruv sahifasi
// Jadval, filter, yangi zakaz, status o'zgartirish
// ================================================

import { useEffect, useState, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import useOrderStore from '@/store/orderStore';
import useAuthStore  from '@/store/authStore';
import ordersApi     from '@/api/ordersApi';
import NewOrderModal    from '@/components/Orders/NewOrderModal';
import StatusModal      from '@/components/Orders/StatusModal';
import OrderDetailModal from '@/components/Orders/OrderDetailModal';
import {
  formatDate, formatMoney, formatDeadline, formatTvInfo,
  ORDER_STATUS_LABELS, ORDER_STATUS_COLORS, ORDER_STATUS_ICONS,
  truncate,
} from '@/utils/formatters';
import { usePageTitle, useDebounce, useModal } from '@/utils/hooks';
import toast from 'react-hot-toast';

// Filtr status tugmalari
const STATUS_FILTERS = [
  { value: '',           label: 'Barchasi' },
  { value: 'new',        label: '🆕 Yangi' },
  { value: 'accepted',   label: '✅ Qabul' },
  { value: 'diagnosing', label: '🔍 Diagnostika' },
  { value: 'waiting',    label: '⏳ Kutmoqda' },
  { value: 'on_the_way', label: "🚗 Yo'lda" },
  { value: 'in_repair',  label: "🔧 Ta'mirda" },
  { value: 'done',       label: '✔️ Tayyor' },
  { value: 'delivered',  label: '🎉 Topshirildi' },
  { value: 'cancelled',  label: '❌ Bekor' },
];

export default function Orders() {
  usePageTitle('Zakazlar');
  const [searchParams] = useSearchParams();
  const { isAdminOrOperator } = useAuthStore();
  const {
    orders, total, totalPages, currentPage, overdueCount,
    isLoading, fetchOrders, setFilter, setPage, changeStatus,
  } = useOrderStore();

  // Modallar
  const newOrderModal  = useModal();
  const statusModal    = useModal();   // data = order
  const detailModal    = useModal();   // data = order

  // Filter holati
  const [searchInput,   setSearchInput]   = useState('');
  const [activeStatus,  setActiveStatus]  = useState(searchParams.get('status') || '');
  const [onlyOverdue,   setOnlyOverdue]   = useState(searchParams.get('only_overdue') === 'true');
  const [isArchived,    setIsArchived]    = useState(false);

  const debouncedSearch = useDebounce(searchInput, 400);

  // ── Zakazlarni yuklash ──────────────────────────────────────
  const load = useCallback(() => {
    fetchOrders({
      status:       activeStatus || undefined,
      search:       debouncedSearch || undefined,
      only_overdue: onlyOverdue,
      is_archived:  isArchived,
      page:         currentPage,
    });
  }, [activeStatus, debouncedSearch, onlyOverdue, isArchived, currentPage]);

  useEffect(() => { load(); }, [load]);

  // ── Filter tugmalari ────────────────────────────────────────
  const handleStatusFilter = (val) => {
    setActiveStatus(val);
    setFilter('status', val);
    setFilter('page', 1);
  };

  const handleSearch = (val) => {
    setSearchInput(val);
    setFilter('search', val);
    setFilter('page', 1);
  };

  const handleOverdueToggle = () => {
    const next = !onlyOverdue;
    setOnlyOverdue(next);
    setFilter('only_overdue', next);
    setFilter('page', 1);
  };

  // ── Zakaz yaratilganda ──────────────────────────────────────
  const handleCreated = (newOrder) => {
    load();
    toast.success(`📋 ${newOrder.order_number} yaratildi!`);
  };

  // ── Status yangilanganda ─────────────────────────────────────
  const handleStatusUpdated = (updatedOrder) => {
    load();
  };

  // ── Detail dan status modali ─────────────────────────────────
  const handleChangeStatusFromDetail = (order) => {
    statusModal.open(order);
  };

  // ── Arxivlash ────────────────────────────────────────────────
  const handleArchive = async (order, e) => {
    e.stopPropagation();
    if (!window.confirm(`"${order.order_number}" ni arxivlashni xohlaysizmi?`)) return;
    try {
      await ordersApi.archive(order.id);
      toast.success('📦 Arxivlandi');
      load();
    } catch (err) {
      toast.error(err.message || 'Xato');
    }
  };

  return (
    <div>
      {/* ── Overdue banner ──────────────────────────────────── */}
      {overdueCount > 0 && !onlyOverdue && (
        <div
          className="overdue-banner"
          style={{ marginBottom: 16, cursor: 'pointer' }}
          onClick={handleOverdueToggle}
        >
          <div className="overdue-banner-pulse" />
          <span style={{ fontWeight: 700 }}>
            ❌ {overdueCount} ta zakazning muddati o'tib ketdi!
          </span>
          <span style={{ fontSize: 13, marginLeft: 8, opacity: 0.8 }}>
            Filtrlash uchun bosing
          </span>
        </div>
      )}

      {/* ── Bosh toolbar ────────────────────────────────────── */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        flexWrap: 'wrap', gap: 12, marginBottom: 16,
      }}>
        {/* Qidiruv */}
        <div className="search-bar" style={{ maxWidth: 280 }}>
          <span className="search-icon">🔍</span>
          <input
            placeholder="Zakaz # yoki mijoz..."
            value={searchInput}
            onChange={(e) => handleSearch(e.target.value)}
          />
        </div>

        {/* O'ng tugmalar */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {/* Arxiv toggle */}
          <button
            className={`btn ${isArchived ? 'btn-secondary' : 'btn-ghost'}`}
            onClick={() => { setIsArchived((p) => !p); setFilter('is_archived', !isArchived); }}
          >
            📦 {isArchived ? 'Arxiv (faol)' : 'Arxiv'}
          </button>

          {/* Overdue toggle */}
          <button
            className={`btn ${onlyOverdue ? 'btn-danger' : 'btn-ghost'}`}
            onClick={handleOverdueToggle}
          >
            {onlyOverdue ? '❌ Muddati o\'tgan' : '⚠️ Muddati o\'tgan'}
          </button>

          {/* Yangi zakaz */}
          {isAdminOrOperator() && (
            <button className="btn btn-primary" onClick={() => newOrderModal.open()}>
              ＋ Yangi zakaz
            </button>
          )}
        </div>
      </div>

      {/* ── Status filtrlari ────────────────────────────────── */}
      <div className="filter-bar" style={{ marginBottom: 16, overflowX: 'auto', flexWrap: 'nowrap' }}>
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.value}
            className={`filter-btn${activeStatus === f.value ? ' active' : ''}`}
            onClick={() => handleStatusFilter(f.value)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* ── Jadval kartasi ──────────────────────────────────── */}
      <div className="card">
        {/* Jadval sarlavhasi */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '16px 20px 12px',
        }}>
          <span style={{ fontSize: 13, color: '#64748b' }}>
            Jami:{' '}
            <b style={{ color: '#0f172a' }}>{total}</b> ta zakaz
            {onlyOverdue && (
              <span className="badge deadline-overdue" style={{ marginLeft: 8, fontSize: 11 }}>
                Muddati o'tganlar
              </span>
            )}
          </span>
          <button
            className="btn btn-ghost btn-sm"
            onClick={load}
            disabled={isLoading}
            title="Yangilash"
          >
            {isLoading ? <span className="spinner" style={{ width: 14, height: 14 }} /> : '🔄'}
          </button>
        </div>

        {/* ── Jadval ──────────────────────────────────────── */}
        <div className="table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
          {isLoading && orders.length === 0 ? (
            <div className="page-loader" style={{ minHeight: 200 }}>
              <div className="spinner" />
              <span>Yuklanmoqda...</span>
            </div>
          ) : orders.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">📋</div>
              <div className="empty-title">Zakazlar topilmadi</div>
              <div className="empty-text">
                {onlyOverdue
                  ? 'Muddati o\'tgan zakazlar yo\'q — yaxshi!'
                  : 'Filter o\'zgartiring yoki yangi zakaz qo\'shing'}
              </div>
            </div>
          ) : (
            <table className="table">
              <thead>
                <tr>
                  <th>Raqam</th>
                  <th>Mijoz</th>
                  <th>Televizor</th>
                  <th>Nosozlik</th>
                  <th>Holat</th>
                  <th>Deadline</th>
                  <th>Usta</th>
                  <th>Narx</th>
                  <th>Amallar</th>
                </tr>
              </thead>
              <tbody>
                {orders.map((order) => {
                  const { label: dlLabel, className: dlClass, isOverdue } =
                    formatDeadline(order.deadline, order.hours_until_deadline);

                  return (
                    <tr
                      key={order.id}
                      style={{
                        cursor: 'pointer',
                        background: isOverdue ? '#fff8f8' : undefined,
                      }}
                      onClick={() => detailModal.open(order)}
                    >
                      {/* Raqam */}
                      <td>
                        <span style={{
                          fontFamily: 'monospace', fontWeight: 700,
                          color: '#2563eb', fontSize: 13,
                        }}>
                          {order.order_number}
                        </span>
                        <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 1 }}>
                          {formatDate(order.created_at).split(',')[0]}
                        </div>
                      </td>

                      {/* Mijoz */}
                      <td>
                        <div style={{ fontWeight: 600, fontSize: 13 }}>
                          {order.client?.full_name || '—'}
                        </div>
                        <div style={{ fontSize: 11, color: '#94a3b8' }}>
                          {order.client?.phone || ''}
                        </div>
                      </td>

                      {/* Televizor */}
                      <td style={{ fontSize: 12 }}>
                        <div style={{ fontWeight: 500 }}>
                          {order.tv_brand || '—'}{order.tv_model ? ` ${order.tv_model}` : ''}
                        </div>
                        {order.tv_diagonal && (
                          <div style={{ color: '#94a3b8' }}>{order.tv_diagonal}</div>
                        )}
                      </td>

                      {/* Nosozlik */}
                      <td style={{ maxWidth: 160 }}>
                        <div
                          style={{
                            fontSize: 12, color: '#374151',
                            overflow: 'hidden', whiteSpace: 'nowrap',
                            textOverflow: 'ellipsis', maxWidth: 150,
                          }}
                          title={order.problem_description}
                        >
                          {truncate(order.problem_description, 40)}
                        </div>
                      </td>

                      {/* Holat */}
                      <td>
                        <span className={`badge ${ORDER_STATUS_COLORS[order.status]}`}>
                          {ORDER_STATUS_ICONS[order.status]}{' '}
                          {ORDER_STATUS_LABELS[order.status]}
                        </span>
                      </td>

                      {/* Deadline */}
                      <td>
                        <span
                          className={`badge ${dlClass}`}
                          style={{ fontSize: 11 }}
                        >
                          {dlLabel}
                        </span>
                      </td>

                      {/* Usta */}
                      <td style={{ fontSize: 12 }}>
                        {order.master?.full_name || (
                          <span style={{ color: '#cbd5e1' }}>—</span>
                        )}
                      </td>

                      {/* Narx */}
                      <td style={{ fontSize: 12 }}>
                        {order.is_paid ? (
                          <span style={{ color: '#16a34a', fontWeight: 700 }}>
                            {formatMoney(order.final_price)}
                          </span>
                        ) : order.estimated_price > 0 ? (
                          <span style={{ color: '#64748b' }}>
                            ~{formatMoney(order.estimated_price)}
                          </span>
                        ) : (
                          <span style={{ color: '#cbd5e1' }}>—</span>
                        )}
                      </td>

                      {/* Amallar */}
                      <td onClick={(e) => e.stopPropagation()}>
                        <div className="table-actions">
                          {/* Status o'zgartirish */}
                          {!['delivered', 'cancelled'].includes(order.status) && (
                            <button
                              className="btn btn-ghost btn-sm"
                              onClick={() => statusModal.open(order)}
                              title="Holat o'zgartirish"
                            >
                              🔄
                            </button>
                          )}
                          {/* Arxivlash */}
                          {['delivered', 'cancelled'].includes(order.status) &&
                           !order.is_archived && (
                            <button
                              className="btn btn-ghost btn-sm"
                              onClick={(e) => handleArchive(order, e)}
                              title="Arxivlash"
                            >
                              📦
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {/* ── Pagination ──────────────────────────────────── */}
        {totalPages > 1 && (
          <div className="pagination">
            <span>
              {total} ta zakazdan{' '}
              {(currentPage - 1) * 20 + 1}–{Math.min(currentPage * 20, total)} ko'rsatilmoqda
            </span>
            <div className="pagination-btns">
              <button
                className="pg-btn"
                disabled={currentPage === 1}
                onClick={() => setPage(currentPage - 1)}
              >
                ‹
              </button>
              {Array.from({ length: Math.min(totalPages, 7) }, (_, i) => {
                const page = i + 1;
                return (
                  <button
                    key={page}
                    className={`pg-btn${currentPage === page ? ' active' : ''}`}
                    onClick={() => setPage(page)}
                  >
                    {page}
                  </button>
                );
              })}
              <button
                className="pg-btn"
                disabled={currentPage === totalPages}
                onClick={() => setPage(currentPage + 1)}
              >
                ›
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ── Modallar ──────────────────────────────────────── */}
      {newOrderModal.isOpen && (
        <NewOrderModal
          onClose={newOrderModal.close}
          onCreated={handleCreated}
        />
      )}

      {statusModal.isOpen && statusModal.data && (
        <StatusModal
          order={statusModal.data}
          onClose={statusModal.close}
          onUpdated={handleStatusUpdated}
        />
      )}

      {detailModal.isOpen && detailModal.data && (
        <OrderDetailModal
          order={detailModal.data}
          onClose={detailModal.close}
          onChangeStatus={handleChangeStatusFromDetail}
        />
      )}
    </div>
  );
}
TVCRM_EOF

  cat > 'tv-crm/.gitignore' << 'TVCRM_EOF'
# ================================================
# TV CRM - Git ignore fayli
# ================================================

# --- Python ---
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
dist/
*.egg-info/
.eggs/
*.egg

# --- Virtual muhit ---
venv/
env/
.venv/
ENV/

# --- Muhit o'zgaruvchilari (MAXFIY!) ---
.env
!.env.example

# --- Ma'lumotlar bazasi fayllari ---
*.db
*.sqlite
*.sqlite3

# --- Logs ---
*.log
logs/

# --- IDE ---
.vscode/
.idea/
*.swp
*.swo

# --- OS ---
.DS_Store
Thumbs.db

# --- Node.js (Frontend) ---
node_modules/
frontend/dist/
frontend/.env
frontend/.env.local

# --- Alembic (avtomatik yaratilgan) ---
backend/alembic/versions/*.py
TVCRM_EOF

  cat > 'tv-crm/README.md' << 'TVCRM_EOF'
# 📺 TV Ta'mirlash Ustaxonasi — CRM Tizimi

Professional, modulli va oylik to'lovsiz shaxsiy CRM tizimi.

## 🚀 Tezkor boshlash

### Backend (Python/FastAPI)
```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env       # .env faylini tahrirlang
python run.py
```

### Frontend (React/Vite)
```bash
cd frontend
npm install
npm run dev
```

## 🏗️ Arxitektura
- **Backend:** FastAPI + SQLAlchemy + SQLite
- **Frontend:** React + Vite + Tailwind CSS
- **Auth:** JWT Token

## 📋 Bosqichlar
- [x] 1-Bosqich: Poydevor va Ma'lumotlar Bazasi
- [ ] 2-Bosqich: Zakazlar va Mijozlar moduli
- [ ] 3-Bosqich: Moliya va Ombor moduli
- [ ] 4-Bosqich: Telegram/Instagram integratsiya
- [ ] 5-Bosqich: AI (Gemini) integratsiya
- [ ] 6-Bosqich: IP-Telefoniya integratsiya
- [ ] 7-Bosqich: Mobile (PWA) versiya
TVCRM_EOF

  success "63 ta fayl yozildi"
}

setup_env() {
  header ".env fayli sozlanmoqda"
  if [ ! -f tv-crm/backend/.env ]; then
    cp tv-crm/backend/.env.example tv-crm/backend/.env
    success ".env fayli yaratildi"
  else
    warn ".env allaqachon mavjud, o'zgartirilmadi"
  fi
}

setup_backend() {
  header "Backend o'rnatilmoqda (Python)"
  cd tv-crm/backend
  if [ ! -d venv ]; then
    python3 -m venv venv
    success "Virtual muhit yaratildi"
  fi
  source venv/bin/activate
  pip install --upgrade pip -q
  pip install -r requirements.txt -q
  success "Python kutubxonalari o'rnatildi"
  info "Ma'lumotlar bazasi yaratilmoqda..."
  python3 -m app.database.migrations.init_db
  success "Ma'lumotlar bazasi tayyor (admin / admin123)"
  deactivate
  cd ../..
}

setup_frontend() {
  header "Frontend o'rnatilmoqda (Node.js)"
  cd tv-crm/frontend
  npm install --silent
  success "Node.js paketlari o'rnatildi"
  cd ../..
}

print_done() {
  echo ""
  echo -e "${BOLD}${GREEN}"
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║      ✅  O'RNATISH MUVAFFAQIYATLI YAKUNLANDI!        ║"
  echo "╠══════════════════════════════════════════════════════╣"
  echo "║                                                      ║"
  echo "║  📺 TV CRM ishga tushirish:                          ║"
  echo "║                                                      ║"
  echo "║  1️⃣  Backend (Terminal 1):                            ║"
  echo "║     cd tv-crm/backend                                ║"
  echo "║     source venv/bin/activate                         ║"
  echo "║     python3 run.py                                   ║"
  echo "║     → http://localhost:8000/docs                     ║"
  echo "║                                                      ║"
  echo "║  2️⃣  Frontend (Terminal 2):                           ║"
  echo "║     cd tv-crm/frontend                               ║"
  echo "║     npm run dev                                      ║"
  echo "║     → http://localhost:5173                          ║"
  echo "║                                                      ║"
  echo "║  🔑  Login: admin   Parol: admin123                  ║"
  echo "║  ⚠️   Parolni albatta o'zgartiring!                   ║"
  echo "║                                                      ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# ════ ASOSIY ════════════════════════════════════════════════════
echo -e "${BOLD}${BLUE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║        📺  TV Ta'mirlash CRM — Setup v1.0            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

check_requirements
make_dirs
write_files
setup_env
setup_backend
setup_frontend
print_done
