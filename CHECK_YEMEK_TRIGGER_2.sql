-- Komisyon hesaplama trigger'ı çalışıyor mu?
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_name ILIKE '%commission%'
ORDER BY trigger_name;
