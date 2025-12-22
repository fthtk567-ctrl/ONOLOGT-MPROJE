-- Test kuryeleri oluştur ve konumlandır
WITH test_locations AS (
  SELECT * FROM (VALUES
    ('TEST_KURYE_1', 41.0082, 29.0124, '1km'), -- Yakın
    ('TEST_KURYE_2', 41.0182, 29.0224, '2km'), -- Orta
    ('TEST_KURYE_3', 41.0282, 29.0324, '3km'), -- Uzak
    ('TEST_KURYE_4', 41.0382, 29.0424, '4km')  -- Çok uzak
  ) AS t(name, lat, lng, distance)
)
INSERT INTO users (
  email,
  role,
  owner_name,
  status,
  is_available,
  current_location
)
SELECT
  name || '@test.com',
  'courier',
  name,
  'active',
  true,
  jsonb_build_object(
    'latitude', lat,
    'longitude', lng,
    'distance', distance,
    'updated_at', NOW()
  )
FROM test_locations
ON CONFLICT (email) DO UPDATE
SET current_location = EXCLUDED.current_location,
    is_available = true,
    status = 'active';

-- Test merchant oluştur
INSERT INTO users (
  email,
  role,
  owner_name,
  business_name,
  status,
  current_location
)
VALUES (
  'test.merchant@test.com',
  'merchant',
  'Test Merchant',
  'Test Restaurant',
  'active',
  jsonb_build_object(
    'latitude', 41.0082,
    'longitude', 29.0124,
    'address', 'Test Adres',
    'updated_at', NOW()
  )
)
ON CONFLICT (email) DO UPDATE
SET current_location = EXCLUDED.current_location;