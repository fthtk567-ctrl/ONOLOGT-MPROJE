-- Mevcut durumda sistemimizdeki tüm kuryelerin detaylı durumunu kontrol et
SELECT 
    id,
    owner_name,
    email,
    role,
    status,
    is_available,
    is_active,
    current_location,
    CASE 
        WHEN is_available = true AND status = 'approved' THEN '✅ ONLINE VE MÜSAİT'
        WHEN is_available = false AND status = 'approved' THEN '🔴 OFFLINE (Mesaide değil)'
        WHEN status != 'approved' THEN CONCAT('❌ ONAYLANMAMIŞ (', status, ')')
        ELSE '⚠️ DİĞER DURUM'
    END as courier_status_info,
    created_at,
    updated_at
FROM users 
WHERE role = 'courier'
ORDER BY 
    is_available DESC, 
    status DESC,
    owner_name;

-- Özel kontrol: Giriş yaptığın kurye
SELECT 
    'MEVCUT GİRİŞ YAPAN KULLANICI:' as info,
    id,
    owner_name,
    email,
    is_available,
    status
FROM users 
WHERE role = 'courier' 
AND is_available = true
LIMIT 1;

-- Son oluşturulan teslimat talebi hangi kuryeye gitti?
SELECT 
    dr.id as delivery_id,
    dr.courier_id,
    u.owner_name as courier_name,
    dr.status,
    dr.created_at,
    dr.merchant_id
FROM delivery_requests dr
LEFT JOIN users u ON dr.courier_id = u.id
ORDER BY dr.created_at DESC
LIMIT 5;