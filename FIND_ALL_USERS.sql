-- ============================================
-- USERS TABLOSU NEREDE? HER YERDE ARA!
-- ============================================

-- 1. public.users tablosunda TÜM courier'lar
SELECT 
  'public.users' as kaynak,
  id,
  email,
  full_name,
  role
FROM public.users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- 2. auth.users tablosunda TÜM kullanıcılar (role yok ama email var)
SELECT 
  'auth.users' as kaynak,
  id,
  email,
  created_at
FROM auth.users
ORDER BY created_at DESC;

-- 3. Delivery_requests'te kullanılan courier_id
SELECT 
  'delivery_requests' as kaynak,
  id as delivery_id,
  courier_id,
  status
FROM delivery_requests
WHERE courier_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;

-- 4. GİRİŞ YAPAN KULLANICININ ID'Sİ NE?
-- Courier App'te giriş yaptın - hangi kullanıcıyla?
-- Email neydi? Bunu söyle, doğru ID'yi bulalım!

-- ============================================
-- VARSA: Courier user'ı DOĞRUDAN EKLE
-- ============================================

-- Eğer courier public.users'da yoksa, ekleyelim!
-- Ama önce mevcut kayıtları görmemiz lazım
