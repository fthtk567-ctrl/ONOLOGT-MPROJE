-- ============================================
-- NOTIFICATIONS TABLOSUNA INSERT YAPAN TRİGGER'LARI BUL
-- ============================================

-- 1. delivery_requests tablosundaki tüm trigger'ları göster
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;

-- 2. Bu trigger'ların fonksiyon kodlarını göster
SELECT 
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_code
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname ILIKE '%notification%'
ORDER BY p.proname;

-- 3. notifications tablosunun kolonlarını kontrol et
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'notifications'
  AND table_schema = 'public'
ORDER BY ordinal_position;
