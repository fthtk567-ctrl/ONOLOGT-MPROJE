-- Payment trigger'ını güncelle - SADECE FREELANCE KURYELER KAZANÇ ALSIN

CREATE OR REPLACE FUNCTION process_order_payment_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_commission_rate DECIMAL;
  v_fixed_fee DECIMAL;
  v_vat_rate DECIMAL;
  v_merchant_commission DECIMAL;
  v_merchant_earnings DECIMAL;
  v_delivery_fee DECIMAL;
  v_courier_type TEXT;
BEGIN
  -- Sadece DELIVERED durumuna geçişte çalış
  IF NEW.status = 'DELIVERED' AND (OLD.status IS NULL OR OLD.status != 'DELIVERED') THEN
    
    -- Komisyon ayarlarını al
    SELECT commission_rate, fixed_fee, vat_rate
    INTO v_commission_rate, v_fixed_fee, v_vat_rate
    FROM commission_configs
    WHERE merchant_id IS NULL OR merchant_id = NEW.merchant_id
    ORDER BY merchant_id NULLS LAST
    LIMIT 1;

    -- Varsayılan değerler
    v_commission_rate := COALESCE(v_commission_rate, 0.15);
    v_fixed_fee := COALESCE(v_fixed_fee, 2.00);
    v_vat_rate := COALESCE(v_vat_rate, 0.18);

    -- Hesaplamalar
    v_merchant_commission := (NEW.total_amount * v_commission_rate) + v_fixed_fee;
    v_merchant_commission := v_merchant_commission * (1 + v_vat_rate);
    v_merchant_earnings := NEW.total_amount - v_merchant_commission;
    v_delivery_fee := NEW.delivery_fee;

    -- SATICI ÖDEMESİNİ OLUŞTUR (her zaman)
    INSERT INTO payment_transactions (
      order_id,
      merchant_id,
      type,
      amount,
      commission_amount,
      net_amount,
      status,
      payment_method
    ) VALUES (
      NEW.id,
      NEW.merchant_id,
      'orderPayment',
      NEW.total_amount,
      v_merchant_commission,
      v_merchant_earnings,
      'completed',
      NEW.payment_method
    );

    -- KURYE TİPİNİ KONTROL ET
    IF NEW.courier_id IS NOT NULL THEN
      SELECT courier_type INTO v_courier_type
      FROM users
      WHERE id = NEW.courier_id;
      
      -- SADECE FREELANCE KURYE İSE ÖDEME OLUŞTUR
      IF v_courier_type = 'freelance' AND v_delivery_fee > 0 THEN
        INSERT INTO payment_transactions (
          order_id,
          courier_id,
          type,
          amount,
          commission_amount,
          net_amount,
          status,
          payment_method
        ) VALUES (
          NEW.id,
          NEW.courier_id,
          'deliveryFee',
          v_delivery_fee,
          0,
          v_delivery_fee,
          'completed',
          NEW.payment_method
        );

        -- Kurye cüzdanını güncelle
        PERFORM update_courier_wallet(NEW.courier_id, v_delivery_fee);
      END IF;
    END IF;

    -- Satıcı cüzdanını güncelle
    PERFORM update_merchant_wallet(NEW.merchant_id, v_merchant_earnings, v_merchant_commission);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı yeniden oluştur
DROP TRIGGER IF EXISTS trigger_process_payment_on_delivery ON orders;
CREATE TRIGGER trigger_process_payment_on_delivery
  AFTER INSERT OR UPDATE OF status ON orders
  FOR EACH ROW
  EXECUTE FUNCTION process_order_payment_on_delivery();
