-- Aktif trigger'ları kontrol et
SELECT 
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  proname as function_name,
  tgenabled
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname LIKE '%notify%' OR tgname LIKE '%fcm%'
ORDER BY tgname;

-- HTTP extension var mı?
SELECT * FROM pg_available_extensions WHERE name = 'http';
