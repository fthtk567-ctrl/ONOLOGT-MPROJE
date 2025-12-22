-- ============================================
-- COURIER'I PUBLIC.USERS TABLOSUNA EKLE
-- ============================================

-- ADIM 1: auth.users'daki courier bilgilerini al
SELECT 
  id,
  email,
  created_at
FROM auth.users
WHERE id = '250f4abe-858a-457b-b972-9a76348a07c2';

-- Eğer yukarıda sonuç varsa, aşağıyı çalıştır:

-- ADIM 2: Courier'ı public.users'a ekle
INSERT INTO public.users (
  id, 
  email, 
  full_name, 
  role, 
  is_available,
  phone_number,
  created_at
)
SELECT 
  id,
  email,
  'Fatih Teke' as full_name,  -- Ad soyad (değiştirilebilir)
  'courier' as role,
  true as is_available,
  '+905551234567' as phone_number,  -- Telefon (değiştirilebilir)
  created_at
FROM auth.users
WHERE id = '250f4abe-858a-457b-b972-9a76348a07c2'
ON CONFLICT (id) DO NOTHING;  -- Zaten varsa ekleme

-- ✅ Artık courier public.users'da!

-- ADIM 3: Kontrol et
SELECT 
  id,
  email,
  full_name,
  role,
  is_available
FROM public.users
WHERE id = '250f4abe-858a-457b-b972-9a76348a07c2';

-- ADIM 4: Şimdi bildirim ekle
INSERT INTO notifications (user_id, title, message, type, is_read)
VALUES (
  '250f4abe-858a-457b-b972-9a76348a07c2',
  '🎉 BAŞARILI!',
  'Courier public.users''a eklendi! Sistem ÇALIŞIYOR!',
  'delivery',
  false
);

-- ADIM 5: Kontrol
SELECT 
  id,
  user_id,
  title,
  message,
  created_at
FROM notifications
WHERE user_id = '250f4abe-858a-457b-b972-9a76348a07c2'
ORDER BY created_at DESC
LIMIT 1;

-- ✅ Bu çalışırsa:
-- 1. Courier public.users'a eklenmiş olacak
-- 2. Bildirim başarıyla eklenecek
-- 3. Courier App'te bildirim GÖRÜNECEK! 🎉
