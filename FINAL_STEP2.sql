-- ===================================================================
-- STEP 2: BALANCE'LARI GÜNCELLE
-- ===================================================================

UPDATE merchant_wallets
SET 
  balance = total_commissions,
  pending_balance = total_commissions,
  updated_at = NOW();

-- SUCCESS! ✅
