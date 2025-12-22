-- En yakın kuryeleri bulma fonksiyonunu güncelle
CREATE OR REPLACE FUNCTION find_nearest_couriers(
    p_merchant_lat FLOAT,
    p_merchant_lng FLOAT,
    p_max_distance_km FLOAT DEFAULT 5.0, -- Maksimum 5km mesafe
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
    -- En yakın kuryeleri bul (PostGIS ST_Distance kullanarak)
    WITH courier_distances AS (
        SELECT 
            id,
            ST_Distance(
                ST_SetSRID(ST_MakePoint(current_location->>'longitude', current_location->>'latitude')::geometry, 4326),
                ST_SetSRID(ST_MakePoint(p_merchant_lng, p_merchant_lat)::geometry, 4326)
            ) * 111.32 as distance_km -- Yaklaşık km cinsinden mesafe
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

-- Teslimat oluşturma trigger'ını akıllı hale getir
CREATE OR REPLACE FUNCTION set_smart_delivery_deadlines() RETURNS TRIGGER AS $$
DECLARE
    v_merchant_location JSONB;
    v_merchant_lat FLOAT;
    v_merchant_lng FLOAT;
    v_nearest_result RECORD;
BEGIN
    -- Merchant konumunu al
    SELECT current_location INTO v_merchant_location
    FROM users 
    WHERE id = NEW.merchant_id;

    v_merchant_lat := (v_merchant_location->>'latitude')::FLOAT;
    v_merchant_lng := (v_merchant_location->>'longitude')::FLOAT;

    -- En yakın kuryeleri bul
    SELECT * INTO v_nearest_result 
    FROM find_nearest_couriers(v_merchant_lat, v_merchant_lng, 5.0);

    -- Yakındaki kurye sayısına göre strateji belirle
    IF v_nearest_result.found_count = 0 THEN
        -- Hiç yakın kurye yoksa direkt 10km'ye çık
        NEW.nearest_couriers := ARRAY[]::UUID[];
        NEW.priority_deadline := NOW(); -- Hemen bitse priority phase
        NEW.limited_visibility_deadline := NOW() + INTERVAL '5 minutes';
        NEW.final_deadline := NOW() + INTERVAL '10 minutes';
        
    ELSIF v_nearest_result.found_count < 3 THEN
        -- 1-2 yakın kurye varsa
        NEW.nearest_couriers := v_nearest_result.courier_ids;
        NEW.priority_deadline := NOW() + INTERVAL '20 seconds'; -- Daha kısa priority süresi
        NEW.limited_visibility_deadline := NOW() + INTERVAL '2 minutes';
        NEW.final_deadline := NOW() + INTERVAL '10 minutes';
        
    ELSE
        -- 3 veya daha fazla yakın kurye varsa normal strateji
        NEW.nearest_couriers := v_nearest_result.courier_ids;
        NEW.priority_deadline := NOW() + INTERVAL '30 seconds';
        NEW.limited_visibility_deadline := NOW() + INTERVAL '2 minutes';
        NEW.final_deadline := NOW() + INTERVAL '10 minutes';
    END IF;

    -- Log kaydı
    INSERT INTO delivery_logs (
        delivery_id,
        merchant_id,
        nearby_courier_count,
        max_distance_km,
        strategy_type,
        created_at
    ) VALUES (
        NEW.id,
        NEW.merchant_id,
        v_nearest_result.found_count,
        v_nearest_result.max_distance_found,
        CASE 
            WHEN v_nearest_result.found_count = 0 THEN 'NO_NEARBY_COURIERS'
            WHEN v_nearest_result.found_count < 3 THEN 'LIMITED_NEARBY_COURIERS'
            ELSE 'NORMAL'
        END,
        NOW()
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Loglama tablosu
CREATE TABLE IF NOT EXISTS delivery_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    delivery_id UUID REFERENCES delivery_requests(id),
    merchant_id UUID REFERENCES users(id),
    nearby_courier_count INTEGER,
    max_distance_km FLOAT,
    strategy_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger'ı güncelle
DROP TRIGGER IF EXISTS set_delivery_deadlines ON delivery_requests;
CREATE TRIGGER set_smart_delivery_deadlines
    BEFORE INSERT ON delivery_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_smart_delivery_deadlines();