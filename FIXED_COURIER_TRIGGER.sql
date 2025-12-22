-- ============================================
-- KURYE BİLDİRİM TRİGGER'I OLUŞTUR
-- ============================================
CREATE OR REPLACE FUNCTION notify_courier_new_delivery()
RETURNS TRIGGER AS $$
BEGIN
  -- notifications tablosuna ekle
  INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
  ) VALUES (
    NEW.courier_id,
    'new_delivery',
    'Yeni Teslimat!',
    'Tutar: ' || NEW.declared_amount || ' TL - Kazanç: ' || NEW.courier_payment_due || ' TL',
    false,
    NOW()
  );
  
  RAISE NOTICE 'Bildirim olusturuldu: Courier=%, Delivery=%', NEW.courier_id, NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı oluştur
DROP TRIGGER IF EXISTS trigger_notify_courier_on_new_delivery ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_on_new_delivery
AFTER INSERT ON delivery_requests
FOR EACH ROW
EXECUTE FUNCTION notify_courier_new_delivery();