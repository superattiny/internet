@echo off
echo ================================
echo   CRM Server ishga tushmoqda...
echo ================================
echo.

cd /d "%~dp0"

echo ws moduli tekshirilmoqda...
npm install ws --silent

echo.
echo ✅ Server ishga tushdi!
echo 📡 WS:   ws://127.0.0.1:8080
echo 📬 HTTP: http://127.0.0.1:8081
echo.
echo Bu oynani yopmang! (minimumga tushurishingiz mumkin)
echo.

node server.js

pause
