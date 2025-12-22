-- ============================================
-- MANUEL BİLDİRİM TEST - DOĞRU ID İLE
-- ============================================

-- Önce notifications tablosunun yapısını kontrol et
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- Sonra manuel bildirim ekle
INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
VALUES (
  '250f4abe-858a-457b-b972-9a76348a07c2',  -- fatih teke (SQL'den doğrulandı)
  'MANUEL TEST BİLDİRİMİ',
  'Giriş yaptın! Bu bildirimi görüyor musun?',
  'delivery',
  false,
  NOW()
);

-- Eğer bu da hata verirse, notifications tablosunda bir sorun var demektir!

-- ============================================
-- SONRA: Eklenen bildirimi kontrol et
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

-- Bu sorgu yeni eklenen bildirimi gösterecek
-- Courier App'te HEMEN görünmeli! 👀
