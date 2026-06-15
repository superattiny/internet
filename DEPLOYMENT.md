# 🚀 TV CRM — Server va Domen Qo'llanmasi

## Umumiy ko'rinish

```
Internet
    ↓
Domen (sizning-crm.uz)
    ↓
Nginx (80/443)
    ├── /          → HTML CRM (/var/www/crm)
    ├── /api/*     → FastAPI (port 8000)
    └── /ws        → Bot Server (port 8080)
```

---

## 📋 BOSQICHMA-BOSQICH QO'LLANMA

### 1-QADAM: VPS Tanlash va Sozlash

**Tavsiya etilgan serverlar (arzon):**

| Provider | Narx | RAM | Disk | Joylashuv |
|----------|------|-----|------|-----------|
| [Hetzner](https://hetzner.com) | ~$4/oy | 2GB | 20GB SSD | Germaniya |
| [DigitalOcean](https://digitalocean.com) | $6/oy | 1GB | 25GB SSD | AQSh/EU |
| [Linode](https://linode.com) | $5/oy | 1GB | 25GB SSD | AQSh |
| O'zbekiston (UzCloud) | ~$8/oy | 2GB | 40GB | Toshkent |

**Minimal tavsiyalar:**
- OS: Ubuntu 22.04 LTS
- RAM: 1GB (2GB tavsiya)
- Disk: 20GB SSD
- CPU: 1 vCPU

---

### 2-QADAM: Serverni tayyorlash

SSH orqali ulaning:
```bash
ssh root@SERVER_IP
```

Yangilash va asosiy paketlar:
```bash
# Tizimni yangilash
apt update && apt upgrade -y

# Kerakli paketlar
apt install -y git nginx certbot python3-certbot-nginx \
               python3.11 python3.11-venv python3-pip \
               postgresql-16 postgresql-client-16

# Node.js 20 o'rnatish
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Versiyalarni tekshirish
python3 --version  # Python 3.11.x
node --version     # v20.x.x
psql --version     # PostgreSQL 16.x
nginx -v           # nginx 1.x.x
```

---

### 3-QADAM: PostgreSQL sozlash

```bash
# PostgreSQL ishga tushirish
systemctl start postgresql
systemctl enable postgresql

# Database yaratish
sudo -u postgres psql << 'EOF'
CREATE USER crm_user WITH PASSWORD 'kuchli_parol_bu_yerga';
CREATE DATABASE tv_crm OWNER crm_user;
GRANT ALL PRIVILEGES ON DATABASE tv_crm TO crm_user;
\q
EOF

echo "✅ PostgreSQL tayyor"
echo "Connection string: postgresql://crm_user:PAROL@localhost:5432/tv_crm"
```

---

### 4-QADAM: Loyihani serverga yuklash

```bash
# Papka yaratish
mkdir -p /var/www/crm
cd /var/www/crm

# GitHub dan yuklab olish
git clone https://github.com/superattiny/internet.git .

# Python virtual muhit
cd backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Node.js paketlari
npm install --production

# .env faylini yaratish
cp .env .env.backup
nano .env  # Pastdagi ma'lumotlarni kiriting
```

**`.env` fayl to'ldirish:**
```bash
# ── Python Backend ─────────────────────────────────────────────
APP_NAME=TV Ta'mirlash CRM
DEBUG=false
SECRET_KEY=JUDA_KUCHLI_MAXFIY_KALIT_BU_YERGA_64_BELGI

DATABASE_URL=postgresql://crm_user:PAROL@localhost:5432/tv_crm
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=480
FRONTEND_URL=https://sizning-crm.uz

# ── Bot Server (Node.js) ────────────────────────────────────────
TELEGRAM_BOT_TOKEN=1234567890:AAF...  # BotFather dan
TELEGRAM_ADMIN_CHAT_ID=123456789     # userinfobot dan
GEMINI_API_KEY=AIza...               # aistudio.google.com
AUTO_REPLY_ENABLED=true
SHOP_NAME=TV Ta'mirlash Ustaxonasi
WS_PORT=8080
```

---

### 5-QADAM: Ma'lumotlar bazasini ishga tushirish

```bash
cd /var/www/crm/backend
source venv/bin/activate

# Jadvallar yaratish va boshlang'ich ma'lumotlar
python -m app.database.migrations.init_db

# Yoki HTML dan eksport qilingan JSON import
python db_migrate.py /path/to/crm_backup_2025.json
```

---

### 6-QADAM: Nginx sozlash

```bash
# Nginx konfiguratsiyasini ko'chirish
cp /var/www/crm/backend/nginx.conf /etc/nginx/sites-available/crm

# Domenni o'zgartiring!
nano /etc/nginx/sites-available/crm
# "sizning-domen.uz" o'rniga o'z domeningizni yozing

# Faollashtirish
ln -sf /etc/nginx/sites-available/crm /etc/nginx/sites-enabled/
nginx -t  # Konfiguratsiyani tekshirish
systemctl reload nginx
```

---

### 7-QADAM: SSL Sertifikat (HTTPS, Bepul!)

```bash
# Let's Encrypt sertifikat olish
certbot --nginx -d sizning-crm.uz -d www.sizning-crm.uz \
        --email sizning@email.com --agree-tos --non-interactive

# Avtomatik yangilanish tekshirish
certbot renew --dry-run

# Crontab ga qo'shish (har 2 oyda avtomatik yangilansin)
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
```

---

### 8-QADAM: Xizmatlarni sozlash (Systemd)

```bash
# Xizmat fayllarini ko'chirish
cp /var/www/crm/backend/crm-api.service /etc/systemd/system/
cp /var/www/crm/backend/crm-bot.service /etc/systemd/system/

# Ruxsatlarni sozlash
chown -R www-data:www-data /var/www/crm

# Faollashtirish
systemctl daemon-reload
systemctl enable crm-api crm-bot
systemctl start  crm-api crm-bot

# Holat tekshirish
systemctl status crm-api
systemctl status crm-bot
```

---

### 9-QADAM: Domen sozlash

DNS provayder panelida (masalan: reg.uz, nic.uz):

| Tur | Nom | Qiymat |
|-----|-----|--------|
| A | `@` | `SERVER_IP` |
| A | `www` | `SERVER_IP` |

> ⚠️ DNS tarqalishi 1-24 soat vaqt olishi mumkin.

---

### 10-QADAM: Telegram Bot sozlash

```bash
# 1. BotFather da yangi bot yarating
# t.me/BotFather → /newbot → nom bering → token oling

# 2. Admin chat ID ni biling
# t.me/userinfobot ga /start yuboring

# 3. Webhook o'rniga polling ishlatiladi (server.js da allaqachon bor)

# 4. Bot xabarlarini tekshirish
sudo journalctl -u crm-bot -f
```

---

## 📊 Monitoring buyruqlari

```bash
# Barcha xizmatlar holati
systemctl status crm-api crm-bot nginx postgresql

# Live loglar
journalctl -u crm-api -f   # FastAPI loglari
journalctl -u crm-bot -f   # Bot loglari
tail -f /var/log/nginx/access.log  # Nginx

# Disk va xotira
df -h
free -h
htop

# PostgreSQL tekshirish
sudo -u postgres psql -c "SELECT version();"
```

---

## 🔄 Yangilash (Deploy)

```bash
cd /var/www/crm
git pull origin main
cd backend
source venv/bin/activate
pip install -r requirements.txt -q
npm install --production --silent
systemctl restart crm-api crm-bot
```

**Yoki GitHub Actions orqali avtomatik** (`.github/workflows/deploy.yml`):

GitHub → Settings → Secrets → Actions:
- `SERVER_HOST` = `SERVER_IP`
- `SERVER_USER` = `root` yoki `www-data`
- `SERVER_SSH_KEY` = SSH private key
- `SERVER_PORT` = `22`

---

## 🔒 Xavfsizlik

```bash
# Firewall sozlash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable

# SSH kalitlar bilan (parolsiz)
# Mahalliy kompyuterda:
ssh-keygen -t ed25519 -C "crm-server"
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@SERVER_IP
```

---

## 💰 Xarajatlar hisob-kitobi

| Narsa | Narx/oy |
|-------|---------|
| VPS (Hetzner CX22) | ~$4 |
| Domen (.uz yoki .com) | ~$1 |
| SSL Sertifikat | **Bepul** (Let's Encrypt) |
| Telegram Bot | **Bepul** |
| Gemini AI (2M token) | **Bepul** |
| **Jami** | **~$5/oy** |

---

## 🆘 Yordam

Muammo bo'lsa:
```bash
# Xizmatni qayta ishga tushiring
systemctl restart crm-api

# Xatolarni tekshiring
journalctl -u crm-api -n 50 --no-pager

# Nginx xatolarini tekshiring
nginx -t
cat /var/log/nginx/error.log | tail -20
```
