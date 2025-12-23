-- Delivery Requests tablo yapısını kontrol et
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
ORDER BY ordinal_position;
 