-- PostGIS extension'ı etkinleştir (geometry tipi için)
CREATE EXTENSION IF NOT EXISTS postgis;

-- delivery_requests tablosuna lokasyon kolonları ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS pickup_location geometry(Point, 4326),
ADD COLUMN IF NOT EXISTS delivery_location geometry(Point, 4326);

-- İndeks ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_delivery_requests_pickup_location 
ON delivery_requests USING GIST(pickup_location);

CREATE INDEX IF NOT EXISTS idx_delivery_requests_delivery_location 
ON delivery_requests USING GIST(delivery_location);

-- Test: Kolonları listele
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'delivery_requests' 
AND column_name IN ('pickup_location', 'delivery_location');
