-- Trigger'ları kontrol et
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name LIKE '%notification%';

-- Notification queue'daki kayıtları kontrol et
SELECT 
    id,
    delivery_request_id,
    fcm_token,
    processed,
    created_at,
    processed_at
FROM notification_queue
ORDER BY created_at DESC
LIMIT 10;

-- Son teslimat isteklerini kontrol et
SELECT 
    id,
    merchant_id,
    status,
    created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;

-- Merchant'ın FCM token'ını kontrol et
SELECT 
    id,
    email,
    role,
    fcm_token IS NOT NULL as has_fcm_token
FROM users
WHERE role = 'merchant'
LIMIT 5;
