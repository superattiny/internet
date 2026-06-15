#!/usr/bin/env python3
"""
================================================================
  TV CRM — localStorage JSON → PostgreSQL Migrator

  Maqsad:
    HTML versiyasidagi barcha ma'lumotlarni
    PostgreSQL ma'lumotlar bazasiga ko'chirish.

  Foydalanish:
    1. HTML CRM → Sozlamalar → "JSON yuklab olish"
    2. Yuklab olingan faylni backend/ papkasiga qo'ying
    3. python db_migrate.py crm_backup_2025-06-15.json

  Yoki interaktiv rejimda:
    python db_migrate.py

  Nima import qilinadi:
    ✅ Foydalanuvchilar (users)
    ✅ Mijozlar (clients)
    ✅ Buyurtmalar (orders)
    ✅ Tranzaksiyalar (transactions → finance_transactions)
    ✅ Ustaxona sozlamalari (settings → shop_settings)
    ✅ Eslatmalar (reminders — agar model qo'shilsa)
================================================================
"""

import asyncio
import json
import sys
import os
from datetime import datetime, timezone
from pathlib import Path

# Loyiha root
sys.path.insert(0, str(Path(__file__).parent))

from app.database.database import init_db, AsyncSessionLocal
from app.database.models import (
    User, UserRole,
    Client,
    Order, OrderStatus, OrderSource, PaymentMethod,
    OrderStatusHistory,
    FinanceTransaction, TransactionType,
    ShopSettings,
)
from app.utils.auth import hash_password

# ── Ranglar ────────────────────────────────────────────────────
OK   = "✅"
WARN = "⚠️ "
ERR  = "❌"
INFO = "ℹ️ "

def p(icon, msg): print(f"  {icon} {msg}")

# ── Yordamchi funksiyalar ───────────────────────────────────────
def parse_date(s) -> datetime | None:
    if not s: return None
    try:
        if "T" in str(s): return datetime.fromisoformat(str(s).replace("Z","+00:00"))
        return datetime.strptime(str(s), "%Y-%m-%d").replace(tzinfo=timezone.utc)
    except: return None

def map_status(s: str) -> OrderStatus:
    m = {
        "new":        OrderStatus.NEW,
        "accepted":   OrderStatus.ACCEPTED,
        "diagnosing": OrderStatus.DIAGNOSING,
        "waiting":    OrderStatus.WAITING,
        "in_repair":  OrderStatus.IN_REPAIR,
        "done":       OrderStatus.DONE,
        "delivered":  OrderStatus.DELIVERED,
        "cancelled":  OrderStatus.CANCELLED,
    }
    return m.get(s, OrderStatus.NEW)

def map_source(s: str) -> OrderSource:
    m = {
        "walk_in":   OrderSource.WALK_IN,
        "phone":     OrderSource.PHONE,
        "telegram":  OrderSource.TELEGRAM,
        "instagram": OrderSource.INSTAGRAM,
    }
    return m.get(s, OrderSource.WALK_IN)

def map_payment(s: str) -> PaymentMethod | None:
    m = {
        "cash":     PaymentMethod.CASH,
        "card":     PaymentMethod.CARD,
        "transfer": PaymentMethod.TRANSFER,
    }
    return m.get(s)

def map_role(s: str) -> UserRole:
    return {"admin": UserRole.ADMIN, "operator": UserRole.OPERATOR}.get(s, UserRole.MASTER)

# ================================================================
#  IMPORT FUNKSIYALARI
# ================================================================

