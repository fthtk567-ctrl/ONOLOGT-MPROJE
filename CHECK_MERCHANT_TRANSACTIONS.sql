-- TEST SANAYI TOPTAN merchant'ın payment_transactions kayıtlarını kontrol et
SELECT 
  id,
  type,
  amount,
  commission_amount,
  order_id,
  delivery_request_id,
  status,
  created_at
FROM payment_transactions
WHERE merchant_id = (
  SELECT id FROM users WHERE email = 'onlogprojects@gmail.com'
)
ORDER BY created_at DESC
LIMIT 10;

-- Merchant'ın wallet bilgileri
SELECT 
  merchant_id,
  balance,
  pending_balance,
  total_earnings,
  total_commissions,
  total_withdrawals,
  updated_at
FROM merchant_wallets
WHERE merchant_id = (
  SELECT id FROM users WHERE email = 'onlogprojects@gmail.com'
);
