-- ============================================
-- OTOMATIK YENIDEN ATAMA SİSTEMİ
-- ============================================
-- Kurye red ettiğinde (status='rejected') otomatik olarak başka kurye bul ve ata

-- 1. ADIM: Fonksiyon oluştur
CREATE OR REPLACE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER AS $$
DECLARE
    v_merchant_location JSONB;
    v_merchant_lat DOUBLE PRECISION;
    v_merchant_lng DOUBLE PRECISION;
    v_best_courier_id UUID;
    v_min_distance DOUBLE PRECISION := 999999;
    v_courier RECORD;
    v_distance DOUBLE PRECISION;
BEGIN
    -- Sadece status 'rejected' olduğunda çalış
    IF NEW.status = 'rejected' AND OLD.status != 'rejected' THEN
        RAISE NOTICE '🔄 Teslimat reddedildi: % - Yeni kurye aranıyor...', NEW.order_number;
        
        -- Merchant'ın iş yeri konumunu al (business_location)
        SELECT business_location INTO v_merchant_location
        FROM users 
        WHERE id = NEW.merchant_id;
        
        IF v_merchant_location IS NOT NULL THEN
            v_merchant_lat := (v_merchant_location->>'latitude')::DOUBLE PRECISION;
            v_merchant_lng := (v_merchant_location->>'longitude')::DOUBLE PRECISION;
            
            RAISE NOTICE '📍 Merchant konumu: %, %', v_merchant_lat, v_merchant_lng;
            
            -- Müsait kuryeleri bul (aktif, mesaide, onaylanmış, red eden hariç)
            FOR v_courier IN
                SELECT 
                    id,
                    full_name,
                    current_location,
                    (current_location->>'latitude')::DOUBLE PRECISION as lat,
                    (current_location->>'longitude')::DOUBLE PRECISION as lng
                FROM users
                WHERE role = 'courier'
                  AND is_active = true           -- ✅ Aktif hesap
                  AND is_available = true        -- ✅ Mesaide
                  AND status = 'approved'        -- ✅ Onaylanmış
                  AND id != NEW.rejected_by      -- ❌ Red eden kurye hariç
                  AND current_location IS NOT NULL
            LOOP
                -- Mesafe hesapla (Haversine formülü ile km cinsinden)
                v_distance := (
                    6371 * acos(
                        cos(radians(v_merchant_lat)) * 
                        cos(radians(v_courier.lat)) * 
                        cos(radians(v_courier.lng) - radians(v_merchant_lng)) + 
                        sin(radians(v_merchant_lat)) * 
                        sin(radians(v_courier.lat))
                    )
                );
                
                RAISE NOTICE '   📊 Kurye: % - Mesafe: % km', v_courier.full_name, ROUND(v_distance::numeric, 2);
                
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
                
                RAISE NOTICE '✅ Yeni kurye atandı: % (Mesafe: % km)', v_best_courier_id, ROUND(v_min_distance::numeric, 2);
                
                -- FCM bildirimi gönder (Edge Function çağrısı yapılabilir)
                -- TODO: HTTP POST ile notification gönder
                
            ELSE
                -- Yakında kurye yok, pending durumuna al
                NEW.status := 'pending';
                NEW.courier_id := NULL;
                RAISE NOTICE '⚠️ 50 km içinde müsait kurye bulunamadı - pending yapıldı';
            END IF;
        ELSE
            -- Merchant konumu yok
            NEW.status := 'pending';
            NEW.courier_id := NULL;
            RAISE NOTICE '⚠️ Merchant konumu bulunamadı - pending yapıldı';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. ADIM: Trigger oluştur
DROP TRIGGER IF EXISTS trigger_auto_reassign_delivery ON delivery_requests;

CREATE TRIGGER trigger_auto_reassign_delivery
    BEFORE UPDATE OF status ON delivery_requests
    FOR EACH ROW
    WHEN (NEW.status = 'rejected')
    EXECUTE FUNCTION auto_reassign_rejected_delivery();

-- 3. ADIM: Test için var olan rejected teslimatları kontrol et
SELECT 
    order_number,
    status,
    courier_id,
    rejected_by,
    created_at
FROM delivery_requests
WHERE status = 'rejected'
ORDER BY created_at DESC;

RAISE NOTICE '✅ Otomatik yeniden atama sistemi kuruldu!';
RAISE NOTICE '📋 Kullanım: Kurye bir teslimatı red ettiğinde (status=rejected), sistem otomatik olarak en yakın müsait kuryeyi bulup atayacak.';
