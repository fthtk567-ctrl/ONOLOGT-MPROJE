-- ===================================================================
-- TÜM MERCHANTLAR İÇİN WALLET OLUŞTUR VE GÜNCELLE
-- ===================================================================

-- 1. Önce kaç merchant var ve hangilerinin wallet'ı yok kontrol et
SELECT 
  u.id,
  u.business_name,
  u.email,
  CASE WHEN mw.merchant_id IS NULL THEN '❌ YOK' ELSE '✅ VAR' END as wallet_durumu
FROM users u
LEFT JOIN merchant_wallets mw ON mw.merchant_id = u.id
WHERE u.role = 'merchant';

-- 2. Wallet'ı olmayan tüm merchantlar için kayıt oluştur
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
SELECT 
  u.id,
  0,
  0,
  0,
  0,
  0,
  0,
  NOW(),
  NOW()
FROM users u
WHERE u.role = 'merchant'
  AND NOT EXISTS (
    SELECT 1 FROM merchant_wallets mw WHERE mw.merchant_id = u.id
  )
ON CONFLICT (merchant_id) DO NOTHING;

-- 3. TÜM merchantlar için komisyon hesapla ve güncelle
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
  
  total_withdrawals = 0,
  updated_at = NOW();

-- 4. Sonuç - TÜM merchantlar ve borçları
SELECT 
  u.business_name as "İşletme",
  u.email as "Email",
  mw.balance as "Borç",
  mw.pending_balance as "Bu Hafta",
  mw.total_commissions as "Toplam Komisyon",
  mw.total_earnings as "Toplam Satış",
  (
    SELECT COUNT(*)
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id AND dr.status = 'delivered'
  ) as "Teslimat"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
ORDER BY mw.balance DESC;

-- BAŞARILI! 🎉
-- Tüm merchantların wallet'ları oluşturuldu ve güncellendi!
