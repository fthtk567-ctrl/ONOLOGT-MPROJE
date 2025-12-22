-- ============================================
-- NOTIFICATIONS TABLO YAPISINI KONTROL ET
-- ============================================

-- Notifications tablosunun kolonlarını göster
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications'
ORDER BY ordinal_position;