async def import_users(session, users_data: list) -> dict:
    """Foydalanuvchilarni import qiladi. Returns: {old_id: new_id}"""
    id_map = {}
    count = 0
    for u in users_data:
        # Admin ni o'tkazib yuboring agar allaqachon bor bo'lsa
        from sqlalchemy import select
        res = await session.execute(select(User).where(User.username == u.get("username","")))
        existing = res.scalar_one_or_none()
        if existing:
            id_map[u["id"]] = existing.id
            p(WARN, f"Foydalanuvchi mavjud: {u.get('username')}")
            continue

        user = User(
            full_name   = u.get("name", "Nomsiz"),
            username    = u.get("username", f"user_{u['id']}"),
            hashed_password = hash_password(u.get("password", "12345")),
            role        = map_role(u.get("role","master")),
            phone       = u.get("phone"),
            balance     = float(u.get("balance", 0)),
            commission_percent = float(u.get("commission", 0)),
            is_active   = bool(u.get("active", True)) and not bool(u.get("fired", False)),
        )
        session.add(user)
        await session.flush()
        id_map[u["id"]] = user.id
        count += 1
    p(OK, f"Foydalanuvchilar: {count} ta yangi, {len(users_data)-count} ta mavjud")
    return id_map

async def import_clients(session, clients_data: list) -> dict:
    """Mijozlarni import qiladi. Returns: {old_id: new_id}"""
    id_map = {}
    count = 0
    for c in clients_data:
        client = Client(
            full_name   = c.get("name", "Noma'lum"),
            phone       = c.get("phone"),
            phone_secondary = c.get("phone2"),
            address     = c.get("address"),
            notes       = c.get("notes"),
            total_orders= int(c.get("totalOrders", 0)),
            total_spent = float(c.get("totalSpent", 0)),
            created_at  = parse_date(c.get("created")) or datetime.now(timezone.utc),
        )
        session.add(client)
        await session.flush()
        id_map[c["id"]] = client.id
        count += 1
    p(OK, f"Mijozlar: {count} ta import qilindi")
    return id_map

async def import_orders(session, orders_data: list, client_map: dict, user_map: dict) -> dict:
    """Buyurtmalarni import qiladi. Returns: {old_id: new_id}"""
    id_map = {}
    count = 0
    skipped = 0
    for o in orders_data:
        client_id = client_map.get(o.get("clientId"))
        if not client_id:
            p(WARN, f"Buyurtma {o.get('num')} uchun mijoz topilmadi, o'tkazib yuborildi")
            skipped += 1
            continue

        master_id   = user_map.get(o.get("masterId"))
        operator_id = user_map.get(o.get("operatorId"))

        order = Order(
            order_number        = o.get("num", f"TV-OLD-{o['id']:04d}"),
            client_id           = client_id,
            master_id           = master_id,
            operator_id         = operator_id,
            tv_brand            = o.get("tvBrand"),
            tv_model            = o.get("tvModel"),
            tv_diagonal         = o.get("tvDiagonal"),
            problem_description = o.get("problem", "Tavsif yo'q"),
            master_diagnosis    = o.get("diagnosis"),
            work_done           = o.get("workDone"),
            status              = map_status(o.get("status", "new")),
            source              = map_source(o.get("source", "walk_in")),
            estimated_price     = float(o.get("estimatedPrice", 0)),
            final_price         = float(o.get("finalPrice", 0)),
            parts_cost          = float(o.get("partsCost", 0)),
            is_paid             = bool(o.get("isPaid", False)),
            payment_method      = map_payment(o.get("payMethod")),
            cancel_reason       = o.get("cancelReason"),
            is_archived         = bool(o.get("archived", False)),
            created_at          = parse_date(o.get("createdAt")) or datetime.now(timezone.utc),
            updated_at          = parse_date(o.get("updatedAt")) or datetime.now(timezone.utc),
        )
        session.add(order)
        await session.flush()
        id_map[o["id"]] = order.id

        # Status tarixi
        for h in (o.get("history") or []):
            hist = OrderStatusHistory(
                order_id   = order.id,
                old_status = None,
                new_status = map_status(h.get("status", "new")),
                comment    = h.get("comment", ""),
                created_at = parse_date(h.get("date")) or datetime.now(timezone.utc),
            )
            session.add(hist)

        count += 1

    p(OK, f"Buyurtmalar: {count} ta import, {skipped} ta o'tkazib yuborildi")
    return id_map

