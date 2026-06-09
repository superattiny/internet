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
