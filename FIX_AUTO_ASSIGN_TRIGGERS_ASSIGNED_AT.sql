-- ======================================================================
-- FIX: Auto-Assign Trigger'larına assigned_at Ekleme
-- ======================================================================
-- Problem: Kurye atandığında assigned_at timestamp'i set edilmiyor
-- Çözüm: Her iki trigger'ı da güncelleyerek assigned_at ekle
-- ======================================================================

-- 1. AUTO ASSIGN TRIGGER FIX
CREATE OR REPLACE FUNCTION auto_assign_courier_to_delivery()
RETURNS TRIGGER AS $$
DECLARE
  best_courier_id UUID;   
  pickup_lat DECIMAL;
  pickup_lng DECIMAL;
  courier_info RECORD;
BEGIN
  -- Sadece pending durumundaki siparişler için
  IF NEW.status = 'pending' THEN
    
    -- Pickup lokasyonunu al
    pickup_lat := (NEW.pickup_location->>'latitude')::DECIMAL;
    pickup_lng := (NEW.pickup_location->>'longitude')::DECIMAL;
    
    RAISE NOTICE '[Auto Assign] Finding courier for delivery %, pickup: %, %', 
      NEW.id, pickup_lat, pickup_lng;
    
    -- En uygun kuryeyi bul
    SELECT id INTO best_courier_id
    FROM users
    WHERE role = 'courier'
      AND is_active = true
      AND is_available = true
      AND is_busy = false
      AND status = 'approved'
      AND (
        (current_location->>'latitude')::DECIMAL IS NOT NULL
        AND (current_location->>'longitude')::DECIMAL IS NOT NULL
      )
    ORDER BY 
      average_rating DESC NULLS LAST,
      created_at ASC
    LIMIT 1;
    
    -- Kurye bulunduysa ata
    IF best_courier_id IS NOT NULL THEN
      
      -- Kurye bilgilerini al
      SELECT owner_name, phone INTO courier_info
      FROM users 
      WHERE id = best_courier_id;
      
      -- Delivery'yi güncelle (assigned_at EKLENDI!)
      UPDATE delivery_requests
      SET 
        courier_id = best_courier_id,
        status = 'assigned',
        assigned_at = NOW(),  -- ✅ BU SATIR EKLENDİ!
        updated_at = NOW()
      WHERE id = NEW.id;
      
      RAISE NOTICE '[Auto Assign] Assigned courier % (%) to delivery %', 
        courier_info.owner_name, best_courier_id, NEW.id;
      
      -- FCM bildirimi gönder
      BEGIN
        PERFORM net.http_post(
          url := current_setting('app.supabase_url', true) || '/functions/v1/send-fcm-notification',
          headers := jsonb_build_object(
            'Authorization', 'Bearer ' || current_setting('app.service_role_key', true),
            'Content-Type', 'application/json'
          ),
          body := jsonb_build_object(
            'userId', best_courier_id,
            'title', CASE 
              WHEN NEW.source = 'yemek_app' THEN '🍕 Yeni Yemek App Teslimatı!'
              WHEN NEW.source = 'trendyol' THEN '🛍️ Yeni Trendyol Teslimatı!'
              WHEN NEW.source = 'getir' THEN '🚀 Yeni Getir Teslimatı!'
              ELSE '📦 Yeni Teslimat!'
            END,
            'body', NEW.package_count || ' paket - ' || NEW.declared_amount || '₺',
            'data', jsonb_build_object(
              'type', 'NEW_DELIVERY',
              'deliveryId', NEW.id,
              'source', COALESCE(NEW.source, 'manual'),
              'externalOrderId', NEW.external_order_id
            )
          )::text
        );
        
        RAISE NOTICE '[Auto Assign] FCM notification sent to courier %', best_courier_id;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[Auto Assign] FCM notification failed: %', SQLERRM;
      END;
      
    ELSE
      RAISE WARNING '[Auto Assign] No available courier found for delivery %', NEW.id;
      
      -- Merchant'a kurye bulunamadı bildirimi
      BEGIN
        PERFORM net.http_post(
          url := current_setting('app.supabase_url', true) || '/functions/v1/send-fcm-notification',
          headers := jsonb_build_object(
            'Authorization', 'Bearer ' || current_setting('app.service_role_key', true),
            'Content-Type', 'application/json'
          ),
          body := jsonb_build_object(
            'userId', NEW.merchant_id,
            'title', '⚠️ Kurye Bulunamadı',
            'body', 'Teslimat için müsait kurye yok. Manuel atama yapabilirsiniz.',
            'data', jsonb_build_object(
              'type', 'NO_COURIER_AVAILABLE',
              'deliveryId', NEW.id
            )
          )::text
        );
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[Auto Assign] Merchant notification failed: %', SQLERRM;
      END;
      
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. AUTO REASSIGN TRIGGER FIX
CREATE OR REPLACE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER AS $$
DECLARE
    v_merchant_location JSONB;
    v_merchant_lat DOUBLE PRECISION;
    v_merchant_lng DOUBLE PRECISION;
    v_best_courier_id UUID;
    v_min_distance DOUBLE PRECISION;
    v_courier RECORD;
    v_distance DOUBLE PRECISION;
BEGIN
    IF NEW.status = 'rejected' AND OLD.status != 'rejected' THEN
        
        v_min_distance := 999999;
        
        SELECT business_location INTO v_merchant_location
        FROM users 
        WHERE id = NEW.merchant_id;
        
        IF v_merchant_location IS NOT NULL THEN
            v_merchant_lat := (v_merchant_location->>'latitude')::DOUBLE PRECISION;
            v_merchant_lng := (v_merchant_location->>'longitude')::DOUBLE PRECISION;
            
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
                
                IF v_distance < v_min_distance AND v_distance <= 50 THEN
                    v_min_distance := v_distance;
                    v_best_courier_id := v_courier.id;
                END IF;
            END LOOP;
            
            IF v_best_courier_id IS NOT NULL THEN
                NEW.courier_id := v_best_courier_id;
                NEW.status := 'assigned';
                NEW.assigned_at := NOW();  -- ✅ BU SATIR EKLENDİ!
                NEW.updated_at := NOW();
            ELSE
                NEW.status := 'pending';
                NEW.courier_id := NULL;
                NEW.assigned_at := NULL;  -- ✅ Kurye yoksa NULL yap
            END IF;
        ELSE
            NEW.status := 'pending';
            NEW.courier_id := NULL;
            NEW.assigned_at := NULL;  -- ✅ Merchant location yoksa NULL
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ✅ Her iki trigger function'ı da güncellendi!
-- Artık kurye atandığında assigned_at otomatik set edilecek.
