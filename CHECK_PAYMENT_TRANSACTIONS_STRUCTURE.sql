-- payment_transactions tablosunun yapısını kontrol et
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'payment_transactions'
ORDER BY ordinal_position;
