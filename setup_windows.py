"""
TV CRM - Windows o'rnatish skripti
Ishlatilishi: python setup_windows.py
"""

import os, sys, subprocess, shutil

GREEN='\033[92m'; YELLOW='\033[93m'; RED='\033[91m'
BLUE='\033[94m'; BOLD='\033[1m'; NC='\033[0m'

def ok(m):     print(f"{GREEN}[OK]{NC}    {m}")
def info(m):   print(f"{BLUE}[INFO]{NC}  {m}")
def warn(m):   print(f"{YELLOW}[WARN]{NC}  {m}")
def error(m):  print(f"{RED}[ERROR]{NC} {m}"); input("Enter bosing..."); sys.exit(1)
def header(m): print(f"\n{BOLD}{BLUE}=== {m} ==={NC}")

print(f"\n{BOLD}{BLUE}╔══════════════════════════════════════╗")
print(f"║   📺  TV CRM — Windows Setup         ║")
print(f"╚══════════════════════════════════════╝{NC}\n")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND  = os.path.join(BASE_DIR, 'backend')
FRONTEND = os.path.join(BASE_DIR, 'frontend')

# ── 1. Python 3.11 topish ─────────────────────────────────────
header("Python 3.11 tekshiruvi")

PYTHON_CMD = None

# py launcher orqali 3.11 ni topish
for try_cmd in [['py', '-3.11'], ['python3.11'], ['python3'], ['python']]:
    try:
        r = subprocess.run(try_cmd + ['--version'], capture_output=True, text=True)
        ver_str = r.stdout.strip() + r.stderr.strip()
        if 'Python 3.11' in ver_str or 'Python 3.10' in ver_str or 'Python 3.12' in ver_str or 'Python 3.13' in ver_str:
            PYTHON_CMD = try_cmd
            ok(f"Python topildi: {ver_str.strip()} ({' '.join(try_cmd)})")
            break
        elif 'Python 3.14' in ver_str:
            warn(f"Python 3.14 pydantic bilan mos emas, 3.11 ni qidiryapmiz...")
    except FileNotFoundError:
        continue

if not PYTHON_CMD:
    # Oxirgi urinish — py -3.11
    try:
        r = subprocess.run(['py', '-3.11', '--version'], capture_output=True, text=True)
        if '3.11' in r.stdout + r.stderr:
            PYTHON_CMD = ['py', '-3.11']
            ok(f"Python 3.11 topildi!")
    except:
        pass

if not PYTHON_CMD:
    error("""Python 3.11 topilmadi!
    
    Yuklab oling: https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    O'rnatayotganda: 'Add Python to PATH' katakchasini belgilang!
    
    O'rnatib bo'lgach, bu skriptni qayta ishlatign.""")

# ── 2. Node.js topish ─────────────────────────────────────────
header("Node.js tekshiruvi")

NODE_EXE = None
NPM_EXE  = None

for p in [r"C:\Program Files\nodejs", r"C:\Program Files (x86)\nodejs"]:
    if os.path.exists(os.path.join(p, 'node.exe')):
        NODE_EXE = os.path.join(p, 'node.exe')
        NPM_EXE  = os.path.join(p, 'npm.cmd')
        os.environ['PATH'] = p + os.pathsep + os.environ.get('PATH','')
        break

if not NODE_EXE:
    NODE_EXE = shutil.which('node')
    NPM_EXE  = shutil.which('npm') or shutil.which('npm.cmd')

if not NODE_EXE:
    error("Node.js topilmadi! https://nodejs.org dan LTS versiyasini o'rnating.")

node_ver = subprocess.run([NODE_EXE,'--version'], capture_output=True, text=True)
npm_ver  = subprocess.run([NPM_EXE, '--version'], capture_output=True, text=True)
ok(f"Node.js {node_ver.stdout.strip()}")
ok(f"npm     {npm_ver.stdout.strip()}")
NODE_DIR = os.path.dirname(NODE_EXE)

