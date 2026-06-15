# CRM + Phone Link - O'rnatish yo'riqnomasi

## 1-qadam: Node.js o'rnatish
https://nodejs.org → "LTS" versiyani yuklab o'rnating

## 2-qadam: ws moduli o'rnatish
```
Win+R → cmd → Enter
cd C:\Users\SIZNING_PAPKA\internet
npm install ws
```

## 3-qadam: Server ishga tushirish
```
node server.js
```
Ekranda ko'rinishi kerak:
✅ Server ishga tushdi
📡 WS:   ws://127.0.0.1:8080
📬 HTTP: http://127.0.0.1:8081

## 4-qadam: PowerShell kuzatuvchi
```
Win+X → Windows PowerShell (Admin)
Set-ExecutionPolicy RemoteSigned
cd C:\Users\SIZNING_PAPKA\internet
.\phone_monitor.ps1
```

## 5-qadam: CRM ni oching
CRM_Tizimi.html ni brauzerda oching
Pastda o'ng tomonda 📞 tugma ko'rinadi

## TEST qilish:
PowerShell oynasida:
```
Send-TestCall "+998901234567"
```
CRM da modal ochilishi kerak!

## Muammo bo'lsa:
- server.js ishlaydimi? → cmd da `node server.js`
- Port band? → `netstat -ano | findstr 8080`
- PowerShell xato? → Admin huquqi bilan oching
