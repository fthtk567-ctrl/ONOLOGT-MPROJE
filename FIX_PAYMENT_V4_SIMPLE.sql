-- ===================================================================
-- ÖDEME SİSTEMİ DÜZELTMESİ V4 - TÜM EKSİK KOLONLARI EKLE
-- ===================================================================
-- SORUN: Tabloda sadece 7 kolon var, 4 kolon eksik!
-- ===================================================================

-- 1. TÜM EKSİK KOLONLARI EKLE
-- ===================================================================

-- pending_balance ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'merchant_wallets' AND column_name = 'pending_balance'
  ) THEN
    ALTER TABLE merchant_wallets 
    ADD COLUMN pending_balance DECIMAL(10, 2) DEFAULT 0 CHECK (pending_balance >= 0);
    RAISE NOTICE '✅ pending_balance eklendi';
  END IF;
END $$;

-- frozen_balance ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'merchant_wallets' AND column_name = 'frozen_balance'
  ) THEN
    ALTER TABLE merchant_wallets 
    ADD COLUMN frozen_balance DECIMAL(10, 2) DEFAULT 0 CHECK (frozen_balance >= 0);
    RAISE NOTICE '✅ frozen_balance eklendi';
  END IF;
END $$;

-- total_commissions ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'merchant_wallets' AND column_name = 'total_commissions'
  ) THEN
    ALTER TABLE merchant_wallets 
    ADD COLUMN total_commissions DECIMAL(10, 2) DEFAULT 0;
    RAISE NOTICE '✅ total_commissions eklendi';
  END IF;
END $$;

-- last_payment_date ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'merchant_wallets' AND column_name = 'last_payment_date'
  ) THEN
    ALTER TABLE merchant_wallets 
    ADD COLUMN last_payment_date TIMESTAMPTZ;
    RAISE NOTICE '✅ last_payment_date eklendi';
  END IF;
END $$;

-- 2. KOLON AÇIKLAMALARI
-- ===================================================================
COMMENT ON COLUMN merchant_wallets.balance IS 'Merchant bize BORÇLU (pozitif = borç)';
COMMENT ON COLUMN merchant_wallets.pending_balance IS 'Bu hafta birikmiş borç';
COMMENT ON COLUMN merchant_wallets.frozen_balance IS 'Dondurulmuş borç';
COMMENT ON COLUMN merchant_wallets.total_earnings IS 'Toplam satış';
COMMENT ON COLUMN merchant_wallets.total_commissions IS 'Toplam komisyon';
COMMENT ON COLUMN merchant_wallets.total_withdrawals IS 'Merchant ödediği';
COMMENT ON COLUMN merchant_wallets.last_payment_date IS 'Son ödeme';

-- 3. WALLET GÜNCELLEME FONKSİYONU
-- ===================================================================
CREATE OR REPLACE FUNCTION update_merchant_wallet_after_payment(
  p_merchant_id UUID,
  p_order_amount DECIMAL,
  p_commission_amount DECIMAL,
  p_transaction_id UUID
)
RETURNS VOID AS $$
BEGIN
  -- Wallet yoksa oluştur (tüm kolonları kullan)
  INSERT INTO merchant_wallets (
    merchant_id, 
    balance,
    pending_balance,
    frozen_balance, 
    total_earnings,
    total_commissions,
    total_withdrawals
  )
  VALUES (p_merchant_id, 0, 0, 0, 0, 0, 0)
  ON CONFLICT (merchant_id) DO NOTHING;
  
  -- Wallet güncelle
  UPDATE merchant_wallets
  SET 
    balance = balance + p_commission_amount,
    pending_balance = pending_balance + p_commission_amount,
    total_earnings = total_earnings + p_order_amount,
    total_commissions = total_commissions + p_commission_amount,
    updated_at = NOW()
  WHERE merchant_id = p_merchant_id;
  
  RAISE NOTICE '💰 Merchant borcu: +% TL', p_commission_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. MERCHANT ÖDEME FONKSİYONU
-- ===================================================================
CREATE OR REPLACE FUNCTION process_merchant_payment(
  p_merchant_id UUID,
  p_amount DECIMAL,
  p_payment_method TEXT DEFAULT 'bank_transfer',
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_transaction_id UUID;
  v_current_debt DECIMAL;
BEGIN
  SELECT pending_balance INTO v_current_debt
  FROM merchant_wallets
  WHERE merchant_id = p_merchant_id;
  
  IF v_current_debt IS NULL THEN
    RAISE EXCEPTION 'Wallet bulunamadı';
  END IF;
  
  IF p_amount > v_current_debt THEN
    RAISE EXCEPTION 'Ödeme (%) > Borç (%)', p_amount, v_current_debt;
  END IF;
  
  -- Transaction kaydet
  INSERT INTO payment_transactions (
    merchant_id, amount, original_amount, commission_amount, vat_amount,
    currency, payment_method, status, type,
    created_at, processed_at, settled_at,
    gateway_reference, gateway_provider, description, metadata
  ) VALUES (
    p_merchant_id, p_amount, p_amount, 0, 0,
    'TRY', p_payment_method, 'completed', 'merchantPayment',
    NOW(), NOW(), NOW(),
    'MERCHANT_PAY_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    'MANUAL',
    'Komisyon ödemesi' || COALESCE(' - ' || p_notes, ''),
    jsonb_build_object('payment_type', 'debt_payment', 'notes', p_notes)
  ) RETURNING id INTO v_transaction_id;
  
  -- Wallet güncelle
  UPDATE merchant_wallets
  SET 
    balance = balance - p_amount,
    pending_balance = pending_balance - p_amount,
    total_withdrawals = total_withdrawals + p_amount,
    last_payment_date = NOW(),
    updated_at = NOW()
  WHERE merchant_id = p_merchant_id;
  
  RAISE NOTICE '✅ % TL alındı', p_amount;
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. HAFTALIK SIFIRLAMA
-- ===================================================================
CREATE OR REPLACE FUNCTION reset_weekly_pending_debts()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE merchant_wallets
  SET pending_balance = 0, last_payment_date = NOW()
  WHERE pending_balance > 0;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE '✅ % merchant sıfırlandı', v_count;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. VİEW
-- ===================================================================
CREATE OR REPLACE VIEW merchants_with_debt AS
SELECT 
  u.id as merchant_id,
  u.business_name,
  u.owner_name,
  u.email,
  mw.balance as total_debt,
  mw.pending_balance as this_week_debt,
  mw.total_earnings,
  mw.total_commissions,
  mw.total_withdrawals as total_payments,
  mw.last_payment_date
FROM users u
INNER JOIN merchant_wallets mw ON u.id = mw.merchant_id
WHERE u.role = 'merchant'
ORDER BY mw.pending_balance DESC;

-- 7. RLS
-- ===================================================================
DROP POLICY IF EXISTS "Merchants can view own wallet" ON merchant_wallets;
CREATE POLICY "Merchants can view own wallet" ON merchant_wallets
  FOR SELECT USING (auth.uid() = merchant_id);

DROP POLICY IF EXISTS "Admin can view all wallets" ON merchant_wallets;
CREATE POLICY "Admin can view all wallets" ON merchant_wallets
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

-- 8. TEST
-- ===================================================================
SELECT 
  u.business_name,
  mw.balance as "Borç",
  mw.pending_balance as "Bu Hafta",
  mw.total_withdrawals as "Ödedi"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
LIMIT 5;

-- BAŞARILI! 🎉
-- ✅ 4 kolon eklendi: pending_balance, frozen_balance, total_commissions, last_payment_date
-- ✅ Fonksiyonlar hazır
-- ✅ VIEW ve policy tamam
