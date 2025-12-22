-- TÜM TRIGGER'LARI KONTROL ET

-- 1. delivery_requests tablosundaki TÜM trigger'lar
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 2. notifications tablosundaki TÜM trigger'lar
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'notifications'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 3. Son oluşturulan delivery_requests kayıtları
SELECT 
    id,
    merchant_id,
    courier_id,
    created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;

-- 4. Son oluşturulan notifications kayıtları
SELECT 
    id,
    user_id,
    title,
    message,
    notification_status,
    created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10;
