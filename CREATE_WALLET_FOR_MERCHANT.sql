-- ===================================================================
-- MERCHANT İÇİN WALLET KAYDI OLUŞTUR
-- ===================================================================

-- Önce kontrol et - merchant var mı?
SELECT id, business_name, email 
FROM users 
WHERE id = '4445ceef-0706-4ba6-a6cf-d13c21717bfe';

-- Wallet kaydı oluştur
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
  '4445ceef-0706-4ba6-a6cf-d13c21717bfe',
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

-- Şimdi UPDATE'i çalıştır
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
  
  balance = COALESCE((
    SELECT SUM(CAST(merchant_payment_due AS NUMERIC))
    FROM delivery_requests
    WHERE merchant_id = mw.merchant_id
      AND status = 'delivered'
  ), 0),
  
  pending_balance = COALESCE((
    SELECT SUM(CAST(merchant_payment_due AS NUMERIC))
    FROM delivery_requests
    WHERE merchant_id = mw.merchant_id
      AND status = 'delivered'
  ), 0),
  
  updated_at = NOW()
WHERE mw.merchant_id = '4445ceef-0706-4ba6-a6cf-d13c21717bfe';

-- Kontrol et
SELECT 
  merchant_id,
  balance,
  pending_balance,
  total_commissions,
  total_earnings
FROM merchant_wallets
WHERE merchant_id = '4445ceef-0706-4ba6-a6cf-d13c21717bfe';

-- SUCCESS! 🎉
