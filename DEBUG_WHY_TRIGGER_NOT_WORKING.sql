-- 🚨 ACİL DURUM KONTROL

-- 1. Kaç tane aktif kurye var?
SELECT COUNT(*) as "Aktif Kurye Sayısı"
FROM users
WHERE role = 'courier'
  AND is_active = true
  AND is_available = true  
  AND status = 'approved';

-- 2. Aktif kuryeler kimler?
SELECT 
  full_name,
  email,
  is_active,
  is_available,
  status
FROM users
WHERE role = 'courier'
  AND is_active = true
  AND is_available = true  
  AND status = 'approved';

-- 3. Trigger fonksiyonu var mı?
SELECT 
  routine_name,
  'Fonksiyon mevcut' as durum
FROM information_schema.routines
WHERE routine_name = 'auto_reassign_rejected_delivery';

-- 4. Trigger var mı?
SELECT 
  trigger_name,
  event_manipulation,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_reassign_delivery';