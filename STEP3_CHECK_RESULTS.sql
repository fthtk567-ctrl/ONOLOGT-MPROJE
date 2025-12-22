-- ===================================================================
-- ADIM 3: KONTROL VE DETAY
-- ===================================================================
-- Her şey tamam mı kontrol et:

-- Özet bilgi
SELECT 
  COUNT(*) as "Merchant Sayısı",
  SUM(total_commissions) as "Toplam Komisyon",
  SUM(total_earnings) as "Toplam Satış",
  AVG(total_commissions) as "Ortalama Borç"
FROM merchant_wallets
WHERE total_commissions > 0;

-- Detaylı liste
SELECT 
  u.business_name as "İşletme",
  mw.total_earnings as "Satış (₺)",
  mw.total_commissions as "Komisyon (₺)",
  mw.balance as "Borç (₺)",
  (
    SELECT COUNT(*)
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id AND dr.status = 'delivered'
  ) as "Teslimat"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
WHERE mw.balance > 0
ORDER BY mw.balance DESC;

-- TAMAM! 🎉
-- Merchant panel'i yenile (F5) ve "💰 Ödemeler" sekmesine bak!
