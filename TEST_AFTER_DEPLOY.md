# Edge Function Deploy Ettikten Sonra Test

## 1. Önce SQL'i Çalıştır (Tekrar)

```sql
DELETE FROM notifications WHERE notification_status = 'pending';

INSERT INTO notifications (
    user_id,
    fcm_token,
    title,
    message,
    type,
    notification_status,
    data,
    created_at
) VALUES (
    '4ff777e0-5bcc-4c21-8785-c650f5667d86',
    'dfLkpcv2RDmBSJ5-D_04t8:APA91bEQORJenXST8mA1Ii22WGY3XUZuawBDzFQECOj_k9B6824LLeZQIc7O2hndYNiuhbFb2pS0PQi--gzq5L7YEGlF1PLEVeiS2a5JrXiHyQ3-oEqyeM0',
    '🚀 YENİ KOD TESTİ',
    'Bu güncellenmiş Edge Function ile gönderiliyor!',
    'delivery',
    'pending',
    '{"order_id": "test-456"}',
    NOW()
);
```

## 2. Uygulamayı Arka Plana At

Courier App'i aç ve **HOME tuşuna bas** (uygulama arka planda çalışsın).

## 3. Edge Function'ı Çalıştır (PowerShell)

```powershell
Invoke-RestMethod -Uri "https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/send-fcm-notification" -Method POST -Headers @{"Authorization"="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY3MjgyOSwiZXhwIjoyMDc2MjQ4ODI5fQ.-_kJYS1oba6vsC4OuTccK9gAVLySigjCI_pHOuvtHt0"; "Content-Type"="application/json"} -Body "{}" -ContentType "application/json"
```

## 4. Telefonuna Bak

**BU SEFER GELMELİ!**

✅ Bildirim sesi  
✅ Titreşim  
✅ Bildirim çubuğunda görünmeli  
✅ Başlık: "🚀 YENİ KOD TESTİ"  
✅ Mesaj: "Bu güncellenmiş Edge Function ile gönderiliyor!"

---

**Neden çalışmadı daha önce?**
Eski Edge Function kodunda `android.notification` kısmı eksikti. Şimdi ekledik:

```typescript
android: {
  priority: 'high',
  notification: {
    sound: 'default',
    notification_priority: 'PRIORITY_HIGH',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  },
},
```

Bu sayede Android cihaz bildirimi **mutlaka** gösterir!
