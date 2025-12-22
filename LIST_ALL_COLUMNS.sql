-- ===================================================================
-- DELIVERY_REQUESTS KOLONLARINI TAM LİSTE
-- ===================================================================

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'delivery_requests'
ORDER BY ordinal_position;
