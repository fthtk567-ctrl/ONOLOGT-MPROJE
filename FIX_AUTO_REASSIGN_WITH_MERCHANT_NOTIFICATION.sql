-- YENIDEN ATAMA TRİGGER'INI İYİLEŞTİR
-- Müsait kurye bulunamazsa merchant'a bildirim gönder

CREATE OR REPLACE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_next_courier_id UUID;
BEGIN
  -- Sadece RED edilen teslimatlar için (status=pending, courier_id=NULL)
  IF NEW.status = 'pending' AND NEW.courier_id IS NULL AND NEW.rejected_by IS NOT NULL THEN
    
    RAISE NOTICE '🔄 Red edilen teslimat yeniden atanıyor: %', NEW.id;
    
    -- En yakın başka kuryeyi bul (red eden hariç)
    SELECT id INTO v_next_courier_id
    FROM users
    WHERE 
      role = 'courier'
      AND is_available = true
      AND (penalty_until IS NULL OR penalty_until <= NOW())
      AND id != NEW.rejected_by
      AND status = 'approved'
    ORDER BY 
      ST_Distance(
        current_location,
        (SELECT business_location FROM users WHERE id = NEW.merchant_id)
      )
    LIMIT 1;
    
    IF v_next_courier_id IS NOT NULL THEN
      -- ✅ Yeni kuryeye ata
      UPDATE delivery_requests
      SET 
        courier_id = v_next_courier_id,
        status = 'assigned',
        updated_at = NOW()
      WHERE id = NEW.id;
      
      RAISE NOTICE '✅ Yeni kurye atandı: %', v_next_courier_id;
      
      -- Kuryeye bildirim gönder
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      ) VALUES (
        v_next_courier_id,
        '🚀 Yeni Teslimat İsteği!',
        'Başka kurye reddetti, size atandı - Tutar: ' || NEW.declared_amount || ' TL',
        'delivery',
        false,
        NOW()
      );
    ELSE
      -- ❌ Müsait kurye bulunamadı - İsteği iptal et ve merchant'a bildir
      RAISE NOTICE '⚠️ Müsait kurye bulunamadı - İstek iptal ediliyor!';
      
      UPDATE delivery_requests
      SET 
        status = 'cancelled',
        rejection_reason = 'Müsait kurye bulunamadı',
        updated_at = NOW()
      WHERE id = NEW.id;
      
      -- Merchant'a bildirim gönder
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      ) VALUES (
        NEW.merchant_id,
        '❌ Teslimat İptal Edildi',
        'Sipariş #' || COALESCE(NEW.order_number, NEW.id::TEXT) || ' - Müsait kurye bulunamadı. Lütfen daha sonra tekrar deneyin.',
        'delivery_cancelled',
        false,
        NOW()
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı yeniden oluştur
DROP TRIGGER IF EXISTS trigger_auto_reassign ON delivery_requests;
CREATE TRIGGER trigger_auto_reassign
  AFTER UPDATE OF courier_id, rejected_by
  ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_reassign_rejected_delivery();

-- Test için kontrol
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_reassign';
