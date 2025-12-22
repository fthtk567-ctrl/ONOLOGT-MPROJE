-- ============================================
-- BİLDİRİMLER YAZILDI MI?
-- ============================================

-- Son 1 saatteki TÜM notifications
SELECT 
  id,
  user_id,
  title,
  message,
  type,
  is_read,
  created_at
FROM notifications
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- Eğer sonuç BOŞ ise → TRİGGER ÇALIŞMADI! ❌
-- Eğer sonuç VAR ise → Bildirim yazıldı ama Flutter dinlemedi! ⚠️

-- ============================================
-- AYRIYETEN: Bu courier'e giden bildirimler
-- ============================================

SELECT 
  id,
  user_id,
  title,
  message,
  type,
  is_read,
  created_at
FROM notifications
WHERE user_id = '250f4abe-858a-457b-b972-9a76348a07c2'  -- fatih teke (courier)
ORDER BY created_at DESC
LIMIT 10;

-- Bu sorgu fatih teke'ye giden SON 10 bildirimi gösterecek
