# Arka Plan Bildirim Testi

## PowerShell komutunu çalıştır:

Invoke-WebRequest -Uri "https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/send-fcm-notification" -Method POST -Headers @{"Authorization"="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY3MjgyOSwiZXhwIjoyMDc2MjQ4ODI5fQ.-_kJYS1oba6vsC4OuTccK9gAVLySigjCI_pHOuvtHt0"; "Content-Type"="application/json"} -Body "{}"

## Beklenen Sonuç:
- 🔔 Telefonda bildirim sesi
- 📳 Titreşim  
- 📱 Notification tray'de bildirim görünür
- 💬 Başlık: "🎉 TEST BİLDİRİMİ"
- 📝 Mesaj: "Yeni teslimat isteği var! Bu gerçek bir FCM bildirimidir."
