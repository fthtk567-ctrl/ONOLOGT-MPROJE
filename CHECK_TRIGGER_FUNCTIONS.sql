-- Trigger fonksiyonlarının kodlarını gör
SELECT 
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_code
FROM pg_proc p
WHERE p.proname IN (
  'add_notification_on_courier_assign',
  'notify_courier_simple',
  'calculate_commissions',
  'notify_courier_via_edge_function',
  'update_merchant_wallet_on_delivery',
  'update_updated_at_column'
)
ORDER BY p.proname;
