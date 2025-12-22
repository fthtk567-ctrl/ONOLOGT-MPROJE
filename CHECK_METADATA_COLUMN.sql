-- metadata kolonunu kontrol et
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'delivery_requests' 
  AND column_name = 'metadata';

-- Eğer default value varsa ve sorunluysa, NULL yap
-- ALTER TABLE delivery_requests ALTER COLUMN metadata DROP DEFAULT;
