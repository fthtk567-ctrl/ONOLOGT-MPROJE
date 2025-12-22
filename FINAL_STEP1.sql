-- ===================================================================
-- STEP 1: WALLET'LARI GÜNCELLE (ÇALIŞAN VERSIYON)
-- ===================================================================

UPDATE merchant_wallets mw
SET 
  total_commissions = COALESCE((
    SELECT SUM(CAST(merchant_payment_due AS NUMERIC))
    FROM delivery_requests
    WHERE merchant_id = mw.merchant_id
      AND status = 'delivered'
  ), 0),
  
  total_earnings = COALESCE((
    SELECT SUM(CAST(declared_amount AS NUMERIC))
    FROM delivery_requests
    WHERE merchant_id = mw.merchant_id
      AND status = 'delivered'
  ), 0),
  
  total_withdrawals = 0,
  updated_at = NOW();

-- SUCCESS! ✅
