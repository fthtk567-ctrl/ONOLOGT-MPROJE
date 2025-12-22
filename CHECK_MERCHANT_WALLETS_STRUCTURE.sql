-- Merchant_wallets tablosunun yapısını kontrol et
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'merchant_wallets'
ORDER BY ordinal_position;
