-- Reddettiğin siparişin son durumunu kontrol et

SELECT 
  order_number as "Sipariş No",
  status as "Durum",
  courier_id as "Kurye ID",
  rejected_by as "Reddeden Kuryeler",
  rejection_count as "Red Sayısı",
  rejected_at as "Red Tarihi",
  updated_at as "Son Güncelleme"
FROM delivery_requests
WHERE order_number = 'ONL2025110243';

-- Trigger var mı kontrol et
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_reassign_delivery';
