# 📺 TV Ta'mirlash Ustaxonasi — CRM Tizimi

Professional, modulli va oylik to'lovsiz shaxsiy CRM tizimi.

## 🚀 Tezkor boshlash

### Backend (Python/FastAPI)
```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env       # .env faylini tahrirlang
python run.py
```

### Frontend (React/Vite)
```bash
cd frontend
npm install
npm run dev
```

## 🏗️ Arxitektura
- **Backend:** FastAPI + SQLAlchemy + SQLite
- **Frontend:** React + Vite + Tailwind CSS
- **Auth:** JWT Token

## 📋 Bosqichlar
- [x] 1-Bosqich: Poydevor va Ma'lumotlar Bazasi
- [ ] 2-Bosqich: Zakazlar va Mijozlar moduli
- [ ] 3-Bosqich: Moliya va Ombor moduli
- [ ] 4-Bosqich: Telegram/Instagram integratsiya
- [ ] 5-Bosqich: AI (Gemini) integratsiya
- [ ] 6-Bosqich: IP-Telefoniya integratsiya
- [ ] 7-Bosqich: Mobile (PWA) versiya
