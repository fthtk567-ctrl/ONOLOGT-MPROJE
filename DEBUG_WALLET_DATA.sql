-- ===================================================================
-- DEBUG: MERCHANT WALLET VERİLERİNİ KONTROL ET
-- ===================================================================

-- 1. Merchant wallet'lar var mı?
SELECT 
  mw.merchant_id,
  u.business_name,
  u.email,
  mw.balance,
  mw.pending_balance,
  mw.total_commissions,
  mw.total_earnings
FROM merchant_wallets mw
LEFT JOIN users u ON u.id = mw.merchant_id;

-- 2. Delivered siparişler var mı?
SELECT 
  COUNT(*) as "Delivered Sipariş Sayısı",
  SUM(CAST(merchant_payment_due AS NUMERIC)) as "Toplam Komisyon",
  merchant_id
FROM delivery_requests
WHERE status = 'delivered'
GROUP BY merchant_id;

-- 3. Son sipariş bilgileri
SELECT 
  id,
  merchant_id,
  declared_amount,
  merchant_payment_due,
  status,
  created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;
