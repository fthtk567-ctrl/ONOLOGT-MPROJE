-- ============================================
-- ÖDEME TRİGGER'INI GÜNCELLE
-- ============================================
-- Artık orders tablosundaki commission_type ve commission_value kullanılacak
-- Böylece eski siparişler eski komisyonla hesaplanır!

CREATE OR REPLACE FUNCTION process_order_payment_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  merchant_id UUID;
  courier_id UUID;
  order_amount NUMERIC;
  delivery_fee NUMERIC;
  
  -- ⚠️ YENİ: Siparişten komisyon bilgilerini al
  order_commission_type TEXT;
  order_commission_value NUMERIC;
  
  platform_commission NUMERIC;
  merchant_earning NUMERIC;
  courier_earning NUMERIC;
BEGIN
  -- Temel bilgileri al
  merchant_id := NEW.restaurant_id;
  courier_id := NEW.courier_id;
  order_amount := NEW.total_amount;
  delivery_fee := NEW.delivery_fee;
  
  -- 🔒 SİPARİŞ ANINDAKİ KOMİSYON BİLGİSİNİ KULLAN
  order_commission_type := NEW.commission_type;
  order_commission_value := NEW.commission_value;
  
  RAISE NOTICE 'Sipariş komisyon bilgisi: type=%, value=%', order_commission_type, order_commission_value;
  
  -- Komisyon hesapla
  IF order_commission_type = 'percentage' THEN
    -- Yüzdelik komisyon
    platform_commission := (order_amount * order_commission_value / 100);
    RAISE NOTICE 'Yüzdelik komisyon: oran=%, tutar=%', order_commission_value, platform_commission;
  ELSIF order_commission_type = 'perOrder' THEN
    -- Sipariş başı sabit ücret
    platform_commission := order_commission_value;
    RAISE NOTICE 'Sipariş başı komisyon: %', platform_commission;
  ELSE
    -- Default: %15 (eski siparişler için)
    platform_commission := (order_amount * 15 / 100);
    RAISE NOTICE 'Komisyon tipi belirsiz, default 15 yuzde uygulandı: %', platform_commission;
  END IF;
  
  -- Merchant kazancı (sipariş tutarı - komisyon)
  merchant_earning := order_amount - platform_commission;
  
  -- Kurye kazancı (teslimat ücreti)
  courier_earning := delivery_fee;
  
  RAISE NOTICE 'Hesaplama tamamlandı: Siparis=%, Komisyon=%, Merchant=%, Kurye=%', 
    order_amount, platform_commission, merchant_earning, courier_earning;
  
  -- Merchant'a ödeme kaydı
  INSERT INTO payment_transactions (
    user_id,
    order_id,
    type,
    amount,
    status,
    description,
    created_at
  ) VALUES (
    merchant_id,
    NEW.id,
    'orderPayment',
    merchant_earning,
    'completed',
    'Sipariş ödemesi (Komisyon: ' || 
      CASE 
        WHEN order_commission_type = 'percentage' THEN '%' || order_commission_value
        WHEN order_commission_type = 'perOrder' THEN order_commission_value || '₺/sipariş'
        ELSE '%15 (default)'
      END || ')',
    NOW()
  );
  
  -- Kurye'ye ödeme kaydı
  IF courier_id IS NOT NULL THEN
    INSERT INTO payment_transactions (
      user_id,
      order_id,
      type,
      amount,
      status,
      description,
      created_at
    ) VALUES (
      courier_id,
      NEW.id,
      'deliveryFee',
      courier_earning,
      'completed',
      'Teslimat ücreti',
      NOW()
    );
    
    -- Kurye wallet güncelle
    UPDATE courier_wallets
    SET 
      balance = balance + courier_earning,
      updated_at = NOW()
    WHERE user_id = courier_id;
    
    IF NOT FOUND THEN
      INSERT INTO courier_wallets (user_id, balance, created_at, updated_at)
      VALUES (courier_id, courier_earning, NOW(), NOW());
    END IF;
  END IF;
  
  -- Merchant wallet güncelle
  UPDATE merchant_wallets
  SET 
    balance = balance + merchant_earning,
    updated_at = NOW()
  WHERE user_id = merchant_id;
  
  IF NOT FOUND THEN
    INSERT INTO merchant_wallets (user_id, balance, created_at, updated_at)
    VALUES (merchant_id, merchant_earning, NOW(), NOW());
  END IF;
  
  RAISE NOTICE 'Odeme islemi tamamlandi: Order ID=%', NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı yeniden oluştur
DROP TRIGGER IF EXISTS trigger_process_payment_on_delivery ON orders;

CREATE TRIGGER trigger_process_payment_on_delivery
AFTER UPDATE OF status ON orders
FOR EACH ROW
WHEN (NEW.status = 'DELIVERED' AND OLD.status <> 'DELIVERED')
EXECUTE FUNCTION process_order_payment_on_delivery();

-- Test sorgusu
SELECT 
  o.id as order_id,
  o.total_amount,
  o.commission_type,
  o.commission_value,
  CASE 
    WHEN o.commission_type = 'percentage' 
    THEN (o.total_amount * o.commission_value / 100)::numeric(10,2)
    WHEN o.commission_type = 'perOrder'
    THEN o.commission_value
    ELSE (o.total_amount * 15 / 100)::numeric(10,2)
  END as hesaplanan_komisyon,
  CASE 
    WHEN o.commission_type = 'percentage' 
    THEN (o.total_amount - (o.total_amount * o.commission_value / 100))::numeric(10,2)
    WHEN o.commission_type = 'perOrder'
    THEN (o.total_amount - o.commission_value)::numeric(10,2)
    ELSE (o.total_amount - (o.total_amount * 15 / 100))::numeric(10,2)
  END as merchant_kazanci,
  o.status,
  TO_CHAR(o.created_at, 'DD.MM.YYYY HH24:MI') as siparis_tarihi
FROM orders o
ORDER BY o.created_at DESC
LIMIT 10;