# ── 3. Virtual muhit ──────────────────────────────────────────
header("Backend o'rnatilmoqda")
venv_dir    = os.path.join(BACKEND, 'venv')
python_path = os.path.join(venv_dir, 'Scripts', 'python.exe')

# Eski venv ni o'chirish
if os.path.exists(venv_dir):
    info("Eski virtual muhit o'chirilmoqda...")
    shutil.rmtree(venv_dir)

info("Virtual muhit yaratilmoqda (Python 3.11)...")
subprocess.run(PYTHON_CMD + ['-m', 'venv', venv_dir], check=True)
ok("Virtual muhit yaratildi")

# ── 4. pip va kutubxonalar ────────────────────────────────────
info("Python kutubxonalari o'rnatilmoqda (3-5 daqiqa)...")
subprocess.run([python_path, '-m', 'pip', 'install', '--upgrade', 'pip', '-q'])
result = subprocess.run(
    [python_path, '-m', 'pip', 'install', '-r',
     os.path.join(BACKEND, 'requirements.txt')],
    capture_output=True, text=True
)
if result.returncode != 0:
    warn("Xato:")
    print(result.stderr[-500:])
    error("Kutubxonalar o'rnatilmadi!")
ok("Python kutubxonalari o'rnatildi")

# ── 5. .env ───────────────────────────────────────────────────
env_file = os.path.join(BACKEND, '.env')
if not os.path.exists(env_file):
    shutil.copy(os.path.join(BACKEND, '.env.example'), env_file)
    ok(".env fayli yaratildi")

# ── 6. Ma'lumotlar bazasi ─────────────────────────────────────
info("Ma'lumotlar bazasi yaratilmoqda...")
r = subprocess.run(
    [python_path, '-m', 'app.database.migrations.init_db'],
    cwd=BACKEND, capture_output=True, text=True
)
if r.returncode == 0:
    ok("Ma'lumotlar bazasi tayyor! (admin / admin123)")
else:
    warn("DB ogohlantirish (kritik emas):")
    print(r.stderr[-200:] if r.stderr else "")

# ── 7. Frontend ───────────────────────────────────────────────
header("Frontend o'rnatilmoqda")
r2 = subprocess.run([NPM_EXE, 'install'], cwd=FRONTEND, capture_output=True, text=True)
if r2.returncode != 0:
    warn(r2.stderr[-200:])
ok("npm paketlari o'rnatildi")

# ── 8. START_CRM.bat ──────────────────────────────────────────
header("Ishga tushirish fayli yaratilmoqda")
bat = os.path.join(BASE_DIR, 'START_CRM.bat')
with open(bat, 'w', encoding='utf-8') as f:
    f.write('@echo off\n')
    f.write('title 📺 TV CRM\n')
    f.write(f'set PATH={NODE_DIR};%PATH%\n\n')
    f.write('echo TV CRM ishga tushmoqda...\n\n')
    f.write(f'start "Backend"  cmd /k "cd /d {BACKEND} && venv\\Scripts\\activate && python run.py"\n')
    f.write('timeout /t 5 /nobreak >nul\n')
    f.write(f'start "Frontend" cmd /k "cd /d {FRONTEND} && set PATH={NODE_DIR};%%PATH%% && npm run dev"\n')
    f.write('timeout /t 8 /nobreak >nul\n')
    f.write('start http://localhost:5173\n')
    f.write('echo.\n')
    f.write('echo ✅ CRM ishga tushdi! http://localhost:5173\n')
    f.write('echo 🔑 Login: admin   Parol: admin123\n')
    f.write('pause\n')
ok("START_CRM.bat yaratildi")

print(f"""
{BOLD}{GREEN}
╔══════════════════════════════════════════════════════╗
║      ✅  O'RNATISH MUVAFFAQIYATLI YAKUNLANDI!        ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  👉  START_CRM.bat  faylini 2x bosing!               ║
║                                                      ║
║  🌐  http://localhost:5173                           ║
║  🔑  Login: admin   |   Parol: admin123              ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
{NC}""")
input("Enter bosing...")
