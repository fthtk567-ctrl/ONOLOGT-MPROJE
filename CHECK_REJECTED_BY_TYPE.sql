-- rejected_by kolonunun tipini kontrol et

SELECT 
  column_name,
  data_type,
  udt_name
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND column_name = 'rejected_by';

-- ONL2025110243 siparişinin rejected_by değerini kontrol et
SELECT 
  order_number,
  rejected_by,
  pg_typeof(rejected_by) as "Tip"
FROM delivery_requests
WHERE order_number = 'ONL2025110243';
