-- Trigger çalışıyor mu kontrol et
-- delivery_requests tablosunda trigger var mı?

SELECT 
  trigger_name,
  event_manipulation,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;
