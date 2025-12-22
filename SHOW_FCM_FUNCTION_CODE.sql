-- ============================================
-- FCM FONKSİYONU KAYNAK KODUNU GÖR
-- ============================================

-- Fonksiyonun tam kodunu göster
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'notify_courier_with_fcm';

-- VEYA daha detaylı:
SELECT 
  proname as function_name,
  pg_get_functiondef(oid) as full_definition
FROM pg_proc 
WHERE proname = 'notify_courier_with_fcm';
