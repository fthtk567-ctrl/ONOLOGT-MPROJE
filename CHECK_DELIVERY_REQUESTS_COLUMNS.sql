-- delivery_requests tablosunun column'larını göster
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'delivery_requests'
ORDER BY ordinal_position;
