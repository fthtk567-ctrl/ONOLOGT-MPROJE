# 📊 SUPABASE LOGS TAKİP REHBERİ

## 1. Supabase Dashboard'da Logs Takibi

### Database Logs Sorgusu:
```sql
-- Son 10 trigger çalışmasını gör
SELECT 
  cast(timestamp as datetime) as zaman,
  event_message as mesaj
FROM edge_logs 
WHERE event_message LIKE '%Bildirim hazırlandı%' 
   OR event_message LIKE '%FCM Komutu%'
ORDER BY timestamp DESC 
LIMIT 10;
```

### Notifications Tablosu Kontrolü:
```sql
-- Son oluşturulan bildirimler
SELECT 
  n.created_at,
  n.title,
  n.message,
  u.full_name as kurye_adi
FROM notifications n
JOIN users u ON u.id = n.user_id
WHERE n.type = 'delivery'
ORDER BY n.created_at DESC
LIMIT 5;
```

### Delivery Requests Kontrolü:
```sql
-- Son teslimat istekleri
SELECT 
  dr.id,
  dr.created_at,
  dr.courier_id,
  dr.declared_amount,
  dr.courier_payment_due,
  u.full_name as kurye_adi
FROM delivery_requests dr
LEFT JOIN users u ON u.id = dr.courier_id
ORDER BY dr.created_at DESC
LIMIT 5;
```

## 2. Test Adımları

### A) Admin Panel'de Test:
1. Admin Panel aç: `cd c:\onlog_projects\onlog_admin_panel && flutter run -d chrome`
2. Delivery Requests sayfasına git
3. Yeni teslimat isteği oluştur
4. Courıer seç, amount gir, kaydet

### B) Supabase'de Kontrol:
1. Logs sekmesine git
2. Yukarıdaki SQL'leri çalıştır
3. Trigger çalıştı mı kontrol et

### C) Courier App'te Kontrol:
1. Courier App aç: `cd c:\onlog_projects\onlog_courier_app && flutter run`
2. Bildirim geldi mi kontrol et
3. Notifications ekranında görünüyor mu kontrol et

## 3. Beklenen Log Mesajları

### ✅ Başarılı Trigger:
```
✅ Bildirim hazırlandı: Courier=12345, Merchant=Ahmet'in Marketi
📱 FCM Komutu: curl -X POST https://fcm.googleapis.com/fcm/send...
```

### ❌ Hata Durumları:
```
❌ Kurye FCM token bulunamadı: 12345
ERROR: relation "delivery_requests" does not exist
```

## 4. Troubleshooting

### FCM Token Yoksa:
```sql
-- Kurye FCM tokenlarını kontrol et
SELECT id, full_name, fcm_token 
FROM users 
WHERE role = 'courier' 
AND fcm_token IS NOT NULL;
```

### Trigger Çalışmıyorsa:
```sql
-- Trigger var mı kontrol et
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notify_courier_simple';
```

## 5. Manuel FCM Test

Eğer otomatik sistem çalışmıyorsa, logs'tan çıkan curl komutunu kopyala ve çalıştır:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
-H "Authorization: key=AIzaSyBWO_lr-73AxfBlulvRD0W_wA0fzuTHAXg" \
-H "Content-Type: application/json" \
-d '{"to":"KURYE_FCM_TOKEN","notification":{"title":"Test","body":"Manuel test"}}'
```

## 6. Sistem Durumu

✅ **Çalışan Özellikler:**
- Database trigger sistemi
- FCM token kaydetme
- Notification tablosuna kayıt
- Log sistemi

🔄 **Geliştirilecek:**
- Otomatik FCM gönderimi (Edge Function gerekli)
- Bildirim ses/titreşim ayarları
- Toplu bildirim sistemi