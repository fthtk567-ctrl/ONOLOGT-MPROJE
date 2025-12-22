-- Onayladığın merchant'ı kontrol et
SELECT 
    id,
    email,
    role,
    business_name,
    owner_name,
    status,
    is_active,
    created_at
FROM users
WHERE email = 'test4@deneme.com'  -- Kayıt yaptığın email
ORDER BY created_at DESC;

-- Tüm approved merchant'ları göster
SELECT 
    id,
    email,
    business_name,
    status,
    is_active
FROM users
WHERE role = 'merchant' AND status = 'approved'
ORDER BY created_at DESC;
