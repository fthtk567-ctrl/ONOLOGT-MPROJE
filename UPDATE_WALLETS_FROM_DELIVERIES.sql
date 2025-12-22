-- ===================================================================
-- MEVCUT WALLET'LARI DELIVERY_REQUESTS'TEN GÜNCELLE
-- ===================================================================
-- payment_transactions yerine delivery_requests kullan
-- ===================================================================

-- 1. HER MERCHANT İÇİN TESLİM EDİLMİŞ SİPARİŞLERDEN KOMİSYON HESAPLA
-- ===================================================================
UPDATE merchant_wallets mw
SET 
  -- Toplam komisyon (commission_value * teslim edilen sipariş sayısı)
  total_commissions = COALESCE((
    SELECT SUM(
      CASE 
        WHEN dr.commission_type = 'percentage' 
        THEN (dr.declared_amount * dr.commission_value / 100)
        WHEN dr.commission_type = 'perOrder'
        THEN dr.commission_value
        ELSE 0
      END
    )
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id
      AND dr.status = 'DELIVERED'
  ), 0),
  
  -- Toplam satış tutarı (tüm teslim edilen siparişlerin tutarı)
  total_earnings = COALESCE((
    SELECT SUM(dr.declared_amount)
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id
      AND dr.status = 'DELIVERED'
  ), 0),
  
  -- Şimdilik ödeme yok (total_withdrawals = 0)
  total_withdrawals = 0;

-- 2. TOPLAM BORCU HESAPLA
-- ===================================================================
UPDATE merchant_wallets
SET 
  balance = total_commissions,
  pending_balance = total_commissions;

-- 3. KONTROL
-- ===================================================================
SELECT 
  COUNT(*) as "Güncellenen Merchant",
  SUM(total_commissions) as "Toplam Komisyon",
  SUM(total_earnings) as "Toplam Satış",
  SUM(balance) as "Toplam Borç"
FROM merchant_wallets
WHERE total_commissions > 0;

-- 4. DETAY
-- ===================================================================
SELECT 
  u.business_name as "İşletme",
  mw.total_earnings as "Satış",
  mw.total_commissions as "Komisyon",
  mw.balance as "Borç"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
WHERE mw.balance > 0
ORDER BY mw.balance DESC;

-- BAŞARILI! 🎉
