-- ===================================================================
-- ÖDEME SİSTEMİ DÜZELTMESİ V3 - EKSİK KOLONLARI EKLE
-- ===================================================================
-- Önce eksik kolonları ekle, sonra fonksiyonları güncelle
-- ===================================================================

-- 1. EKSİK KOLONLARI EKLE
-- ===================================================================
-- pending_balance kolonu YOKSA ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'merchant_wallets' 
    AND column_name = 'pending_balance'
  ) THEN
    ALTER TABLE merchant_wallets 
    ADD COLUMN pending_balance DECIMAL(10, 2) DEFAULT 0 CHECK (pending_balance >= 0);
    
    RAISE NOTICE '✅ pending_balance kolonu eklendi';
  ELSE
    RAISE NOTICE 'ℹ️  pending_balance kolonu zaten var';
  END IF;
END $$;

-- last_payment_date kolonu YOKSA ekle
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'merchant_wallets' 
    AND column_name = 'last_payment_date'
  ) THEN
    ALTER TABLE merchant_wallets 
    ADD COLUMN last_payment_date TIMESTAMPTZ;
    
    RAISE NOTICE '✅ last_payment_date kolonu eklendi';
  ELSE
    RAISE NOTICE 'ℹ️  last_payment_date kolonu zaten var';
  END IF;
END $$;

-- 2. KOLON AÇIKLAMALARI
-- ===================================================================
COMMENT ON COLUMN merchant_wallets.balance IS 'Merchant''ın platforma toplam borcu (komisyonlar) - POZİTİF DEĞER = BORÇLU';
COMMENT ON COLUMN merchant_wallets.pending_balance IS 'Bu dönemde biriken, henüz ödenmemiş komisyon borcu';
COMMENT ON COLUMN merchant_wallets.frozen_balance IS 'Dondurulmuş borç (anlaşmazlık durumunda)';
COMMENT ON COLUMN merchant_wallets.total_earnings IS 'Merchant''ın toplam satış tutarı';
COMMENT ON COLUMN merchant_wallets.total_commissions IS 'Toplam kesilen komisyon';
COMMENT ON COLUMN merchant_wallets.total_withdrawals IS 'Merchant''ın platforma yaptığı toplam ödemeler';
COMMENT ON COLUMN merchant_wallets.last_payment_date IS 'Son ödeme tarihi';

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
  -- Wallet yoksa oluştur
  INSERT INTO merchant_wallets (
    merchant_id, 
    balance,               -- Toplam borç (pozitif = borçlu)
    pending_balance,       -- Bu hafta birikmiş borç
    frozen_balance, 
    total_earnings,        -- Toplam satış
    total_commissions,     -- Toplam komisyon
    total_withdrawals      -- Ödediği toplam
  )
  VALUES (p_merchant_id, 0, 0, 0, 0, 0, 0)
  ON CONFLICT (merchant_id) DO NOTHING;
  
  -- Wallet'ı güncelle
  UPDATE merchant_wallets
  SET 
    -- Borç artır (komisyon kadar)
    balance = balance + p_commission_amount,
    pending_balance = pending_balance + p_commission_amount,
    
    -- İstatistikleri güncelle
    total_earnings = total_earnings + p_order_amount,
    total_commissions = total_commissions + p_commission_amount,
    
    last_updated = NOW()
  WHERE merchant_id = p_merchant_id;
  
  RAISE NOTICE '💰 Merchant borcu güncellendi: +% TL komisyon', p_commission_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. MERCHANT ÖDEME KAYDI FONKSİYONU
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
  -- Mevcut borcu kontrol et
  SELECT pending_balance INTO v_current_debt
  FROM merchant_wallets
  WHERE merchant_id = p_merchant_id;
  
  IF v_current_debt IS NULL THEN
    RAISE EXCEPTION 'Merchant wallet bulunamadı';
  END IF;
  
  IF p_amount > v_current_debt THEN
    RAISE EXCEPTION 'Ödeme tutarı (%) mevcut borçtan (%) fazla olamaz', p_amount, v_current_debt;
  END IF;
  
  -- Payment transaction oluştur
  INSERT INTO payment_transactions (
    merchant_id,
    amount,
    original_amount,
    commission_amount,
    vat_amount,
    currency,
    payment_method,
    status,
    type,
    created_at,
    processed_at,
    settled_at,
    gateway_reference,
    gateway_provider,
    description,
    metadata
  ) VALUES (
    p_merchant_id,
    p_amount,
    p_amount,
    0,
    0,
    'TRY',
    p_payment_method,
    'completed',
    'merchantPayment',
    NOW(),
    NOW(),
    NOW(),
    'MERCHANT_PAY_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    'MANUAL',
    'Merchant komisyon ödemesi' || COALESCE(' - ' || p_notes, ''),
    jsonb_build_object(
      'payment_type', 'debt_payment',
      'notes', p_notes
    )
  ) RETURNING id INTO v_transaction_id;
  
  -- Merchant wallet'ı güncelle
  UPDATE merchant_wallets
  SET 
    balance = balance - p_amount,
    pending_balance = pending_balance - p_amount,
    total_withdrawals = total_withdrawals + p_amount,
    last_payment_date = NOW(),
    last_updated = NOW()
  WHERE merchant_id = p_merchant_id;
  
  RAISE NOTICE '✅ Merchant ödemesi işlendi: % TL alındı', p_amount;
  
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. HAFTALIK ÖDEME DÖNGÜSÜ SIFIRLAMA
-- ===================================================================
CREATE OR REPLACE FUNCTION reset_weekly_pending_debts()
RETURNS INTEGER AS $$
DECLARE
  v_affected_count INTEGER;
