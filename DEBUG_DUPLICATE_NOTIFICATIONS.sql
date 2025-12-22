-- TÜM TRIGGER'LARI VE SON BİLDİRİMLERİ KONTROL ET

-- 1. delivery_requests üzerindeki TÜM trigger'lar
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 2. notifications üzerindeki TÜM trigger'lar
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'notifications'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 3. Son oluşturulan bildirimleri göster
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

-- 4. Son oluşturulan delivery_requests
SELECT 
    id,
    courier_id,
    declared_amount,
    created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;
