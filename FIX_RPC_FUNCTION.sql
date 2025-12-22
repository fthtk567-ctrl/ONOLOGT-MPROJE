-- RPC fonksiyonunu düzelt - JSONB yerine TABLE döndürsün
DROP FUNCTION IF EXISTS find_merchant_mapping(TEXT);

CREATE OR REPLACE FUNCTION find_merchant_mapping(search_id TEXT)
RETURNS TABLE (
  onlog_merchant_id UUID,
  restaurant_name VARCHAR(255)
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.onlog_merchant_id,
    m.restaurant_name
  FROM public.onlog_merchant_mapping m
  WHERE m.yemek_app_restaurant_id = search_id
    AND m.is_active = true
  LIMIT 1;
END;
$$;

-- RPC fonksiyonuna herkese execute izni ver (SERVICE_ROLE_KEY için gerekli)
GRANT EXECUTE ON FUNCTION find_merchant_mapping(TEXT) TO anon, authenticated, service_role;

-- Test et
SELECT * FROM find_merchant_mapping('4445ceef-0706-4ba6-a6cf-d13c21171bfe');
