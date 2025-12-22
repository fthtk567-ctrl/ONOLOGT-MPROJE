-- 1. Yeni kolonlar ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS nearest_couriers UUID[] DEFAULT ARRAY[]::UUID[],
ADD COLUMN IF NOT EXISTS priority_deadline TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS limited_visibility_deadline TIMESTAMPTZ;

-- 2. En yakın kuryeleri bulma fonksiyonu
CREATE OR REPLACE FUNCTION find_nearest_couriers(
    p_merchant_lat FLOAT,
    p_merchant_lng FLOAT,
    p_limit INTEGER DEFAULT 3
) RETURNS UUID[] AS $$
DECLARE
    v_courier_list UUID[];
BEGIN
    -- En yakın kuryeleri bul (PostGIS ST_Distance kullanarak)
    SELECT ARRAY_AGG(id) INTO v_courier_list
    FROM (
        SELECT 
            id,
            ST_Distance(
                ST_SetSRID(ST_MakePoint(current_location->>'longitude', current_location->>'latitude')::geometry, 4326),
                ST_SetSRID(ST_MakePoint(p_merchant_lng, p_merchant_lat)::geometry, 4326)
            ) as distance
        FROM users
        WHERE 
            role = 'courier'
            AND status = 'active'
            AND is_available = true
            AND current_location IS NOT NULL
        ORDER BY distance ASC
        LIMIT p_limit
    ) nearest;

    RETURN v_courier_list;
END;
$$ LANGUAGE plpgsql;

-- 3. Teslimat oluşturma trigger'ını güncelle
CREATE OR REPLACE FUNCTION set_delivery_deadlines() RETURNS TRIGGER AS $$
DECLARE
    v_merchant_location JSONB;
    v_merchant_lat FLOAT;
    v_merchant_lng FLOAT;
BEGIN
    -- Merchant konumunu al
    SELECT current_location INTO v_merchant_location
    FROM users 
    WHERE id = NEW.merchant_id;

    v_merchant_lat := (v_merchant_location->>'latitude')::FLOAT;
    v_merchant_lng := (v_merchant_location->>'longitude')::FLOAT;

    -- En yakın kuryeleri bul
    NEW.nearest_couriers := find_nearest_couriers(v_merchant_lat, v_merchant_lng, 3);
    
    -- Deadlines ayarla
    NEW.priority_deadline := NOW() + INTERVAL '30 seconds';  -- İlk 30 saniye sadece en yakın 3 kurye
    NEW.limited_visibility_deadline := NOW() + INTERVAL '2 minutes';  -- Sonraki 1.5 dakika 5km içindekiler
    NEW.final_deadline := NOW() + INTERVAL '10 minutes';  -- Son 8 dakika 10km içindekiler

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Güvenli kurye kabul fonksiyonu
CREATE OR REPLACE FUNCTION safe_accept_delivery(
    p_delivery_id UUID,
    p_courier_id UUID
) RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_delivery delivery_requests;
    v_distance FLOAT;
BEGIN
    -- Transaction başlat
    BEGIN
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        
        -- Teslimatı kilitle ve bilgileri al
        SELECT * INTO v_delivery
        FROM delivery_requests 
        WHERE id = p_delivery_id 
        AND status = 'pending'
        FOR UPDATE SKIP LOCKED;
        
        -- Teslimat kontrolü
        IF v_delivery IS NULL THEN
            RETURN QUERY SELECT false, 'Bu teslimat isteği artık müsait değil.'::TEXT;
            RETURN;
        END IF;

        -- Zaman ve mesafe kontrolü
        IF NOW() < v_delivery.priority_deadline THEN
            -- İlk 30 saniye: Sadece en yakın 3 kurye
            IF NOT (p_courier_id = ANY(v_delivery.nearest_couriers)) THEN
                RETURN QUERY SELECT false, 'Bu teslimat şu anda en yakın kuryelere özel.'::TEXT;
                RETURN;
            END IF;
        ELSIF NOW() < v_delivery.limited_visibility_deadline THEN
            -- Sonraki 1.5 dakika: 5km içindeki kuryeler
            IF NOT check_courier_distance(p_courier_id, v_delivery.merchant_id, 5000) THEN
                RETURN QUERY SELECT false, 'Bu teslimat şu anda 5km içindeki kuryelere özel.'::TEXT;
                RETURN;
            END IF;
        ELSE
            -- Son 8 dakika: 10km içindeki kuryeler
            IF NOT check_courier_distance(p_courier_id, v_delivery.merchant_id, 10000) THEN
                RETURN QUERY SELECT false, 'Bu teslimat 10km mesafe sınırı dışında.'::TEXT;
                RETURN;
            END IF;
        END IF;

        -- Kurye müsaitlik kontrolü
        IF EXISTS (
            SELECT 1 FROM delivery_requests 
            WHERE courier_id = p_courier_id 
            AND status IN ('assigned', 'picked_up', 'delivering')
        ) THEN
            RETURN QUERY SELECT false, 'Aktif teslimatınız varken yeni teslimat alamazsınız.'::TEXT;
            RETURN;
        END IF;

        -- Teslimatı güvenli şekilde güncelle
        UPDATE delivery_requests 
        SET 
            courier_id = p_courier_id,
            status = 'assigned',
            assigned_at = NOW(),
            updated_at = NOW()
        WHERE id = p_delivery_id;

        RETURN QUERY SELECT true, 'Teslimat başarıyla alındı!'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT false, 'Bir hata oluştu: ' || SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql;

-- 5. Mesafe kontrol yardımcı fonksiyonu
CREATE OR REPLACE FUNCTION check_courier_distance(
    p_courier_id UUID,
    p_merchant_id UUID,
    p_max_distance_meters FLOAT
) RETURNS BOOLEAN AS $$
DECLARE
    v_distance FLOAT;
BEGIN
    SELECT 
        ST_Distance(
            ST_SetSRID(ST_MakePoint(
                (c.current_location->>'longitude')::FLOAT, 
                (c.current_location->>'latitude')::FLOAT
            )::geometry, 4326),
            ST_SetSRID(ST_MakePoint(
                (m.current_location->>'longitude')::FLOAT, 
                (m.current_location->>'latitude')::FLOAT
            )::geometry, 4326)
        ) INTO v_distance
    FROM users c, users m
    WHERE c.id = p_courier_id AND m.id = p_merchant_id;

    RETURN COALESCE(v_distance <= p_max_distance_meters, false);
END;
$$ LANGUAGE plpgsql;