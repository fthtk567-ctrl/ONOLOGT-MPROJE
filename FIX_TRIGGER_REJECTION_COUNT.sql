-- Trigger'ı düzelt - rejection_count kontrolü kaldır

DROP FUNCTION IF EXISTS auto_reassign_rejected_delivery() CASCADE;

CREATE OR REPLACE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS '
DECLARE
  v_next_courier_id UUID;
  v_rejected_courier_ids UUID[];
  v_rejected_count INTEGER;
BEGIN
  -- Kurye ID NULL yapıldığında ve rejected_by dolu ise çalış
  IF (TG_OP = ''UPDATE'' AND 
      OLD.courier_id IS NOT NULL AND 
      NEW.courier_id IS NULL AND
      jsonb_array_length(NEW.rejected_by) > 0) THEN
    
    RAISE NOTICE ''Teslimat reddedildi, yeni kurye aranıyor...'';
    
    -- rejection_count güncelle
    v_rejected_count := jsonb_array_length(NEW.rejected_by);
    
    UPDATE delivery_requests
    SET rejection_count = v_rejected_count
    WHERE id = NEW.id;
    
    -- Reddeden kuryeler listesi
    SELECT ARRAY(
      SELECT jsonb_array_elements_text(NEW.rejected_by)::UUID
    ) INTO v_rejected_courier_ids;
    
    -- Yeni kurye bul
    SELECT id INTO v_next_courier_id
    FROM users
    WHERE role = ''courier''
      AND is_active = true
      AND status = ''approved''
      AND is_available = true
      AND NOT (id = ANY(v_rejected_courier_ids))
    ORDER BY RANDOM()
    LIMIT 1;
    
    IF v_next_courier_id IS NOT NULL THEN
      UPDATE delivery_requests
      SET 
        courier_id = v_next_courier_id,
        status = ''assigned'',
        assigned_at = NOW(),
        updated_at = NOW()
      WHERE id = NEW.id;
      
      RAISE NOTICE ''Teslimat yeni kuryeye atandi'';
      
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      ) VALUES (
        v_next_courier_id,
        ''Yeni Teslimat Istegi'',
        ''Bir onceki kurye reddetti, size atandi - Tutar: '' || NEW.declared_amount || '' TL'',
        ''new_order'',
        false,
        NOW()
      );
    ELSE
      RAISE NOTICE ''Musait kurye bulunamadi'';
      
      UPDATE delivery_requests
      SET status = ''pending''
      WHERE id = NEW.id;
      
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      ) VALUES (
        NEW.merchant_id,
        ''Kurye Bulunamadi'',
        ''Siparis #'' || NEW.order_number || '' icin musait kurye bulunamadi.'',
        ''courier_not_found'',
        false,
        NOW()
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
';

CREATE TRIGGER trigger_auto_reassign_delivery
  AFTER UPDATE OF courier_id
  ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_reassign_rejected_delivery();

SELECT '✅ Trigger düzeltildi - artık rejected_by array kontrolü ile çalışıyor!' as status;
