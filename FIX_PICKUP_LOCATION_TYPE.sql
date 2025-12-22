-- pickup_location ve delivery_location kolonlarını TEXT tipine çevir
ALTER TABLE delivery_requests 
  ALTER COLUMN pickup_location TYPE TEXT USING pickup_location::TEXT;

ALTER TABLE delivery_requests 
  ALTER COLUMN delivery_location TYPE TEXT USING delivery_location::TEXT;

-- Kontrol et
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'delivery_requests' 
  AND column_name IN ('pickup_location', 'delivery_location');
