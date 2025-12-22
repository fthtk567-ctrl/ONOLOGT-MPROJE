-- Auth'daki kullanıcının email_confirmed_at durumunu kontrol et
SELECT 
    au.id,
    au.email,
    au.email_confirmed_at,  -- NULL ise email onaylanmamış!
    au.created_at,
    u.role,
    u.status,
    u.is_active,
    u.business_name
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE au.email = 'test4@deneme.com'  -- Kayıt yaptığın email
ORDER BY au.created_at DESC;

-- Tüm merchant'ların email onay durumu
SELECT 
    au.email,
    au.email_confirmed_at,
    CASE 
        WHEN au.email_confirmed_at IS NULL THEN '❌ Onaylanmamış'
        ELSE '✅ Onaylanmış'
    END as email_durumu,
    u.status,
    u.is_active
FROM auth.users au
INNER JOIN public.users u ON au.id = u.id
WHERE u.role = 'merchant'
ORDER BY au.created_at DESC;
