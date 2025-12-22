-- ===================================================================
-- ÖDEME SİSTEMİ DÜZELTMESİ - MERCHANT BORÇ SİSTEMİ
-- ===================================================================
-- Merchant bize BORÇLU olacak, biz ona para ödemeyeceğiz!
-- Her teslimatın komisyonu merchant'ın BORCUNA eklenecek
-- ===================================================================

-- 1. MERCHANT_WALLETS TABLOSUNU GÜNCELLE
-- ===================================================================
-- Yanlış kolonları değiştir:
-- balance → debt_balance (merchant'ın bize borcu)
-- pending_balance → pending_debt (bu hafta birikmiş borç)

ALTER TABLE merchant_wallets 
  RENAME COLUMN balance TO debt_balance;

ALTER TABLE merchant_wallets 
  RENAME COLUMN pending_balance TO pending_debt;

-- Açıklama kolonları ekle
COMMENT ON COLUMN merchant_wallets.debt_balance IS 'Merchant''ın platforma toplam borcu (komisyonlar)';
COMMENT ON COLUMN merchant_wallets.pending_debt IS 'Bu dönemde biriken, henüz ödenmemiş komisyon borcu';
COMMENT ON COLUMN merchant_wallets.frozen_balance IS 'Dondurulmuş borç (anlaşmazlık durumunda)';
COMMENT ON COLUMN merchant_wallets.total_earnings IS 'Merchant''ın toplam satış tutarı';
COMMENT ON COLUMN merchant_wallets.total_commissions IS 'Toplam kesilen komisyon';

-- total_withdrawals → total_payments (merchant bizE ödediği)
ALTER TABLE merchant_wallets 
  RENAME COLUMN total_withdrawals TO total_payments;

COMMENT ON COLUMN merchant_wallets.total_payments IS 'Merchant''ın platforma yaptığı toplam ödemeler';

-- ===================================================================
-- 2. WALLET GÜNCELLEME FONKSİYONUNU DÜZELT
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
    debt_balance,      -- Toplam borç
    pending_debt,      -- Bu hafta birikmiş borç
    frozen_balance, 
    total_earnings,    -- Toplam satış
    total_commissions, -- Toplam komisyon
    total_payments     -- Ödediği toplam
  )
  VALUES (p_merchant_id, 0, 0, 0, 0, 0, 0)
  ON CONFLICT (merchant_id) DO NOTHING;
  
  -- Wallet'ı güncelle
  UPDATE merchant_wallets
  SET 
    -- Borç artır (komisyon kadar)
    debt_balance = debt_balance + p_commission_amount,
    pending_debt = pending_debt + p_commission_amount,
    
    -- İstatistikleri güncelle
    total_earnings = total_earnings + p_order_amount,
    total_commissions = total_commissions + p_commission_amount,
    
    last_updated = NOW()
  WHERE merchant_id = p_merchant_id;
  
  RAISE NOTICE '💰 Merchant borcu güncellendi: +% TL komisyon', p_commission_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- 3. PAYMENT_TRANSACTIONS TABLOSUNA AÇIKLAMA
-- ===================================================================
COMMENT ON COLUMN payment_transactions.amount IS 'İşlem tutarı (komisyon için pozitif değer)';
COMMENT ON COLUMN payment_transactions.type IS 'orderPayment: merchant satış, merchantPayment: merchant bize ödeme yaptı';

-- Yeni transaction type ekle
DO $$
BEGIN
  -- merchantPayment type'ı ekle (merchant bize ödeme yaptığında)
  -- Eğer type enum ise, bunu ALTER TYPE ile eklemen gerekir
  -- Şimdilik string olarak varsayıyoruz
END $$;

-- ===================================================================
-- 4. MERCHANT ÖDEME KAYDI FONKSİYONU
-- ===================================================================
-- Admin panel'den "Ödeme Alındı" işaretlendiğinde çalışacak
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
  SELECT pending_debt INTO v_current_debt
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
    'merchantPayment',  -- Yeni tip: Merchant bize ödeme yaptı
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
    debt_balance = debt_balance - p_amount,      -- Borç azalt
    pending_debt = pending_debt - p_amount,      -- Bekleyen borç azalt
    total_payments = total_payments + p_amount,  -- Toplam ödeme artır
    last_payment_date = NOW(),
    last_updated = NOW()
  WHERE merchant_id = p_merchant_id;
  
  RAISE NOTICE '✅ Merchant ödemesi işlendi: % TL alındı', p_amount;
  
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- 5. HAFTALIK ÖDEME DÖNGÜSÜ SIFIRLAMA
-- ===================================================================
-- Her hafta admin "Ödemeler Alındı" dediğinde pending_debt sıfırlanacak
CREATE OR REPLACE FUNCTION reset_weekly_pending_debts()
RETURNS INTEGER AS $$
DECLARE
  v_affected_count INTEGER;
BEGIN
  -- Tüm merchant'ların pending_debt'ini sıfırla
  -- (Admin panelden toplu ödeme işaretlemesi sonrası)
  UPDATE merchant_wallets
  SET 
    pending_debt = 0,
    last_payment_date = NOW()
  WHERE pending_debt > 0;
  
  GET DIAGNOSTICS v_affected_count = ROW_COUNT;
  
  RAISE NOTICE '✅ % merchant için haftalık borç sıfırlandı', v_affected_count;
  
  RETURN v_affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- 6. VİEW: BORÇLU MERCHANTLAR
-- ===================================================================
CREATE OR REPLACE VIEW merchants_with_debt AS
SELECT 
  u.id as merchant_id,
  u.business_name,
  u.owner_name,
  u.email,
  u.phone,
  mw.debt_balance as total_debt,
  mw.pending_debt as this_week_debt,
  mw.total_earnings,
  mw.total_commissions,
  mw.total_payments,
  mw.last_payment_date,
  (mw.total_commissions - mw.total_payments) as unpaid_commission
FROM users u
INNER JOIN merchant_wallets mw ON u.id = mw.merchant_id
WHERE u.role = 'merchant'
ORDER BY mw.pending_debt DESC;

-- ===================================================================
-- 7. RLS POLİCY GÜNCELLEMESİ
-- ===================================================================
-- Merchant kendi borcunu görebilir
DROP POLICY IF EXISTS "Merchants can view own wallet" ON merchant_wallets;
CREATE POLICY "Merchants can view own wallet" ON merchant_wallets
  FOR SELECT
  USING (auth.uid() = merchant_id);

-- Admin tüm borçları görebilir
DROP POLICY IF EXISTS "Admin can view all wallets" ON merchant_wallets;
CREATE POLICY "Admin can view all wallets" ON merchant_wallets
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===================================================================
-- 8. TEST VERİSİ KONTROL
-- ===================================================================
-- Mevcut merchant'ların durumunu göster
SELECT 
  u.business_name,
  mw.debt_balance as "Toplam Borç",
  mw.pending_debt as "Bu Hafta Borç",
  mw.total_payments as "Toplam Ödediği"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
LIMIT 5;

-- ===================================================================
-- NOTLAR:
-- ===================================================================
-- ✅ Artık merchant'a para ödemiyoruz, komisyon BORCU olarak kaydediyoruz
-- ✅ pending_debt: Bu hafta birikmiş, henüz ödenmemiş borç
-- ✅ debt_balance: Toplam borç (eski dönemlerde ödenmemiş varsa dahil)
-- ✅ Admin panel'den "Ödeme Alındı" işaretlenince process_merchant_payment() çağrılacak
