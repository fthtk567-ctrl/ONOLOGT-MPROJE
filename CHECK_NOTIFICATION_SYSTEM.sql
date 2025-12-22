-- notification_queue tablosunda kayıt var mı kontrol et
SELECT * FROM notification_queue ORDER BY created_at DESC LIMIT 10;

-- Son delivery_requests'leri kontrol et
SELECT id, courier_id, merchant_id, status, created_at 
FROM delivery_requests 
ORDER BY created_at DESC 
LIMIT 5;

-- Trigger var mı kontrol et
SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_courier';
