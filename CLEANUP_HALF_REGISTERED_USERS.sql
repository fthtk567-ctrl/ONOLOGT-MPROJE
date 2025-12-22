-- ============================================
-- YARIM KALMIŞ KAYITLARI TEMİZLE
-- ============================================
-- Problem: Auth'da hesap var ama users tablosunda yok
-- Sonuç: "User already registered" hatası

-- 1️⃣ ÖNCE KONTROL ET - Hangi kayıtlar yarım kalmış?
SELECT 
  au.id as auth_id,
  au.email,
  au.created_at as auth_created,
  u.id as user_table_id,
  u.business_name,
  u.status,
  CASE 
    WHEN u.id IS NULL THEN '❌ YARIM - Users tablosunda yok'
    ELSE '✅ TAMAM - Her yerde var'
  END as durum
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE au.email LIKE '%test%'
ORDER BY au.created_at DESC;

-- 2️⃣ YARIM KALMIŞ KAYDI TEMİZLE
-- ÖNEMLİ: Sadece Auth'da olup users'da olmayanları sil!

-- Örnek: manav@test.com için
-- NOT: Supabase Dashboard > Authentication > Users'dan bulup "Delete" ile sil
-- Ya da aşağıdaki SQL'i kullan:

-- ⚠️ YALNIZCA YARIM KALMIŞ KAYITLARI SİL
-- (users tablosunda olmayan Auth kayıtları)
-- NOT: Bu işlem için Dashboard kullanmak daha güvenli

-- 3️⃣ ALTERNATİF: Eksik user kaydını tamamla
-- Eğer silmek istemiyorsan, users tablosuna ekle:

DO $$
DECLARE
    auth_user_id uuid;
    auth_user_email text;
BEGIN
    -- manav@test.com için Auth ID'yi bul
    SELECT id, email INTO auth_user_id, auth_user_email
    FROM auth.users 
    WHERE email = 'manav@test.com';
    
    IF auth_user_id IS NOT NULL THEN
        -- Users tablosunda var mı kontrol et
        IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth_user_id) THEN
            -- Yoksa ekle (minimal kayıt)
            INSERT INTO public.users (
                id, 
                email, 
                role, 
                status, 
                is_active,
                business_name,
                created_at,
                updated_at
            ) VALUES (
                auth_user_id,
                auth_user_email,
                'merchant',
                'pending',
                false,
                'Manav Test', -- İsim gerekli
                NOW(),
                NOW()
            );
            RAISE NOTICE 'Yarım kalmış kayıt tamamlandı: %', auth_user_email;
        ELSE
            RAISE NOTICE 'Bu email zaten users tablosunda var: %', auth_user_email;
        END IF;
    ELSE
        RAISE NOTICE 'Auth''da bu email bulunamadı: manav@test.com';
    END IF;
END $$;

-- 4️⃣ TÜM YARIM KALMIŞ KAYITLARI TOPLU TEMİZLE (DİKKAT!)
-- ⚠️ Bu sorguyu çalıştırmadan önce yukarıdaki SELECT ile kontrol et!

/*
-- Auth'da olup users'da olmayan tüm test hesaplarını bul
WITH orphaned_auth_users AS (
  SELECT au.id, au.email
  FROM auth.users au
  LEFT JOIN public.users u ON au.id = u.id
  WHERE u.id IS NULL 
    AND au.email LIKE '%test%'
)
SELECT * FROM orphaned_auth_users;

-- NOT: Bunları silmek için Supabase Dashboard kullan
-- Dashboard > Authentication > Users > [email seç] > Delete
*/
