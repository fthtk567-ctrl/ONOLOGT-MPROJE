-- Delivery Requests tablosuna red bilgilerini ekle

-- 1. ÖNCE eski trigger varsa sil (kolon tipini değiştireceğimiz için)
DROP TRIGGER IF EXISTS trigger_auto_reassign_delivery ON delivery_requests;
DROP FUNCTION IF EXISTS auto_reassign_rejected_delivery() CASCADE;

-- 2. Foreign key constraint'i sil (rejected_by UUID'den JSONB'ye dönüşecek)
ALTER TABLE delivery_requests 
DROP CONSTRAINT IF EXISTS delivery_requests_rejected_by_fkey;

-- 3. rejected_by kolonunu JSONB array'e dönüştür ve rejection_count ekle
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by TYPE JSONB USING 
  CASE 
    WHEN rejected_by IS NULL THEN '[]'::jsonb
    ELSE jsonb_build_array(rejected_by)
  END;

ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by SET DEFAULT '[]'::jsonb;

ALTER TABLE delivery_requests
ADD COLUMN IF NOT EXISTS rejection_count INTEGER DEFAULT 0;

-- 4. Otomatik yeniden atama fonksiyonu (şimdi güvenle oluşturabiliriz)
CREATE OR REPLACE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
DECLARE
  v_next_courier_id UUID;
  v_rejected_courier_ids UUID[];
BEGIN
  -- Sadece courier_id NULL yapıldığında ve rejection_count > 0 ise çalış
  IF (TG_OP = 'UPDATE' AND 
      OLD.courier_id IS NOT NULL AND 
      NEW.courier_id IS NULL AND
      NEW.rejection_count > 0) THEN
    
    RAISE NOTICE 'Teslimat reddedildi, yeni kurye aranıyor...';
    
    -- Daha önce reddeden kuryeler listesi
    SELECT ARRAY(
      SELECT jsonb_array_elements_text(NEW.rejected_by)::UUID
    ) INTO v_rejected_courier_ids;
    
    -- Yeni kurye bul (reddedenlerin dışında, aktif ve müsait)
    SELECT id INTO v_next_courier_id
    FROM users
    WHERE role = 'courier'
      AND is_active = true
      AND status = 'approved'
      AND is_available = true
      AND NOT (id = ANY(v_rejected_courier_ids))
    ORDER BY RANDOM()
    LIMIT 1;
    
    IF v_next_courier_id IS NOT NULL THEN
      -- Yeni kuryeye ata
      UPDATE delivery_requests
      SET 
        courier_id = v_next_courier_id,
        status = 'assigned',
        assigned_at = NOW(),
        updated_at = NOW()
      WHERE id = NEW.id;
      
      RAISE NOTICE 'Teslimat yeni kuryeye atandi';
      
      -- Bildirim gönder
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      ) VALUES (
        v_next_courier_id,
        'Yeni Teslimat Istegi',
        'Bir onceki kurye reddetti, size atandi - Tutar: ' || NEW.declared_amount || ' TL',
        'new_order',
        false,
        NOW()
      );
    ELSE
      -- Müsait kurye bulunamadı - merchant'a bildir
      RAISE NOTICE 'Musait kurye bulunamadi';
      
      UPDATE delivery_requests
      SET status = 'pending'
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
        'Kurye Bulunamadi',
        'Siparis #' || NEW.order_number || ' icin musait kurye bulunamadi. Lutfen daha sonra tekrar deneyin.',
        'courier_not_found',
        false,
        NOW()
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- 5. Trigger oluştur (fonksiyon hazır olduğuna göre)
CREATE TRIGGER trigger_auto_reassign_delivery
  AFTER UPDATE OF courier_id
  ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_reassign_rejected_delivery();

-- ✅ TAMAM!
SELECT '✅ Otomatik yeniden atama sistemi kuruldu!' as status;
