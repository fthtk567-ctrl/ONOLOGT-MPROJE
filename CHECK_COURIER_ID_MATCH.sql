-- COURIER ID KONTROLÜ

-- 1. Fatih'in gerçek courier ID'si (sen girdiğin ID)
SELECT '250f4abe-858a-457b-b972-9a76340b07c2' as given_id;

-- 2. courier@onlog.com kullanıcısının gerçek ID'si
SELECT id as real_id, email, full_name 
FROM users 
WHERE email = 'courier@onlog.com';

-- 3. İKİ ID AYNI MI?
SELECT 
  CASE 
    WHEN (SELECT id FROM users WHERE email = 'courier@onlog.com') = '250f4abe-858a-457b-b972-9a76340b07c2'
    THEN '✅ ID DOĞRU - Aynı kişi'
    ELSE '❌ ID YANLIŞ - Farklı kişiler!'
  END as id_match;

-- 4. Eğer farklıysa, doğru ID ile siparişleri göster
SELECT 
  COUNT(*) as total_deliveries,
  SUM(courier_payment_due) as total_earnings
FROM delivery_requests
WHERE courier_id = '250f4abe-858a-457b-b972-9a76340b07c2'
  AND status = 'delivered';
