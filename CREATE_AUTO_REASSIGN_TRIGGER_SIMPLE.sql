-- ============================================
-- OTOMATIK YENIDEN ATAMA SİSTEMİ - BASİTLEŞTİRİLMİŞ
-- ============================================

-- 1. ADIM: Eski trigger ve fonksiyonu temizle
DROP TRIGGER IF EXISTS trigger_auto_reassign_delivery ON delivery_requests;
DROP FUNCTION IF EXISTS auto_reassign_rejected_delivery();

-- 2. ADIM: Yeni fonksiyon oluştur
CREATE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
DECLARE
    v_merchant_location JSONB;
    v_merchant_lat DOUBLE PRECISION;
    v_merchant_lng DOUBLE PRECISION;
    v_best_courier_id UUID;
    v_min_distance DOUBLE PRECISION;
    v_courier RECORD;
    v_distance DOUBLE PRECISION;
BEGIN
    -- Sadece status 'rejected' olduğunda çalış
    IF NEW.status = 'rejected' AND OLD.status != 'rejected' THEN
        
        v_min_distance := 999999;
        
        -- Merchant'ın iş yeri konumunu al (business_location)
        SELECT business_location INTO v_merchant_location
        FROM users 
        WHERE id = NEW.merchant_id;
        
        IF v_merchant_location IS NOT NULL THEN
            v_merchant_lat := (v_merchant_location->>'latitude')::DOUBLE PRECISION;
            v_merchant_lng := (v_merchant_location->>'longitude')::DOUBLE PRECISION;
            
            -- Müsait kuryeleri bul (aktif, mesaide, onaylanmış, red eden hariç)
            FOR v_courier IN
                SELECT 
                    id,
                    full_name,
                    (current_location->>'latitude')::DOUBLE PRECISION as lat,
                    (current_location->>'longitude')::DOUBLE PRECISION as lng
                FROM users
                WHERE role = 'courier'
                  AND is_active = true
                  AND is_available = true
                  AND status = 'approved'
                  AND id != NEW.rejected_by
                  AND current_location IS NOT NULL
            LOOP
                -- Mesafe hesapla (Haversine formülü ile km cinsinden)
                v_distance := (
                    6371 * acos(
                        LEAST(1.0, GREATEST(-1.0,
                            cos(radians(v_merchant_lat)) * 
                            cos(radians(v_courier.lat)) * 
                            cos(radians(v_courier.lng) - radians(v_merchant_lng)) + 
                            sin(radians(v_merchant_lat)) * 
                            sin(radians(v_courier.lat))
                        ))
                    )
                );
                
                -- En yakın kuryeyi bul (50 km içinde)
                IF v_distance < v_min_distance AND v_distance <= 50 THEN
                    v_min_distance := v_distance;
                    v_best_courier_id := v_courier.id;
                END IF;
            END LOOP;
            
            -- En yakın kurye bulunduysa ata
            IF v_best_courier_id IS NOT NULL THEN
                NEW.courier_id := v_best_courier_id;
                NEW.status := 'assigned';
                NEW.updated_at := NOW();
            ELSE
                -- Yakında kurye yok, pending durumuna al
                NEW.status := 'pending';
                NEW.courier_id := NULL;
            END IF;
        ELSE
            -- Merchant konumu yok
            NEW.status := 'pending';
            NEW.courier_id := NULL;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- 3. ADIM: Trigger oluştur
CREATE TRIGGER trigger_auto_reassign_delivery
    BEFORE UPDATE OF status ON delivery_requests
    FOR EACH ROW
    WHEN (NEW.status = 'rejected')
    EXECUTE FUNCTION auto_reassign_rejected_delivery();
