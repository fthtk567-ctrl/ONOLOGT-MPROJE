-- En yakın kuryeleri bulma fonksiyonunu düzelt
CREATE OR REPLACE FUNCTION find_nearest_couriers(
    p_merchant_lat FLOAT,
    p_merchant_lng FLOAT,
    p_max_distance_km FLOAT DEFAULT 5.0,
    p_limit INTEGER DEFAULT 3
) RETURNS TABLE (
    courier_ids UUID[],
    found_count INTEGER,
    max_distance_found FLOAT
) AS $$
DECLARE
    v_courier_list UUID[];
    v_found_count INTEGER;
    v_max_distance FLOAT;
BEGIN
    WITH courier_distances AS (
        SELECT 
            id,
            -- JSON'dan gelen değerleri FLOAT'a çevir
            (
                sqrt(
                    power(CAST(current_location->>'latitude' AS FLOAT) - p_merchant_lat, 2) +
                    power(CAST(current_location->>'longitude' AS FLOAT) - p_merchant_lng, 2)
                ) * 111.32
            ) as distance_km
        FROM users
        WHERE 
            role = 'courier'
            AND status = 'active'
            AND is_available = true
            AND current_location IS NOT NULL
            AND current_location->>'latitude' IS NOT NULL
            AND current_location->>'longitude' IS NOT NULL
    )
    SELECT 
        ARRAY_AGG(id),
        COUNT(*)::INTEGER,
        MAX(distance_km)
    INTO v_courier_list, v_found_count, v_max_distance
    FROM (
        SELECT id, distance_km
        FROM courier_distances
        WHERE distance_km <= p_max_distance_km
        ORDER BY distance_km ASC
        LIMIT p_limit
    ) nearest;

    RETURN QUERY SELECT 
        COALESCE(v_courier_list, ARRAY[]::UUID[]),
        COALESCE(v_found_count, 0),
        COALESCE(v_max_distance, 0.0);
END;
$$ LANGUAGE plpgsql;