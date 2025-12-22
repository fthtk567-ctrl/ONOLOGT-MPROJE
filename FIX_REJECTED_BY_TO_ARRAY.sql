-- rejected_by değerlerini düzelt - string'den array'e çevir

UPDATE delivery_requests
SET rejected_by = jsonb_build_array(rejected_by)
WHERE order_number IN ('ONL2025110243', 'ONL2025110242')
  AND jsonb_typeof(rejected_by) != 'array';

SELECT 
  order_number,
  rejected_by,
  jsonb_typeof(rejected_by) as "Tip"
FROM delivery_requests
WHERE order_number IN ('ONL2025110243', 'ONL2025110242');
