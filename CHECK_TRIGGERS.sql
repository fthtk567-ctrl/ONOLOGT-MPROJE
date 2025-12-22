-- ============================================
-- TETİKLEYİCİLERİ KONTROL ET
-- ============================================

-- 1. Tüm trigger'ları listele
SELECT 
  trigger_name,
  event_object_table as tablo,
  action_timing,
  event_manipulation as olay,
  action_statement as fonksiyon
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 2. delivery_requests için trigger var mı?
SELECT 
  trigger_name,
  action_timing,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
  AND trigger_schema = 'public';

-- 3. Bildirim fonksiyonları var mı?
SELECT 
  proname as fonksiyon_adi,
  prosrc as fonksiyon_kodu
FROM pg_proc
WHERE proname LIKE '%notification%' 
   OR proname LIKE '%notify%'
   OR proname LIKE '%courier%'
ORDER BY proname;
