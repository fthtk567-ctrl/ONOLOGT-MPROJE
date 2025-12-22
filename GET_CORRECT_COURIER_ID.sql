-- ============================================
-- DOĞRU COURIER ID'Sİ BUL
-- ============================================

-- 1. TÜM courier'ları listele (doğru ID'yi bulmak için)
SELECT 
  id,
  email,
  full_name,
  role,
  is_available,
  created_at
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- 2. Son delivery_request'te kullanılan courier_id
SELECT 
  id as delivery_id,
  courier_id,
  status,
  declared_amount,
  created_at
FROM delivery_requests
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 1;

-- 3. Bu courier_id users tablosunda var mı?
SELECT 
  dr.id as delivery_id,
  dr.courier_id,
  u.email,
  u.full_name,
  CASE 
    WHEN u.id IS NOT NULL THEN '✅ Courier users tablosunda VAR'
    ELSE '❌ Courier users tablosunda YOK! SORUN BURADA!'
  END as durum
FROM delivery_requests dr
LEFT JOIN users u ON dr.courier_id = u.id
WHERE dr.created_at > NOW() - INTERVAL '1 hour'
ORDER BY dr.created_at DESC
LIMIT 1;

-- Bu sorgu sorunu gösterecek!
-- Eğer LEFT JOIN'de users.id NULL ise → courier_id geçersiz!
