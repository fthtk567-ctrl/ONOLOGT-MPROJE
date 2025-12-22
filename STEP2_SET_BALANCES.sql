-- ===================================================================
-- ADIM 2: BORÇLARI BALANCE VE PENDING_BALANCE'A AKTAR
-- ===================================================================
-- ADIM 1 başarılıysa bunu çalıştır:

UPDATE merchant_wallets
SET 
  balance = total_commissions,
  pending_balance = total_commissions,
  updated_at = NOW();

-- BAŞARILI! ✅
-- Şimdi ADIM 3'ü aç ve çalıştır.
