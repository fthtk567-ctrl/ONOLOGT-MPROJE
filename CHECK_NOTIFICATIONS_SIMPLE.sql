-- ============================================
-- BİLDİRİMLER VAR MI? - BASIT KONTROL
-- ============================================

SELECT 
  id,
  user_id,
  title,
  message,
  is_read,
  created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 5;

-- Eğer sonuç BOŞ ise → Trigger çalışmadı!
-- Eğer sonuç VAR ise → Bildirim oluşturulmuş, Courier App dinlemiyor!
