-- ===================================================================
-- MEVCUT WALLET'LARI GERİYE DÖNÜK GÜNCELLE
-- ===================================================================
-- Geçmiş tüm payment_transactions'ları tarayıp borçları hesapla
-- ===================================================================

-- 1. MEVCUT TÜM MERCHANT'LARIN BORÇLARINI HESAPLA
-- ===================================================================
UPDATE merchant_wallets mw
SET 
  -- Toplam komisyon (tüm orderPayment transaction'lardan)
  total_commissions = COALESCE((
    SELECT SUM(commission_amount)
    FROM payment_transactions
    WHERE merchant_id = mw.merchant_id
      AND type = 'orderPayment'
      AND status IN ('completed', 'pending')
  ), 0),
  
  -- Toplam satış tutarı (tüm orderPayment transaction'lardan)
  total_earnings = COALESCE((
    SELECT SUM(original_amount)
    FROM payment_transactions
    WHERE merchant_id = mw.merchant_id
      AND type = 'orderPayment'
      AND status IN ('completed', 'pending')
  ), 0),
  
  -- Merchant'ın ödediği (merchantPayment transaction'lar)
  total_withdrawals = COALESCE((
    SELECT SUM(amount)
    FROM payment_transactions
    WHERE merchant_id = mw.merchant_id
      AND type = 'merchantPayment'
      AND status = 'completed'
  ), 0);

-- 2. TOPLAM BORCU HESAPLA (total_commissions - total_withdrawals)
-- ===================================================================
UPDATE merchant_wallets
SET 
  balance = total_commissions - total_withdrawals,
  pending_balance = total_commissions - total_withdrawals; -- İlk seferde hepsi pending

-- 3. KONTROL: Kaç merchant güncellendi?
-- ===================================================================
SELECT 
  COUNT(*) as "Güncellenen Merchant",
  SUM(total_commissions) as "Toplam Komisyon",
  SUM(total_withdrawals) as "Toplam Ödenen",
  SUM(balance) as "Toplam Borç"
FROM merchant_wallets;

-- 4. DETAYLI GÖRÜNÜM: Her merchant'ın durumu
-- ===================================================================
SELECT 
  u.business_name as "İşletme",
  mw.total_earnings as "Toplam Satış",
  mw.total_commissions as "Toplam Komisyon",
  mw.total_withdrawals as "Ödediği",
  mw.balance as "Borç",
  mw.pending_balance as "Bekleyen Borç"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
WHERE mw.balance > 0
ORDER BY mw.balance DESC;

-- ===================================================================
-- BAŞARILI! 🎉
-- ===================================================================
-- ✅ Tüm geçmiş işlemler hesaplandı
-- ✅ Borçlar güncellendi
-- ✅ pending_balance dolduruldu
