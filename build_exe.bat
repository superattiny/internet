@echo off
echo ================================
echo   CRM .EXE yasalmoqda...
echo ================================
echo.

pip install pywebview pyinstaller --quiet

pyinstaller --onefile --windowed --name "TV_CRM" --add-data "CRM_Tizimi.html;." run.py

echo.
echo ✅ Tayyor! dist\TV_CRM.exe faylini oching
pause