async def import_transactions(session, trans_data: list, order_map: dict, user_map: dict):
    """Moliyaviy tranzaksiyalarni import qiladi."""
    count = 0
    for t in trans_data:
        t_type = TransactionType.INCOME if t.get("type")=="income" else TransactionType.EXPENSE
        # Oylik to'lovlari uchun
        if t.get("turi") == "oylik": t_type = TransactionType.SALARY

        trans = FinanceTransaction(
            transaction_type = t_type,
            amount           = float(t.get("amount", 0)),
            description      = t.get("desc", "—"),
            order_id         = order_map.get(t.get("orderId")),
            created_at       = parse_date(t.get("date")) or datetime.now(timezone.utc),
        )
        session.add(trans)
        count += 1
    p(OK, f"Tranzaksiyalar: {count} ta import qilindi")

async def import_settings(session, settings_data: dict, finance_data: dict):
    """Ustaxona sozlamalarini import qiladi."""
    from sqlalchemy import select
    res = await session.execute(select(ShopSettings))
    existing = res.scalar_one_or_none()

    balance = float(finance_data.get("balance", 0)) if finance_data else 0

    if existing:
        existing.shop_name    = settings_data.get("shopName", existing.shop_name)
        existing.phone        = settings_data.get("phone", existing.phone)
        existing.address      = settings_data.get("address", existing.address)
        existing.order_counter= int(settings_data.get("orderCounter", existing.order_counter))
        existing.total_balance= balance
        p(OK, f"Ustaxona sozlamalari yangilandi")
    else:
        s = ShopSettings(
            shop_name     = settings_data.get("shopName", "TV Ta'mirlash"),
            phone         = settings_data.get("phone"),
            address       = settings_data.get("address"),
            order_counter = int(settings_data.get("orderCounter", 0)),
            total_balance = balance,
        )
        session.add(s)
        p(OK, f"Ustaxona sozlamalari yaratildi")

# ================================================================
#  ASOSIY FUNKSIYA
# ================================================================

async def run_migration(json_file: str):
    print("\n" + "="*58)
    print("  TV CRM — localStorage → PostgreSQL Migration")
    print("="*58)

    # JSON faylni o'qish
    try:
        with open(json_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        p(OK, f"Fayl o'qildi: {json_file}")
        p(INFO, f"Eksport sanasi: {data.get('_exported','—')}")
    except FileNotFoundError:
        p(ERR, f"Fayl topilmadi: {json_file}")
        return
    except json.JSONDecodeError as e:
        p(ERR, f"JSON xatosi: {e}")
        return

    # Jadvallarni yaratish
    print(f"\n{INFO} Jadvallar yaratilmoqda...")
    await init_db()

    # Import
    async with AsyncSessionLocal() as session:
        async with session.begin():
            print(f"\n{INFO} Ma'lumotlar import qilinmoqda...\n")

            # 1. Sozlamalar
            await import_settings(
                session,
                data.get("settings") or {},
                data.get("finance") or {}
            )

            # 2. Foydalanuvchilar
            users  = data.get("users")  or []
            user_map = await import_users(session, users)

            # 3. Mijozlar
            clients = data.get("clients") or []
            client_map = await import_clients(session, clients)

            # 4. Buyurtmalar
            orders = data.get("orders") or []
            order_map = await import_orders(session, orders, client_map, user_map)

            # 5. Tranzaksiyalar
            transactions = data.get("transactions") or []
            await import_transactions(session, transactions, order_map, user_map)

    print("\n" + "="*58)
    print(f"  {OK} Migratsiya muvaffaqiyatli tugadi!")
    print("="*58)
    print(f"""
  Statistika:
    👥 Foydalanuvchilar : {len(users)} ta
    👤 Mijozlar         : {len(clients)} ta
    📋 Buyurtmalar      : {len(orders)} ta
    💰 Tranzaksiyalar   : {len(transactions)} ta
""")


def main():
    if len(sys.argv) > 1:
        json_file = sys.argv[1]
    else:
        print("\nJSON backup fayl yo'li:")
        json_file = input("  > ").strip()

    if not json_file:
        print(f"{ERR} Fayl yo'li kiritilmadi!")
        sys.exit(1)

    asyncio.run(run_migration(json_file))


if __name__ == "__main__":
    main()
