-- Son teslimat kaydını ve trigger durumunu kontrol et

-- 1. En son oluşturulan teslimat
SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    package_count,
    declared_amount,
    created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 1;

-- 2. notification_queue'da kayıt var mı?
SELECT 
    id,
    user_id,
    fcm_token,
    title,
    body,
    status,
    created_at
FROM notification_queue
ORDER BY created_at DESC
LIMIT 3;

-- 3. Trigger mevcut mu?
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_courier_on_assignment';

-- 4. notify_courier_on_delivery_assigned fonksiyonu var mı?
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_name = 'notify_courier_on_delivery_assigned';
