-- ============================================
-- COURIER'I PUBLIC.USERS'A EKLE (PHONE_NUMBER YOK)
-- ============================================

-- ADIM 1: Courier'ı public.users'a ekle (phone_number olmadan)
INSERT INTO public.users (
  id, 
  email, 
  full_name, 
  role, 
  is_available,
  created_at
)
SELECT 
  id,
  email,
  'Fatih Teke' as full_name,
  'courier' as role,
  true as is_available,
  created_at
FROM auth.users
WHERE id = '250f4abe-858a-457b-b972-9a76348a07c2'
ON CONFLICT (id) DO NOTHING;

-- ADIM 2: Kontrol et
SELECT 
  id,
  email,
  full_name,
  role,
  is_available
FROM public.users
WHERE id = '250f4abe-858a-457b-b972-9a76348a07c2';

-- ADIM 3: Bildirim ekle
INSERT INTO notifications (user_id, title, message, type, is_read)
VALUES (
  '250f4abe-858a-457b-b972-9a76348a07c2',
  '🎉 BAŞARILI TEST!',
  'Courier eklendi! Bildirimi görüyor musun?',
  'delivery',
  false
);

-- ADIM 4: Bildirim kontrolü
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

-- ✅ Eğer başarılı olursa:
-- 1. Courier public.users'a eklenecek
-- 2. Bildirim eklenecek
-- 3. Courier App'te HEMEN yeşil SnackBar görünecek! 🎉
