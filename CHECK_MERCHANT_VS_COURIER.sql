-- Merchant başvurularını kontrol et
SELECT 
    id,
    email,
    role,
    business_name,
    owner_name,
    status,
    created_at,
    commission_settings
FROM users
WHERE email IN ('test5@deneme.com', 'test6@deneme.com')
ORDER BY created_at DESC;

-- Tüm pending başvuruları kontrol et
SELECT 
    id,
    email,
    role,
    business_name,
    owner_name,
    full_name,
    status,
    created_at
FROM users
WHERE status = 'pending'
ORDER BY created_at DESC;

-- Son 10 kaydı kontrol et
SELECT 
    id,
    email,
    role,
    business_name,
    owner_name,
    full_name,
    status,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;
