-- ================================================================
-- 15 DAKİKA ÖNCEKİ TESLİMAT İSTEĞİNİ KONTROL ET
-- ================================================================

-- 1. Son 20 dakikada oluşturulan tüm delivery_requests
SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    customer_name,
    declared_amount,
    pickup_location,
    delivery_location,
    created_at,
    updated_at,
    priority_deadline,
    final_deadline
FROM delivery_requests
WHERE created_at >= NOW() - INTERVAL '20 minute'
ORDER BY created_at DESC;

-- 2. Merchant bilgileri ile birlikte
SELECT 
    dr.id,
    dr.status,
    dr.customer_name,
    dr.declared_amount,
    dr.created_at,
    u.full_name as merchant_name,
    u.business_name,
    u.email as merchant_email,
    dr.courier_id,
    courier.full_name as courier_name
FROM delivery_requests dr
LEFT JOIN users u ON dr.merchant_id = u.id
LEFT JOIN users courier ON dr.courier_id = courier.id
WHERE dr.created_at >= NOW() - INTERVAL '20 minute'
ORDER BY dr.created_at DESC;

-- 3. Pending durumundaki istekler (kurye atanmamış)
SELECT 
    id,
    status,
    customer_name,
    declared_amount,
    created_at,
    EXTRACT(EPOCH FROM (NOW() - created_at))/60 as dakika_once
FROM delivery_requests
WHERE status = 'pending'
  AND created_at >= NOW() - INTERVAL '20 minute'
ORDER BY created_at DESC;

-- 4. Kurye ataması olan ama aktif olmayan istekler
SELECT 
    id,
    status,
    courier_id,
    customer_name,
    declared_amount,
    created_at,
    EXTRACT(EPOCH FROM (NOW() - created_at))/60 as dakika_once
FROM delivery_requests
WHERE courier_id IS NOT NULL
  AND status NOT IN ('delivered', 'cancelled')
  AND created_at >= NOW() - INTERVAL '20 minute'
ORDER BY created_at DESC;

-- 5. Test kuryesinin mevcut durumu
SELECT 
    id,
    full_name,
    email,
    role,
    is_available,
    is_active,
    current_location,
    last_login
FROM users 
WHERE role = 'courier'
  AND email = 'trolloji.ai@gmail.com';