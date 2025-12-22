-- Merchant kayıt sorununu düzelt
-- Problem: Auth'da hesap var ama users tablosunda yok

-- 1. Auth'da olup users'da olmayan kullanıcıları kontrol et
SELECT 
    au.id,
    au.email,
    au.created_at as auth_created_at
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL
ORDER BY au.created_at DESC;

-- 2. test5@deneme.com ve test6@deneme.com'u kontrol et
SELECT 
    au.id as auth_id,
    au.email as auth_email,
    u.id as user_id,
    u.email as user_email,
    u.role,
    u.status
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE au.email IN ('test5@deneme.com', 'test6@deneme.com');

-- 3. Auth'da olup users'da olmayan kayıtları temizle (DİKKATLİ KULLAN!)
-- DELETE FROM auth.users 
-- WHERE id IN (
--     SELECT au.id 
--     FROM auth.users au
--     LEFT JOIN public.users u ON au.id = u.id
--     WHERE u.id IS NULL
--     AND au.created_at > NOW() - INTERVAL '1 day'  -- Son 24 saattekiler
-- );
