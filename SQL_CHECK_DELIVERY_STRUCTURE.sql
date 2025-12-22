-- ================================================================
-- Delivery Requests tablosu yapısını kontrol et
-- ================================================================

-- 1. Tablo yapısı
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
ORDER BY ordinal_position;

-- 2. Mevcut delivery_requests kayıtları
SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    pickup_location,
    delivery_location,
    created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;

-- 3. Merchants konumları var mı?
SELECT 
    id,
    email,
    full_name,
    role,
    business_address,
    current_location
FROM users
WHERE role = 'merchant'
LIMIT 3;
