-- 🎯 ADIM 2: TRİGGER OLUŞTU MU KONTROL
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_reassign_delivery';