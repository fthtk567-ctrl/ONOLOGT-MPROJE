-- update_merchant_wallet_on_delivery FONKSİYONUNU KONTROL ET

SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name LIKE '%wallet%'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;
