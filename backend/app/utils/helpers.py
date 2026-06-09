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
