-- ============================================
-- FONKSİYON KODLARINI GÖSTER VE TEST ET
-- ============================================

-- 1. notify_courier_simple fonksiyonunun kodunu göster
SELECT pg_get_functiondef(oid) as function_code
FROM pg_proc
WHERE proname = 'notify_courier_simple';

-- 2. add_notification_to_queue fonksiyonunun kodunu göster
SELECT pg_get_functiondef(oid) as function_code
FROM pg_proc
WHERE proname = 'add_notification_to_queue';

-- 3. Manuel test: Yeni bir bildirim ekle (trigger'ı bypass et)
INSERT INTO notifications (user_id, title, body, type)
VALUES (
  '250f4abe-858a-457b-b972-9a76340b07c2', -- Kurye ID'si
  'TEST BİLDİRİMİ',
  'Bu manuel test bildirimi',
  'delivery'
);

-- 4. Son 5 bildirimi göster
SELECT 
  id,
  user_id,
  title,
  body,
  type,
  created_at,
  is_read
FROM notifications
ORDER BY created_at DESC
LIMIT 5;

-- ✅ Supabase'de çalıştır
