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
