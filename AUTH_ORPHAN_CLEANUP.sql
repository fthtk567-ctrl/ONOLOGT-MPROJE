-- Auth'da olup users'da olmayan kayıtları temizle
-- Bu kayıtlar "yarım kalmış" kayıtlar - Auth başarılı ama users'a eklenememiş

-- 1. Önce kontrol et
SELECT 
    au.id,
    au.email,
    au.created_at,
    'ORPHAN - Users tablosunda yok' as durum
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL
AND au.created_at > NOW() - INTERVAL '1 day'  -- Son 24 saat
ORDER BY au.created_at DESC;

-- 2. Temizle (DİKKATLİ!)
-- NOT: Bu SQL'i Supabase Dashboard'dan MANUEL çalıştırın
-- Flutter app'ten çalıştırılamaz (admin yetkisi gerekir)

/*
DELETE FROM auth.users
WHERE id IN (
    SELECT au.id 
    FROM auth.users au
    LEFT JOIN public.users u ON au.id = u.id
    WHERE u.id IS NULL
    AND au.created_at > NOW() - INTERVAL '7 days'  -- Son 7 gün
);
*/

-- 3. Sonucu kontrol et
SELECT COUNT(*) as auth_kayit_sayisi FROM auth.users;
SELECT COUNT(*) as users_kayit_sayisi FROM public.users;
SELECT COUNT(*) as orphan_sayisi 
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL;
