-- Trigger var mı ve fonksiyon doğru mu kontrol et

SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_reassign_delivery';

-- Fonksiyon içeriğini göster
SELECT pg_get_functiondef('auto_reassign_rejected_delivery'::regproc);
