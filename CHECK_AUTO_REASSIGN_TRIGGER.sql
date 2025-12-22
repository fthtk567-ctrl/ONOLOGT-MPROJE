-- Otomatik yeniden atama trigger'ını kontrol et

-- 1. Trigger var mı?
SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_reassign';

-- 2. Fonksiyon var mı?
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_name = 'auto_reassign_rejected_delivery';

-- 3. Son reddedilen siparişleri gör
SELECT 
  id,
  status,
  courier_id,
  rejected_by,
  rejected_at,
  created_at
FROM orders
WHERE rejected_by IS NOT NULL
ORDER BY rejected_at DESC
LIMIT 5;

-- 4. Aktif ve müsait kuryeler
SELECT 
  id,
  full_name,
  is_available,
  is_active,
  status
FROM users
WHERE role = 'courier'
  AND is_active = true
  AND status = 'approved'
ORDER BY created_at;
