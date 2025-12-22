-- Tüm kuryelerin konumlarını kontrol et
SELECT 
    id,
    full_name,
    email,
    role,
    is_available,
    is_active,
    status,
    current_location,
    updated_at,
    last_login
FROM users
WHERE role = 'courier'
ORDER BY updated_at DESC;

-- Konum bilgisi olan kuryeleri göster
SELECT 
    full_name,
    email,
    is_available,
    current_location,
    current_location->>'latitude' as lat,
    current_location->>'longitude' as lng,
    current_location->>'updated_at' as location_updated,
    updated_at as profile_updated,
    last_login
FROM users
WHERE role = 'courier'
  AND current_location IS NOT NULL
ORDER BY updated_at DESC;

-- Müsait ve konum bilgisi olan kuryeleri göster
SELECT 
    full_name,
    email,
    is_available,
    current_location,
    current_location->>'latitude' as lat,
    current_location->>'longitude' as lng,
    current_location->>'updated_at' as location_updated,
    EXTRACT(EPOCH FROM (NOW() - (current_location->>'updated_at')::timestamp)) / 60 as minutes_since_update
FROM users
WHERE role = 'courier'
  AND is_available = true
  AND current_location IS NOT NULL
ORDER BY updated_at DESC;
