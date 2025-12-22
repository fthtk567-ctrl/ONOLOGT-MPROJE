-- ===================================================================
-- MERCHANT_WALLETS RLS POLİCY FİX
-- ===================================================================
-- SORUN: Trigger merchant_wallets'a INSERT yaparken RLS engelliyor!
-- ===================================================================

-- 1. merchant_wallets tablosuna TRIGGER için policy ekle
-- Trigger postgres rolü olarak çalıştığı için SERVICE ROLE policy gerekiyor

CREATE POLICY "Triggers can insert into merchant_wallets"
ON merchant_wallets
FOR INSERT
TO service_role
WITH CHECK (true);

-- 2. Alternatif: Mevcut trigger'ı SECURITY DEFINER yap
-- (Bu durumda trigger RLS'i atlar)

CREATE OR REPLACE FUNCTION update_merchant_wallet_on_delivery()
RETURNS TRIGGER 
SECURITY DEFINER  -- ← Bu satır RLS'i atlar!
SET search_path = public
AS $$
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

-- ✅ BAŞARILI!
-- Şimdi trigger RLS'i atlayarak çalışacak!
