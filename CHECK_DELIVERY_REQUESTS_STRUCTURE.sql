-- ===================================================================
-- DELIVERY_REQUESTS TABLOSU YAPISINI KONTROL ET
-- ===================================================================

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'delivery_requests'
ORDER BY ordinal_position;

-- Örnek bir satır göster
SELECT *
FROM delivery_requests
LIMIT 1;
