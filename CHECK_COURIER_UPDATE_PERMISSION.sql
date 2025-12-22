-- ===================================================================
-- COURIER UPDATE İZNİ KONTROL ET
-- ===================================================================

-- 1. delivery_requests için mevcut RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'delivery_requests';

-- 2. Courier UPDATE izni var mı?
-- Courier'ın order'ı update edebilmesi için policy gerekli
