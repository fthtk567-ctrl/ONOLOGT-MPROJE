-- ============================================
-- BİLDİRİM TRİGGER DURUMU KONTROL
-- ============================================

-- 1. Trigger var mı kontrol et
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_name LIKE '%notification%'
   OR trigger_name LIKE '%notify%'
ORDER BY trigger_name;

-- 2. delivery_requests tablosundaki trigger'ları listele
SELECT 
    trigger_name,
    action_timing || ' ' || event_manipulation as "ne_zaman",
    action_statement as "ne_yapar"
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;

-- 3. Notifications tablosunda yeni kayıt var mı?
SELECT 
    id,
    user_id,
    title,
    body,
    type,
    created_at,
    is_read
FROM notifications
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- ✅ Supabase SQL Editor'da çalıştır
