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
