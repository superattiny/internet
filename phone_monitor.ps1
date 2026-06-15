# Phone Link qo'ng'iroqlarini kuzatib CRM ga yuboradi
# O'rnatish: Task Scheduler yoki fon rejimida ishga tushiring

Add-Type -AssemblyName System.Runtime.WindowsRuntime

$serverUrl = "http://127.0.0.1:8081"

# Windows bildirishnomalarni kuzatish uchun
$source = @"
using System;
using System.Runtime.InteropServices;
public class ToastWatcher {
    public delegate void CallbackDelegate(string text);
    public static event CallbackDelegate OnNotification;
    
    public static void Start() {
        // Windows Notification listener
    }
}
"@

# Oddiy polling usuli - Windows Event Log orqali
function Watch-PhoneLink {
    Write-Host "📞 Phone Link kuzatilmoqda..." -ForegroundColor Cyan
    
    $lastId = 0
    
    while ($true) {
        try {
            # Windows Application log dan Phone Link voqealarini olish
            $events = Get-WinEvent -FilterHashtable @{
                LogName = 'Microsoft-Windows-PushNotification-Platform/Operational'
                StartTime = (Get-Date).AddSeconds(-5)
            } -ErrorAction SilentlyContinue
            
            foreach ($event in $events) {
                $msg = $event.Message
                # Telefon raqamini topamiz
                $match = [regex]::Match($msg, '\+?[\d\s\-\(\)]{9,15}')
                if ($match.Success -and $event.Id -ne $lastId) {
                    $number = $match.Value -replace '[\s\-\(\)]', ''
                    $lastId = $event.Id
                    Write-Host "📞 Qongiroq: $number" -ForegroundColor Green
                    
                    # CRM ga yuborish
                    try {
                        Invoke-RestMethod -Uri $serverUrl -Method Post `
                            -Body $number -ContentType "text/plain" -TimeoutSec 2
                    } catch {
                        Write-Host "Server ulanmagan" -ForegroundColor Red
                    }
                }
            }
        } catch {}
        
        Start-Sleep -Seconds 2
    }
}

# Test uchun qo'lda raqam yuborish
function Send-TestCall {
    param([string]$Number = "+998901234567")
    Write-Host "Test: $Number yuborilmoqda..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri $serverUrl -Method Post -Body $Number -ContentType "text/plain"
    Write-Host "✅ Yuborildi!" -ForegroundColor Green
}

# Ishga tushirish
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Phone Link → CRM Ko'prigi" -ForegroundColor Cyan  
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Buyruqlar:" -ForegroundColor Yellow
Write-Host "  Watch-PhoneLink  - Kuzatishni boshlash"
Write-Host "  Send-TestCall    - Test qo'ng'iroq yuborish"
Write-Host "  Send-TestCall '+998901234567' - Raqam bilan test"
Write-Host ""

# Avtomatik kuzatishni boshlash
Watch-PhoneLink
