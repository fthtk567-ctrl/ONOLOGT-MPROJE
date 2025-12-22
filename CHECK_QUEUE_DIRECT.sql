-- notification_queue tablosunu direkt kontrol et
-- RLS olmadan göster

-- 1. Tüm kayıtları göster
SELECT 
    id,
    user_id,
    fcm_token,
    title,
    body,
    status,
    created_at,
    processed_at
FROM notification_queue
ORDER BY created_at DESC
LIMIT 5;

-- 2. RLS policy kontrolü
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'notification_queue';

-- 3. Status dağılımı
SELECT 
    status,
    COUNT(*) as count
FROM notification_queue
GROUP BY status;
