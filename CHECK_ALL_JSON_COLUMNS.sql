-- delivery_requests tablosundaki TÜM JSONB kolonları kontrol et
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns 
WHERE table_name = 'delivery_requests' 
  AND (data_type = 'jsonb' OR data_type = 'json')
ORDER BY ordinal_position;
