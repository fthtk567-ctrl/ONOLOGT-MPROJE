-- ===================================================================
-- STEP 3: SONUÇLARI KONTROL ET
-- ===================================================================

SELECT 
  COUNT(*) as "Merchant Sayısı",
  SUM(total_commissions)::NUMERIC(10,2) as "Toplam Komisyon (₺)",
  SUM(total_earnings)::NUMERIC(10,2) as "Toplam Satış (₺)",
  AVG(total_commissions)::NUMERIC(10,2) as "Ortalama Borç (₺)"
FROM merchant_wallets
WHERE total_commissions > 0;

-- Detaylı liste
SELECT 
  u.business_name as "İşletme",
  mw.total_earnings::NUMERIC(10,2) as "Satış",
  mw.total_commissions::NUMERIC(10,2) as "Komisyon",
  mw.balance::NUMERIC(10,2) as "Borç",
  (
    SELECT COUNT(*)
    FROM delivery_requests
    WHERE merchant_id = mw.merchant_id AND status = 'delivered'
  ) as "Teslimat"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
WHERE mw.balance > 0
ORDER BY mw.balance DESC;

-- TAMAM! 🎉
