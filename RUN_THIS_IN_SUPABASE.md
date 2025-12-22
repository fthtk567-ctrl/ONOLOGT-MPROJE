# Supabase Dashboard'da Çalıştırılacak SQL

## ADIM 1: Bu linki aç
https://supabase.com/dashboard/project/oilldfyywtzybrmpyixx/sql/new

## ADIM 2: Aşağıdaki SQL'i yapıştır ve RUN'a bas

```sql
-- Tüm FCM trigger'larını geçici olarak kaldır
DROP TRIGGER IF EXISTS trigger_send_courier_notification ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_queue_courier_notification ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_on_insert ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_insert ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_update ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_delivery_request ON delivery_requests;
DROP TRIGGER IF EXISTS on_notification_insert_trigger ON notifications;
DROP TRIGGER IF EXISTS trigger_call_fcm_edge_function ON notifications;
DROP TRIGGER IF EXISTS trigger_send_fcm_on_notification_insert ON notifications;

-- Kalan trigger'ları kontrol et
SELECT 
    trigger_name,
    event_object_table as table_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND event_object_table IN ('delivery_requests', 'notifications');
```

## ADIM 3: Sonuç
- Eğer SELECT sorgusu **boş tablo** döndüyorsa ✅ trigger'lar kaldırıldı
- Yemek App'ten tekrar test et
- Artık "Project not specified" hatası GİTMELİ!

## ADIM 4: Test başarılıysa
Sipariş başarıyla `delivery_requests` tablosuna kaydedilecek ve webhook 200 dönecek.
