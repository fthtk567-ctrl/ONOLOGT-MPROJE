-- TRIGGER KONTROLÜ - Bildirimler otomatik mı gönderiliyor?

-- 1. Tüm trigger'ları listele
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND event_object_table IN ('notifications', 'orders', 'delivery_requests');

-- 2. Notifications tablosunda kaç tane pending var?
SELECT COUNT(*) as pending_count FROM notifications WHERE notification_status = 'pending';

-- 3. Son 10 bildirimi göster
SELECT id, title, notification_status, created_at, sent_at 
FROM notifications 
ORDER BY created_at DESC 
LIMIT 10;
