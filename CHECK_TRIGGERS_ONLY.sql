-- Sadece trigger'ları kontrol et
SELECT 
    t.tgname AS trigger_name,
    p.proname AS function_name,
    pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_class c ON t.tgrelid = c.oid
WHERE c.relname = 'users'
  AND t.tgisinternal = false
ORDER BY t.tgname;
