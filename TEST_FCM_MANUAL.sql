-- ============================================
-- MANUEL FCM TEST - Direkt fonksiyon çağır
-- ============================================

-- Courier'ın FCM token'ını al
SELECT fcm_token FROM users WHERE id = '250f4abe-858a-457b-b972-9a76340b07c2';

-- HTTP extension var mı kontrol et
SELECT * FROM pg_extension WHERE extname = 'http';

-- FCM fonksiyonu var mı?
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_name = 'notify_courier_with_fcm';

-- ÖNEMLİ: Supabase LOGS kontrol et!
-- Dashboard -> Logs -> Postgres Logs
-- "FCM" veya "notify_courier" ara
-- Hata varsa orada görünür!
