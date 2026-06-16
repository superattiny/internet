# ================================================
# telegram_bot.py — Telegram Bot integratsiyasi
#
# Funksiyalar:
#   1. Bot ishga tushirish
#   2. Mijozdan xabar kelganda — CRM da zakaz ochish
#   3. Admin ga bildirishnoma yuborish
#   4. Zakaz statuslari haqida mijozga xabar
# ================================================

import asyncio
import logging
from typing import Optional
from datetime import datetime, timezone

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.utils.logger import logger


# ── Telegram API yordamchi ────────────────────────────────────
TELEGRAM_API = "https://api.telegram.org/bot"


async def send_message(
    chat_id: str,
    text: str,
    parse_mode: str = "HTML",
) -> bool:
    """
    Telegram ga xabar yuboradi.
    parse_mode: HTML yoki Markdown
    """
    if not settings.telegram_bot_token:
        logger.warning("Telegram token sozlanmagan!")
        return False

    url = f"{TELEGRAM_API}{settings.telegram_bot_token}/sendMessage"
    payload = {
        "chat_id":    chat_id,
        "text":       text,
        "parse_mode": parse_mode,
    }

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.post(url, json=payload)
            if r.status_code == 200:
                logger.info(f"✅ Telegram xabar yuborildi: chat_id={chat_id}")
                return True
            else:
                logger.error(f"❌ Telegram xato: {r.text}")
                return False
    except Exception as e:
        logger.error(f"❌ Telegram ulanish xatosi: {e}")
        return False


async def notify_admin_new_order(order) -> None:
    """
    Yangi zakaz ochilganda admin ga bildirishnoma yuboradi.
    """
    if not settings.telegram_chat_id:
        return

    client      = getattr(order, 'client', None)
    client_name = client.full_name if client else "Noma'lum"
    client_phone= client.phone if client else "—"
    deadline_str= order.deadline.strftime('%d.%m.%Y %H:%M') if order.deadline else "—"

    text = (
        f"🆕 <b>Yangi Zakaz!</b>\n\n"
        f"📋 Raqam: <code>{order.order_number}</code>\n"
        f"👤 Mijoz: {client_name}\n"
        f"📱 Telefon: {client_phone}\n"
        f"📺 Texnika: {order.tv_brand or ''} {order.tv_model or ''}\n"
        f"🔧 Muammo: {order.problem_description[:100]}...\n"
        f"⏰ Deadline: {deadline_str}\n"
        f"💰 Taxminiy narx: {order.estimated_price:,.0f} so'm\n"
    )

    await send_message(settings.telegram_chat_id, text)


async def notify_admin_status_changed(order, old_status: str, new_status: str, changed_by: str) -> None:
    """
    Zakaz statusi o'zgarganda admin ga xabar yuboradi.
    """
    if not settings.telegram_chat_id:
        return

    STATUS_EMOJI = {
        "new":        "🆕",
        "accepted":   "✅",
        "diagnosing": "🔍",
        "waiting":    "⏳",
        "on_the_way": "🚗",
        "in_repair":  "🔧",
        "done":       "✔️",
        "delivered":  "🎉",
        "cancelled":  "❌",
    }

    STATUS_UZ = {
        "new":        "Yangi",
        "accepted":   "Qabul qilindi",
        "diagnosing": "Diagnostika",
        "waiting":    "Kutilmoqda",
        "on_the_way": "Yo'lda",
        "in_repair":  "Ta'mirda",
        "done":       "Tayyor",
        "delivered":  "Topshirildi",
        "cancelled":  "Bekor qilindi",
    }

    old_emoji = STATUS_EMOJI.get(old_status, "❓")
    new_emoji = STATUS_EMOJI.get(new_status, "❓")
    old_label = STATUS_UZ.get(old_status, old_status)
    new_label = STATUS_UZ.get(new_status, new_status)

    client      = getattr(order, 'client', None)
    client_name = client.full_name if client else "—"
    now_str     = datetime.now().strftime('%d.%m.%Y %H:%M')

    text = (
        f"🔄 <b>Status o'zgardi</b>\n\n"
        f"📋 Zakaz: <code>{order.order_number}</code>\n"
        f"👤 Mijoz: {client_name}\n"
        f"{old_emoji} {old_label} → {new_emoji} {new_label}\n"
        f"👨‍💼 Kim o'zgartirdi: {changed_by}\n"
        f"🕐 Vaqt: {now_str}\n"
    )

    await send_message(settings.telegram_chat_id, text)


