-- ============================================
-- YARIM KALMIŞ AUTH KAYITLARINI TEMİZLE
-- ============================================
-- Supabase Dashboard'dan çalıştır

-- 1️⃣ Önce hangi kayıtlar yarım kalmış görelim
SELECT 
  au.id,
  au.email,
  au.created_at,
  CASE 
    WHEN u.id IS NULL THEN '❌ YARIM - Users tablosunda yok'
    ELSE '✅ Tamam'
  END as durum
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE au.email LIKE '%test%'
ORDER BY au.created_at DESC;

-- 2️⃣ Yarım kalmış kayıtları manuel sil
-- Supabase Dashboard > Authentication > Users
-- manav@test.com'u bul ve Delete tıkla

-- Ya da SQL ile (sadece users tablosunda olmayanları):
-- NOT: Bu işlem için admin yetkisi gerekiyor
-- Dashboard kullanmak daha güvenli!

/*
DELETE FROM auth.users 
WHERE email IN (
  SELECT au.email
  FROM auth.users au
  LEFT JOIN public.users u ON au.id = u.id
  WHERE u.id IS NULL 
    AND au.email LIKE '%test%'
);
*/
