-- ============================================
-- TESLİMAT SONRASI KONTROL
-- ============================================

-- 1. Son oluşturulan teslimat
SELECT 
  id,
  merchant_id,
  courier_id,
  status,
  declared_amount,
  created_at,
  updated_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 1;

-- 2. Bu teslimat için bildirim oluşturuldu mu?
SELECT 
  n.id,
  n.user_id,
  n.title,
  n.message,
  n.is_read,
  n.created_at,
  u.email as courier_email
FROM notifications n
LEFT JOIN users u ON n.user_id = u.id
ORDER BY n.created_at DESC
LIMIT 3;

-- Bu iki sorguyu teslimat oluşturduktan HEMEN SONRA çalıştır!
