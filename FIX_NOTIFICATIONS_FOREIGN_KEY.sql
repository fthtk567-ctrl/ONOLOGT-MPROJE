-- ============================================
-- NOTIFICATIONS FOREIGN KEY DÜZELT
-- ============================================

-- ADIM 1: Eski constraint'i kaldır
ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;

-- ADIM 2: Yeni constraint ekle (public.users'a bağla)
ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES public.users(id) 
ON DELETE CASCADE;

-- ✅ Artık notifications public.users'a bağlı!

-- ============================================
-- TEST: Şimdi bildirim ekle
-- ============================================

INSERT INTO notifications (user_id, title, message, type, is_read)
VALUES (
  '250f4abe-858a-457b-b972-9a76348a07c2',  -- fatih teke (public.users'dan)
  '🎉 BAŞARILI TEST!',
  'Foreign key düzeltildi! Bu bildirimi görüyorsan sistem ÇALIŞIYOR!',
  'delivery',
  false
);

-- Bu INSERT başarılı olmalı! 
-- Courier App'te HEMEN bildirim görünecek! 👀

-- ============================================
-- KONTROL: Bildirim eklendi mi?
-- ============================================

SELECT 
  id,
  user_id,
  title,
  message,
  is_read,
  created_at
FROM notifications
WHERE user_id = '250f4abe-858a-457b-b972-9a76348a07c2'
ORDER BY created_at DESC
LIMIT 1;

-- Eğer bu sorgu sonuç döndürüyorsa → BAŞARILI! 🎉
-- Courier App'te yeşil SnackBar görünmeli!
