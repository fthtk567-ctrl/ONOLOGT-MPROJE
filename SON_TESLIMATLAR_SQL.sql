-- ================================================================
-- SON TESLİMATLARI GÖRME SQL SORULARI
-- ================================================================

-- 1. SON 1 SAATTE OLUŞTURULAN TÜM DELIVERY_REQUESTS
SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    customer_name,
    declared_amount,
    created_at,
    updated_at
FROM delivery_requests
WHERE created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- 2. SADECE PENDING DURUMUNDAKI İSTEKLER
SELECT 
    id,
    status,
    customer_name,
    declared_amount,
    created_at
FROM delivery_requests
WHERE status = 'pending'
ORDER BY created_at DESC;

-- 3. TEST KURYE BİLGİSİ
SELECT 
    id,
    email,
    full_name,
    role,
    is_available,
    is_active
FROM users 
WHERE email = 'trolloji.ai@gmail.com';

-- 4. TEST KURYEYE ATANMIŞ İSTEKLER
-- (Yukarıdaki sorgudan aldığın courier_id'yi buraya koy)
SELECT 
    id,
    status,
    customer_name,
    declared_amount,
    created_at
FROM delivery_requests
WHERE courier_id = 'COURIER_ID_BURAYA_YAZ'
ORDER BY created_at DESC;

-- 5. TÜM DURUMLAR - SON 2 SAAT
SELECT 
    id,
    status,
    customer_name,
    declared_amount,
    created_at,
    CASE 
        WHEN status = 'pending' THEN 'BEKLEYEN - Kurye atanmamış'
        WHEN status = 'assigned' THEN 'ATANDI - Kurye kabul etmedi'
        WHEN status = 'accepted' THEN 'KABUL EDİLDİ - Kurye yolda'
        WHEN status = 'picked_up' THEN 'ALINDI - Teslimata gidiyor'
        WHEN status = 'delivered' THEN 'TESLİM EDİLDİ'
        WHEN status = 'cancelled' THEN 'İPTAL EDİLDİ'
        ELSE status
    END as durum_aciklama
FROM delivery_requests
WHERE created_at >= NOW() - INTERVAL '2 hour'
ORDER BY created_at DESC;