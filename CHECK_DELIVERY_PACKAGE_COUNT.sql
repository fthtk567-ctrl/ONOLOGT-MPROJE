-- delivery_requests tablosunda paket sayısı var mı?
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND (column_name ILIKE '%package%' OR column_name ILIKE '%paket%' OR column_name ILIKE '%quantity%' OR column_name ILIKE '%count%')
ORDER BY ordinal_position;

-- Tüm kolonları göster
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
ORDER BY ordinal_position;
