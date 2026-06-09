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
