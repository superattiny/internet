"""
TV CRM - Windows o'rnatish skripti
Ishlatilishi: python setup_windows.py
"""

import os, sys, subprocess, platform, shutil

GREEN='\033[92m'; YELLOW='\033[93m'; RED='\033[91m'
BLUE='\033[94m'; BOLD='\033[1m'; NC='\033[0m'

def ok(m):     print(f"{GREEN}[OK]{NC}    {m}")
def info(m):   print(f"{BLUE}[INFO]{NC}  {m}")
def warn(m):   print(f"{YELLOW}[WARN]{NC}  {m}")
def error(m):  print(f"{RED}[ERROR]{NC} {m}")
def header(m): print(f"\n{BOLD}{BLUE}=== {m} ==={NC}")

print(f"\n{BOLD}{BLUE}╔══════════════════════════════════════╗")
print(f"║   📺  TV CRM — Windows Setup         ║")
print(f"╚══════════════════════════════════════╝{NC}\n")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND  = os.path.join(BASE_DIR, 'backend')
FRONTEND = os.path.join(BASE_DIR, 'frontend')

# 1. Python
header("Python tekshiruvi")
ver = sys.version_info
if ver.major < 3 or (ver.major==3 and ver.minor < 9):
    error(f"Python 3.9+ kerak. Sizda: {ver.major}.{ver.minor}")
    sys.exit(1)
ok(f"Python {ver.major}.{ver.minor}.{ver.micro}")

# 2. Node.js
header("Node.js tekshiruvi")
try:
    node = subprocess.run(['node','--version'], capture_output=True, text=True)
    npm  = subprocess.run(['npm','--version'],  capture_output=True, text=True)
    ok(f"Node.js {node.stdout.strip()}")
    ok(f"npm {npm.stdout.strip()}")
except FileNotFoundError:
    error("Node.js topilmadi! https://nodejs.org dan o'rnating")
    sys.exit(1)

# 3. Virtual muhit
header("Backend o'rnatilmoqda")
venv_dir = os.path.join(BACKEND, 'venv')
if not os.path.exists(venv_dir):
    info("Virtual muhit yaratilmoqda...")
    subprocess.run([sys.executable, '-m', 'venv', venv_dir], check=True)
    ok("Virtual muhit yaratildi")
else:
    ok("Virtual muhit mavjud")

pip_path    = os.path.join(venv_dir, 'Scripts', 'pip.exe')
python_path = os.path.join(venv_dir, 'Scripts', 'python.exe')

# 4. Kutubxonalar
info("Python kutubxonalari o'rnatilmoqda (2-3 daqiqa)...")
subprocess.run([pip_path, 'install', '--upgrade', 'pip', '-q'], check=True)
subprocess.run([pip_path, 'install', '-r',
    os.path.join(BACKEND,'requirements.txt'), '-q'], check=True)
ok("Python kutubxonalari o'rnatildi")

# 5. .env
env_file = os.path.join(BACKEND, '.env')
if not os.path.exists(env_file):
    shutil.copy(os.path.join(BACKEND, '.env.example'), env_file)
    ok(".env fayli yaratildi")

# 6. Database
info("Ma'lumotlar bazasi yaratilmoqda...")
r = subprocess.run([python_path, '-m', 'app.database.migrations.init_db'],
    cwd=BACKEND, capture_output=True, text=True)
if r.returncode == 0:
    ok("Ma'lumotlar bazasi tayyor! (admin/admin123)")
else:
    warn("DB xato:")
    print(r.stderr[-300:] if r.stderr else "")

# 7. Frontend
header("Frontend o'rnatilmoqda")
subprocess.run(['npm', 'install', '--silent'], cwd=FRONTEND, check=True)
ok("npm paketlari o'rnatildi")

# 8. .bat fayllar yaratish
header("Ishga tushirish fayllar yaratilmoqda")

with open(os.path.join(BASE_DIR,'START_CRM.bat'),'w') as f:
    f.write(f'@echo off\ntitle TV CRM\n')
    f.write(f'start "Backend"  cmd /k "cd /d {BACKEND} && venv\\Scripts\\activate && python run.py"\n')
    f.write(f'timeout /t 4 /nobreak >nul\n')
    f.write(f'start "Frontend" cmd /k "cd /d {FRONTEND} && npm run dev"\n')
    f.write(f'timeout /t 6 /nobreak >nul\n')
    f.write(f'start http://localhost:5173\n')
    f.write(f'echo CRM ishga tushdi! http://localhost:5173\npause\n')
ok("START_CRM.bat yaratildi")

print(f"""
{BOLD}{GREEN}
╔══════════════════════════════════════════════════════╗
║      ✅  O'RNATISH MUVAFFAQIYATLI YAKUNLANDI!        ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  👉 START_CRM.bat faylini 2x bosing                  ║
║     (avtomatik backend + frontend ochiladi)          ║
║                                                      ║
║  🌐 http://localhost:5173                            ║
║  🔑 Login: admin  |  Parol: admin123                 ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
{NC}""")
