-- ✅ BASİT TESLİMAT KONTROL VE TETİKLE

-- 1. Mevcut durum
SELECT 
  id,
  status,
  courier_id,
  rejected_by
FROM delivery_requests
WHERE id = 'ONL2025110247';

-- 2. Pending'e al (trigger tetiklenecek)
UPDATE delivery_requests 
SET status = 'pending'
WHERE id = 'ONL2025110247';

-- 3. Sonuç kontrol
SELECT 
  id,
  status,
  courier_id,
  rejected_by,
  (SELECT full_name FROM users WHERE id = courier_id) as "Atanan",
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden"
FROM delivery_requests
WHERE id = 'ONL2025110247';