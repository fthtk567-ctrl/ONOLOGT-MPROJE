-- MERCHANT_WALLETS TABLOSUNUN GERÇEK YAPISINI GÖR
SELECT 
    column_name, 
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'merchant_wallets'
ORDER BY ordinal_position;
