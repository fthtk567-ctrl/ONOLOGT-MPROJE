-- AYNI MERCHANT KURYE TERCİHİ TEST SORGUSU
-- Bu test, aynı merchant'ın önceki siparişlerini hangi kuryenin teslim ettiğini gösterir

-- 1️⃣ merchantt@test.com için önceki teslimatları kontrol et
SELECT 
    dr.id AS delivery_id,
    dr.order_number,
    dr.status,
    dr.created_at,
    dr.delivered_at,
    u.email AS courier_email,
    u.owner_name AS courier_name,
    u.is_available AS courier_online,
    u.is_busy AS courier_busy,
    dr.courier_id
FROM delivery_requests dr
LEFT JOIN users u ON dr.courier_id = u.id
WHERE dr.merchant_id = (SELECT id FROM users WHERE email = 'merchantt@test.com')
ORDER BY dr.created_at DESC
LIMIT 10;

-- 2️⃣ Şu anda müsait kuryeler kimler?
SELECT 
    id,
    email,
    owner_name,
    is_available AS online,
    is_busy AS busy,
    is_active AS active,
    status
FROM users
WHERE role = 'courier'
AND is_active = true
AND status = 'approved'
ORDER BY is_available DESC, is_busy ASC;

-- 3️⃣ merchantt@test.com için son teslimatı yapan kurye kimdi ve şu an müsait mi?
WITH last_delivery AS (
    SELECT courier_id
    FROM delivery_requests
    WHERE merchant_id = (SELECT id FROM users WHERE email = 'merchantt@test.com')
    AND status = 'delivered'
    ORDER BY delivered_at DESC
    LIMIT 1
)
SELECT 
    u.id,
    u.email,
    u.owner_name,
    u.is_available AS online,
    u.is_busy AS busy,
    u.is_active AS active,
    CASE 
        WHEN u.is_available = true AND u.is_busy = false THEN '✅ Müsait - Tercih Edilecek'
        WHEN u.is_available = true AND u.is_busy = true THEN '⚠️ Online ama meşgul - Yine de tercih edilecek'
        ELSE '❌ Offline - Başka kurye aranacak'
    END AS durum
FROM last_delivery ld
LEFT JOIN users u ON ld.courier_id = u.id
WHERE u.role = 'courier';
