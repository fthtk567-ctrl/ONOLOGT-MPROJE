-- ===================================================================
-- OTOMATİK WALLET GÜNCELLEMESİ - TRIGGER
-- ===================================================================
-- Her delivery_requests 'delivered' olduğunda otomatik wallet'ı güncelle!
-- ===================================================================

-- 1. Trigger fonksiyonu oluştur
CREATE OR REPLACE FUNCTION update_merchant_wallet_on_delivery()
RETURNS TRIGGER AS $$
BEGIN
  -- Eğer status 'delivered' olarak değiştiyse
  IF NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered') THEN
    
    -- Merchant için wallet var mı kontrol et, yoksa oluştur
    INSERT INTO merchant_wallets (
      merchant_id,
      balance,
      pending_balance,
      total_commissions,
      total_earnings,
      total_withdrawals,
      frozen_balance,
      created_at,
      updated_at
    )
    VALUES (
      NEW.merchant_id,
      0,
      0,
      0,
      0,
      0,
      0,
      NOW(),
      NOW()
    )
    ON CONFLICT (merchant_id) DO NOTHING;
    
    -- Wallet'ı güncelle
    UPDATE merchant_wallets
    SET 
      total_commissions = total_commissions + CAST(NEW.merchant_payment_due AS NUMERIC),
      total_earnings = total_earnings + CAST(NEW.declared_amount AS NUMERIC),
      balance = balance + CAST(NEW.merchant_payment_due AS NUMERIC),
      pending_balance = pending_balance + CAST(NEW.merchant_payment_due AS NUMERIC),
      updated_at = NOW()
    WHERE merchant_id = NEW.merchant_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger oluştur
DROP TRIGGER IF EXISTS trigger_update_wallet_on_delivery ON delivery_requests;

CREATE TRIGGER trigger_update_wallet_on_delivery
  AFTER INSERT OR UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_merchant_wallet_on_delivery();

-- 3. Test - Trigger çalışıyor mu?
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_update_wallet_on_delivery';

-- BAŞARILI! 🎉
-- Artık her 'delivered' teslimat otomatik olarak wallet'ı güncelleyecek!
