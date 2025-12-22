-- Durum bildirimi trigger'ı var mı?
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_name ILIKE '%notify_external%'
ORDER BY trigger_name;
