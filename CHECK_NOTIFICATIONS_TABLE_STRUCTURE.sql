-- ============================================
-- NOTIFICATIONS TABLOSU YAPISINI KONTROL ET
-- ============================================

-- 1. Notifications tablosunun kolonlarını göster
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- 2. Eğer 'message' kolonu varsa ve 'body' yoksa, body ekle VEYA message'ı kullan
-- Şimdilik manuel test: message ile ekle
INSERT INTO notifications (user_id, title, message, type)
VALUES (
  '250f4abe-858a-457b-b972-9a76340b07c2',
  'TEST BİLDİRİMİ',
  'Bu manuel test bildirimi',
  'delivery'
);

-- 3. Son 5 bildirimi göster
SELECT *
FROM notifications
ORDER BY created_at DESC
LIMIT 5;

-- ✅ Supabase'de çalıştır
