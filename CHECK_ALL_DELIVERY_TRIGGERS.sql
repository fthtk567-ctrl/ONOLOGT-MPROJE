-- Mevcut trigger'ları kontrol et
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;
