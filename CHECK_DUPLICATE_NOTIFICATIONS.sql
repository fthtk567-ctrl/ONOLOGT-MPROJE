-- Son 10 bildirim kaydını kontrol et - aynı delivery_request_id için 2 satır var mı?
SELECT 
  id,
  delivery_request_id,
  fcm_token,
  title,
  created_at,
  processed
FROM notification_queue
ORDER BY created_at DESC
LIMIT 10;

-- Aynı delivery_request_id'ye kaç bildirim var?
SELECT 
  delivery_request_id,
  COUNT(*) as bildirim_sayisi,
  MAX(created_at) as son_bildirim
FROM notification_queue
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY delivery_request_id
HAVING COUNT(*) > 1
ORDER BY son_bildirim DESC;

-- Database trigger'ları kontrol et - birden fazla trigger var mı?
SELECT 
  trigger_name,
  event_object_table,
  action_statement,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
  AND trigger_name LIKE '%notif%';
