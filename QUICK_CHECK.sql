-- ============================================
-- BİLDİRİM SİSTEMİ KONTROL - DÜZELT
-- ============================================

-- 1. Trigger'lar VAR MI?
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
  AND trigger_name LIKE '%notif%';

-- 2. Fonksiyonlar VAR MI?
SELECT routine_name
FROM information_schema.routines
WHERE routine_name IN ('add_notification_to_queue', 'notify_courier_simple');

-- 3. Realtime publications (farklı sorgu)
SELECT pubname, tablename
FROM pg_publication_tables
WHERE tablename = 'notifications';

-- 4. Son delivery_request
SELECT 
  id,
  merchant_id,
  courier_id,
  status,
  created_at,
  updated_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 3;

-- ✅ Bu 4 sorguyu çalıştır!
