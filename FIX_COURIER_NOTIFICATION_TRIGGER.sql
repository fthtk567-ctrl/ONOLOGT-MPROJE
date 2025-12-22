-- =================================================================
-- ONLOG - Courier'a Bildirim Gönderen Trigger (DÜZELTME)
-- Yeni teslimat isteği oluşturulduğunda COURIER'A bildirim gönder
-- =================================================================

-- Trigger Function'ı güncelle - COURIER'ın FCM token'ını al
CREATE OR REPLACE FUNCTION add_notification_to_queue()
RETURNS TRIGGER AS $$
DECLARE
    courier_fcm_token TEXT;
    merchant_name TEXT;
BEGIN
    -- Eğer courier atanmışsa, COURIER'ın FCM token'ını al
    IF NEW.courier_id IS NOT NULL THEN
        SELECT fcm_token INTO courier_fcm_token
        FROM users
        WHERE id = NEW.courier_id;
        
        -- Merchant ismini al (bildirimde gösterilecek)
        SELECT COALESCE(business_name, full_name, owner_name, 'İşletme')
        INTO merchant_name
        FROM users
        WHERE id = NEW.merchant_id;
        
        -- Eğer courier'ın FCM token'ı varsa kuyruğa ekle
        IF courier_fcm_token IS NOT NULL THEN
            INSERT INTO notification_queue (
                delivery_request_id,
                merchant_id,
                fcm_token,
                title,
                body,
                data,
                processed
            ) VALUES (
                NEW.id,
                NEW.merchant_id,
                courier_fcm_token,  -- COURIER'IN TOKEN'I!
                '🚀 Yeni Teslimat İsteği',
                'Toplam tutar: ' || COALESCE(NEW.declared_amount::TEXT, '0') || ' TL - ' || COALESCE(NEW.package_count::TEXT, '0') || ' paket',
                jsonb_build_object(
                    'type', 'new_delivery_request',
                    'delivery_request_id', NEW.id,
                    'merchant_id', NEW.merchant_id,
                    'merchant_name', merchant_name,
                    'declared_amount', NEW.declared_amount,
                    'package_count', NEW.package_count,
                    'status', NEW.status
                ),
                FALSE
            );
            
            RAISE NOTICE '✅ COURIER bildirim kuyruğa eklendi: % -> %', NEW.id, NEW.courier_id;
        ELSE
            RAISE NOTICE '⚠️ Courier FCM token yok: %', NEW.courier_id;
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Courier atanmamış: %', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger zaten var, sadece function'ı güncelledik
-- Test için:
-- INSERT INTO delivery_requests (merchant_id, courier_id, declared_amount, package_count) 
-- VALUES ('merchant-uuid', 'courier-uuid', 100.00, 2);