async def notify_admin_payment(order, amount: float, payment_method: str) -> None:
    """
    To'lov qabul qilinganda admin ga xabar yuboradi.
    """
    if not settings.telegram_chat_id:
        return

    METHOD_LABEL = {
        "cash":     "💵 Naqd",
        "card":     "💳 Karta",
        "transfer": "🏦 O'tkazma",
    }

    client      = getattr(order, 'client', None)
    client_name = client.full_name if client else "—"
    now_str     = datetime.now().strftime('%d.%m.%Y %H:%M')

    text = (
        f"💳 <b>To'lov qabul qilindi!</b>\n\n"
        f"📋 Zakaz: <code>{order.order_number}</code>\n"
        f"👤 Mijoz: {client_name}\n"
        f"💰 Summa: <b>{amount:,.0f} so'm</b>\n"
        f"💳 Usul: {METHOD_LABEL.get(payment_method, payment_method)}\n"
        f"🕐 Vaqt: {now_str}\n"
    )

    await send_message(settings.telegram_chat_id, text)


async def notify_overdue_orders(overdue_orders: list) -> None:
    """
    Muddati o'tgan zakazlar haqida admin ga eslatma yuboradi.
    Har kuni ertalab avtomatik ishga tushishi mumkin.
    """
    if not settings.telegram_chat_id or not overdue_orders:
        return

    text = f"⚠️ <b>Muddati o'tgan zakazlar: {len(overdue_orders)} ta</b>\n\n"

    for o in overdue_orders[:10]:
        client      = getattr(o, 'client', None)
        client_name = client.full_name if client else "—"
        text += f"❌ <code>{o.order_number}</code> — {client_name}\n"

    if len(overdue_orders) > 10:
        text += f"\n...va yana {len(overdue_orders) - 10} ta\n"

    text += f"\n🔗 CRM: http://localhost:5173/orders?only_overdue=true"

    await send_message(settings.telegram_chat_id, text)


