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
