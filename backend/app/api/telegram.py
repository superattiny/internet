# ================================================
# api/telegram.py — Telegram Bot API
#
# Endpoint'lar:
#   POST /api/v1/telegram/webhook  ← Telegramdan xabar keladi
#   GET  /api/v1/telegram/status   ← Bot holati
#   POST /api/v1/telegram/test     ← Test xabar yuborish [Admin]
# ================================================

from fastapi import APIRouter, Request, HTTPException, status
from app.integrations.telegram_bot import (
    process_incoming_message,
    send_message,
    check_bot_info,
    notify_admin_new_order,
)
from app.utils.dependencies import AdminUser, DBSession
from app.config import settings
from app.utils.logger import logger

router = APIRouter(
    prefix="/telegram",
    tags=["📱 Telegram Bot"],
)


@router.post("/webhook")
async def telegram_webhook(request: Request, db: DBSession):
    """
    Telegram webhook — Telegramdan xabarlar shu yerga keladi.
    Bu URL Telegram ga ro'yxatdan o'tkazilishi kerak.
    """
    try:
        update = await request.json()
        logger.debug(f"Telegram webhook: {update}")
        await process_incoming_message(update, db)
        return {"ok": True}
    except Exception as e:
        logger.error(f"Webhook xato: {e}")
        return {"ok": False}


@router.get("/status")
async def bot_status(admin: AdminUser):
    """
    Bot ma'lumotlari va holati.
    """
    if not settings.telegram_bot_token:
        return {
            "configured": False,
            "message": "Telegram token .env faylida sozlanmagan"
        }

    bot_info = await check_bot_info()
    return {
        "configured": True,
        "bot": bot_info,
        "chat_id": settings.telegram_chat_id or "Sozlanmagan",
        "webhook_url": f"Sizning serveringiz/api/v1/telegram/webhook",
    }


@router.post("/test")
async def send_test_message(admin: AdminUser):
    """
    Admin test xabar yuboradi — bot ishlayotganini tekshirish.
    """
    if not settings.telegram_bot_token:
        raise HTTPException(
            status_code=400,
            detail="Telegram token sozlanmagan. .env faylini tekshiring."
        )
    if not settings.telegram_chat_id:
        raise HTTPException(
            status_code=400,
            detail="Telegram chat_id sozlanmagan. .env faylini tekshiring."
        )

    success = await send_message(
        settings.telegram_chat_id,
        "✅ <b>TV CRM</b> — Telegram bot ishlayapti!\n\n"
        "Siz bu xabarni olsangiz — bot to'g'ri sozlangan. 🎉"
    )

    if success:
        return {"success": True, "message": "Test xabar yuborildi!"}
    else:
        raise HTTPException(status_code=500, detail="Xabar yuborilmadi!")


@router.post("/notify/overdue")
async def notify_overdue(admin: AdminUser, db: DBSession):
    """
    Muddati o'tgan zakazlar haqida xabar yuborish.
    """
    from sqlalchemy import select, and_
    from app.database.models import Order, OrderStatus
    from app.utils.helpers import utc_now
    from app.integrations.telegram_bot import notify_overdue_orders

    now = utc_now()
    result = await db.execute(
        select(Order).where(
            and_(
                Order.deadline < now,
                Order.status.notin_([OrderStatus.DELIVERED, OrderStatus.CANCELLED]),
                Order.is_archived == False,
            )
        )
    )
    overdue = result.scalars().all()
    await notify_overdue_orders(overdue)

    return {"success": True, "overdue_count": len(overdue)}
