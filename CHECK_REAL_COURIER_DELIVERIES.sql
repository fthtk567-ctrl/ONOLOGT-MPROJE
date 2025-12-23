-- GERÇEK KURYE VERİLERİNİ KONTROL ET

-- 1. courier@onlog.com kullanıcısının ID'sini bul
SELECT id, email, full_name, role
FROM users
WHERE email = 'courier@onlog.com';

-- 2. Bu kuryenin tüm teslimatlarını listele (HER STATUS)
SELECT 
  id,
  merchant_name,
  declared_amount,
  courier_payment_due,
  merchant_payment_due,
  system_commission,
  status,
  created_at,
  assigned_at,
  picked_up_at,
  completed_at
FROM delivery_requests
WHERE courier_id = (SELECT id FROM users WHERE email = 'courier@onlog.com')
ORDER BY created_at DESC
LIMIT 20;

-- 3. Sadece tamamlanmış teslimatları göster
SELECT 
  id,
  merchant_name,
  declared_amount,
  courier_payment_due,
  status,
  completed_at
FROM delivery_requests
WHERE courier_id = (SELECT id FROM users WHERE email = 'courier@onlog.com')
  AND status = 'completed'
ORDER BY created_at DESC;

-- 4. Tüm status değerlerini kontrol et
SELECT 
  status,
  COUNT(*) as count,
  SUM(courier_payment_due) as total_earnings
FROM delivery_requests
WHERE courier_id = (SELECT id FROM users WHERE email = 'courier@onlog.com')
GROUP BY status
ORDER BY count DESC;
