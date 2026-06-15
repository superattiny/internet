# ================================================
# database.py — Ma'lumotlar bazasi ulanishi
# SQLAlchemy async engine va session factory
# ================================================

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings


# ── Drайverni aniqlash ──────────────────────────────────────────
def _build_db_url(url: str) -> str:
    """
    Database URL ni async driver bilan qayta quramiz.
    SQLite  → sqlite+aiosqlite:///
    Postgres → postgresql+asyncpg://
    """
    if url.startswith("sqlite"):
        return url.replace("sqlite:///", "sqlite+aiosqlite:///")
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+asyncpg://", 1)
    return url


_DB_URL = _build_db_url(settings.database_url)
_IS_SQLITE = _DB_URL.startswith("sqlite")

# ── Engine ─────────────────────────────────────────────────────
engine = create_async_engine(
    url=_DB_URL,
    echo=settings.debug,
    # SQLite uchun maxsus sozlama
    connect_args={"check_same_thread": False} if _IS_SQLITE else {},
    # PostgreSQL uchun connection pool
    pool_size=5          if not _IS_SQLITE else None,
    max_overflow=10      if not _IS_SQLITE else None,
    pool_pre_ping=True   if not _IS_SQLITE else False,
)

# ── Session Factory ────────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


# ── Base Model ─────────────────────────────────────────────────
class Base(DeclarativeBase):
    pass


# ── Dependency ─────────────────────────────────────────────────
async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


# ── Init & Drop ────────────────────────────────────────────────
async def init_db():
    from app.database import models  # noqa: F401
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def drop_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