# ── Webhook orqali xabar qabul qilish ────────────────────────
async def process_incoming_message(update: dict, db: AsyncSession) -> None:
    """
    Telegramdan kelgan xabarni qayta ishlaydi.
    Mijoz xabar yozsa — CRM da avtomatik zakaz ochadi.

    update — Telegram webhook dan kelgan JSON
    """
    try:
        message = update.get("message", {})
        if not message:
            return

        chat_id    = str(message.get("chat", {}).get("id", ""))
        text       = message.get("text", "")
        first_name = message.get("chat", {}).get("first_name", "")
        last_name  = message.get("chat", {}).get("last_name", "")
        username   = message.get("chat", {}).get("username", "")
        full_name  = f"{first_name} {last_name}".strip() or username or "Telegram mijoz"

        logger.info(f"📩 Telegram xabar: {full_name} ({chat_id}): {text[:50]}")

        # /start buyrug'i
        if text.startswith("/start"):
            await send_message(chat_id, (
                f"👋 Salom, <b>{full_name}</b>!\n\n"
                f"📺 <b>TV Ta'mirlash Ustaxonasiga xush kelibsiz!</b>\n\n"
                f"Televizoringiz nosoz bo'lsa, shunchaki yozing:\n"
                f"Masalan: <i>Samsung TV ekrani singan</i>\n\n"
                f"Biz siz bilan bog'lanamiz! 📞"
            ))
            return

        # /status buyrug'i
        if text.startswith("/status"):
            await send_message(chat_id, (
                f"📋 Zakazingiz holati haqida so'rash uchun\n"
                f"zakaz raqamingizni yuboring.\n"
                f"Masalan: <code>TV-2025-0001</code>"
            ))
            return

        # Oddiy xabar — mijoz muammosini yozmoqda
        # 1. Mijozni topish yoki yaratish
        from app.database.models import Client, Order, OrderStatus, OrderSource
        from sqlalchemy import select

        # Telegram ID bo'yicha mijozni qidirish
        result = await db.execute(
            select(Client).where(Client.telegram_id == chat_id)
        )
        client = result.scalar_one_or_none()

        if not client:
            # Yangi mijoz yaratish
            client = Client(
                full_name=full_name,
                telegram_id=chat_id,
                telegram_username=username,
                total_orders=0,
                total_spent=0.0,
            )
            db.add(client)
            await db.flush()
            logger.info(f"👤 Yangi Telegram mijoz: {full_name} ({chat_id})")

        # 2. Zakaz raqami generatsiya
        from app.database.models import ShopSettings
        settings_result = await db.execute(select(ShopSettings))
        shop = settings_result.scalar_one_or_none()
        if not shop:
            shop = ShopSettings()
            db.add(shop)
            await db.flush()

        shop.order_counter += 1
        order_number = f"TV-{datetime.now().year}-{shop.order_counter:04d}"

        # Deadline (3 kun keyin)
        from datetime import timedelta
        deadline = datetime.now(timezone.utc) + timedelta(days=3)

        # 3. Zakaz yaratish
        order = Order(
            order_number=order_number,
            client_id=client.id,
            problem_description=text,
            status=OrderStatus.NEW,
            source=OrderSource.TELEGRAM,
            estimated_price=0.0,
            final_price=0.0,
            parts_cost=0.0,
            is_paid=False,
            is_archived=False,
            deadline=deadline,
        )
        db.add(order)
        client.total_orders += 1

        # Status tarixi
        from app.database.models import OrderStatusHistory
        history = OrderStatusHistory(
            order_id=order.id if order.id else None,
            old_status=None,
            new_status=OrderStatus.NEW,
            comment="Telegram orqali zakaz ochildi",
        )

        await db.commit()
        await db.refresh(order)

        # 4. Mijozga tasdiqlash xabari
        await send_message(chat_id, (
            f"✅ <b>Zakazingiz qabul qilindi!</b>\n\n"
            f"📋 Zakaz raqami: <code>{order_number}</code>\n"
            f"🔧 Muammo: {text[:100]}\n"
            f"⏰ Taxminiy muddat: 3 kun\n\n"
            f"Tez orada siz bilan bog'lanamiz! 📞"
        ))

        # 5. Admin ga xabar
        await notify_admin_new_order(order)

        logger.info(f"✅ Telegram zakaz yaratildi: {order_number}")

    except Exception as e:
        logger.error(f"❌ Telegram xabar qayta ishlash xatosi: {e}")


async def setup_webhook(base_url: str) -> bool:
    """
    Telegram webhook ni sozlaydi.
    base_url — sizning server manzili (masalan: https://yourdomain.com)
    """
    if not settings.telegram_bot_token:
        logger.warning("Telegram token sozlanmagan!")
        return False

    webhook_url = f"{base_url}/api/v1/telegram/webhook"
    url = f"{TELEGRAM_API}{settings.telegram_bot_token}/setWebhook"

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.post(url, json={"url": webhook_url})
            data = r.json()
            if data.get("ok"):
                logger.info(f"✅ Telegram webhook sozlandi: {webhook_url}")
                return True
            else:
                logger.error(f"❌ Webhook xato: {data}")
                return False
    except Exception as e:
        logger.error(f"❌ Webhook ulanish xatosi: {e}")
        return False


async def check_bot_info() -> Optional[dict]:
    """
    Bot ma'lumotlarini tekshiradi.
    Token to'g'ri yoki yo'qligini aniqlaydi.
    """
    if not settings.telegram_bot_token:
        return None

    url = f"{TELEGRAM_API}{settings.telegram_bot_token}/getMe"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(url)
            data = r.json()
            if data.get("ok"):
                bot = data["result"]
                logger.info(f"✅ Bot: @{bot['username']} ({bot['id']})")
                return bot
    except Exception as e:
        logger.error(f"❌ Bot tekshiruvi xatosi: {e}")
    return None