BEGIN
  UPDATE merchant_wallets
  SET 
    pending_balance = 0,
    last_payment_date = NOW()
  WHERE pending_balance > 0;
  
  GET DIAGNOSTICS v_affected_count = ROW_COUNT;
  
  RAISE NOTICE '✅ % merchant için haftalık borç sıfırlandı', v_affected_count;
  
  RETURN v_affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. VİEW: BORÇLU MERCHANTLAR
-- ===================================================================
CREATE OR REPLACE VIEW merchants_with_debt AS
SELECT 
  u.id as merchant_id,
  u.business_name,
  u.owner_name,
  u.email,
  u.phone,
  mw.balance as total_debt,
  mw.pending_balance as this_week_debt,
  mw.total_earnings,
  mw.total_commissions,
  mw.total_withdrawals as total_payments,
  mw.last_payment_date,
  (mw.total_commissions - mw.total_withdrawals) as unpaid_commission
FROM users u
INNER JOIN merchant_wallets mw ON u.id = mw.merchant_id
WHERE u.role = 'merchant'
ORDER BY mw.pending_balance DESC;

-- 7. RLS POLİCY
-- ===================================================================
DROP POLICY IF EXISTS "Merchants can view own wallet" ON merchant_wallets;
CREATE POLICY "Merchants can view own wallet" ON merchant_wallets
  FOR SELECT
  USING (auth.uid() = merchant_id);

DROP POLICY IF EXISTS "Admin can view all wallets" ON merchant_wallets;
CREATE POLICY "Admin can view all wallets" ON merchant_wallets
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 8. TEST
-- ===================================================================
SELECT 
  u.business_name,
  mw.balance as "Toplam Borç",
  mw.pending_balance as "Bu Hafta Borç",
  mw.total_withdrawals as "Toplam Ödediği"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
LIMIT 5;

-- ===================================================================
-- BAŞARILI! 🎉
-- ===================================================================
-- ✅ pending_balance kolonu eklendi
-- ✅ last_payment_date kolonu eklendi
-- ✅ Fonksiyonlar güncellendi
-- ✅ VIEW oluşturuldu
-- ✅ RLS policy güncellendi
