-- ===================================================================
-- WALLET'LARI DELIVERY_REQUESTS'TEN GÜNCELLE (BASIT VERSIYON)
-- ===================================================================
-- merchant_payment_due direkt kullan!
-- ===================================================================

-- 1. HER MERCHANT İÇİN TESLİM EDİLMİŞ SİPARİŞLERDEN KOMİSYON TOPLA
-- ===================================================================
UPDATE merchant_wallets mw
SET 
  -- Toplam komisyon (merchant_payment_due kolonundan direkt topla)
  total_commissions = COALESCE((
    SELECT SUM(CAST(dr.merchant_payment_due AS DECIMAL(10,2)))
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id
      AND dr.status = 'delivered'
  ), 0),
  
  -- Toplam satış tutarı (declared_amount toplamı)
  total_earnings = COALESCE((
    SELECT SUM(CAST(dr.declared_amount AS DECIMAL(10,2)))
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id
      AND dr.status = 'delivered'
  ), 0),
  
  -- Şimdilik ödeme yok
  total_withdrawals = 0,
  
  -- Güncelleme zamanı
  updated_at = NOW();

-- 2. BORÇLARI BALANCE VE PENDING_BALANCE'A AKTAR
-- ===================================================================
UPDATE merchant_wallets
SET 
  balance = total_commissions,
  pending_balance = total_commissions,
  updated_at = NOW();

-- 3. KONTROL - KAÇ MERCHANT GÜNCELLENDİ?
-- ===================================================================
SELECT 
  COUNT(*) as "Güncellenen Merchant Sayısı",
  SUM(total_commissions) as "Toplam Komisyon Borcu",
  SUM(total_earnings) as "Toplam Satış",
  AVG(total_commissions) as "Ortalama Borç"
FROM merchant_wallets
WHERE total_commissions > 0;

-- 4. DETAYLI LİSTE - HANGİ MERCHANT'LAR NE KADAR BORÇLU?
-- ===================================================================
SELECT 
  u.business_name as "İşletme Adı",
  u.email as "E-posta",
  mw.total_earnings as "Toplam Satış (₺)",
  mw.total_commissions as "Komisyon Borcu (₺)",
  mw.balance as "Cari Borç (₺)",
  mw.pending_balance as "Bu Hafta Borç (₺)",
  (
    SELECT COUNT(*)
    FROM delivery_requests dr
    WHERE dr.merchant_id = mw.merchant_id AND dr.status = 'delivered'
  ) as "Teslimat Sayısı"
FROM merchant_wallets mw
JOIN users u ON u.id = mw.merchant_id
WHERE mw.balance > 0
ORDER BY mw.balance DESC;

-- BAŞARILI! 🎉
-- Şimdi merchant panel'i yenile (F5) ve "💰 Ödemeler" sekmesine bak!
