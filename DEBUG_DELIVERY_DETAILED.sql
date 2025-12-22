-- ================================================================
-- TESLİMAT İSTEĞİ DEBUG - DETAYLI KONTROL
-- ================================================================

-- 1. SON 30 DAKİKADAKİ TÜM İSTEKLER
SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    customer_name,
    declared_amount,
    pickup_location->>'address' as pickup_address,
    delivery_location->>'address' as delivery_address,
    created_at,
    updated_at,
    EXTRACT(EPOCH FROM (NOW() - created_at))/60 as dakika_once,
    priority_deadline,
    final_deadline
FROM delivery_requests
WHERE created_at >= NOW() - INTERVAL '30 minute'
ORDER BY created_at DESC
LIMIT 10;

-- 2. PENDING DURUMUNDAKI TÜM İSTEKLER
SELECT 
    id,
    status,
    customer_name,
    declared_amount,
    created_at,
    EXTRACT(EPOCH FROM (NOW() - created_at))/60 as dakika_once
FROM delivery_requests
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 5;

-- 3. TEST KURYEYE ATANMIŞ İSTEKLER (trolloji.ai@gmail.com)
-- Önce courier ID'sini bulalım
SELECT 
    id as courier_id,
    full_name,
    email,
    is_available,
    is_active
FROM users 
WHERE email = 'trolloji.ai@gmail.com' AND role = 'courier';

-- Test kuryeye atanmış delivery_requests
SELECT 
    dr.id,
    dr.status,
    dr.customer_name,
    dr.created_at,
    EXTRACT(EPOCH FROM (NOW() - dr.created_at))/60 as dakika_once,
    u.email as courier_email
FROM delivery_requests dr
JOIN users u ON dr.courier_id = u.id
WHERE u.email = 'trolloji.ai@gmail.com'
  AND dr.created_at >= NOW() - INTERVAL '30 minute'
ORDER BY dr.created_at DESC;

-- 4. STREAM FİLTRE TEST
-- Courier app'in kullandığı filtreler:
-- Stream 1: courier_id = X olan istekler
-- Stream 2: status = 'pending' olan istekler

-- Pending istekler (Stream 2'nin gördüğü)
SELECT 
    id,
    status,
    customer_name,
    declared_amount,
    pickup_location->>'address' as pickup,
    delivery_location->>'address' as delivery,
    created_at
FROM delivery_requests
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 5;

-- 5. MERCHANT PANEL'DEN SON OLUŞTURULMUŞ İSTEKLER
SELECT 
    dr.id,
    dr.status,
    dr.customer_name,
    dr.created_at,
    u.business_name as merchant,
    u.email as merchant_email
FROM delivery_requests dr
JOIN users u ON dr.merchant_id = u.id
WHERE dr.created_at >= NOW() - INTERVAL '30 minute'
ORDER BY dr.created_at DESC
LIMIT 5;