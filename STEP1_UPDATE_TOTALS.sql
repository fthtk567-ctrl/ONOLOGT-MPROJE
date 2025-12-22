-- ===================================================================
-- ADIM 1: KOMİSYONLARI VE SATIŞLARI TOPLA
-- ===================================================================
-- İlk önce bunu çalıştır:

UPDATE merchant_wallets mw
SET 
  total_commissions = COALESCE((
    SELECT SUM(CAST(dr.merchant_payment_due AS DECIMAL(10,2)))
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id
      AND dr.status = 'delivered'
  ), 0),
  
  total_earnings = COALESCE((
    SELECT SUM(CAST(dr.declared_amount AS DECIMAL(10,2)))
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id
      AND dr.status = 'delivered'
  ), 0),
  
  total_withdrawals = 0,
  updated_at = NOW();

-- BAŞARILI! ✅
-- Şimdi ADIM 2'yi aç ve çalıştır.
