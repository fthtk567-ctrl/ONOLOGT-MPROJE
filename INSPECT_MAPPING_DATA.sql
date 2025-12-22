-- Inspect mapping rows with byte details
SELECT 
  yemek_app_restaurant_id,
  length(yemek_app_restaurant_id) as char_length,
  encode(yemek_app_restaurant_id::bytea, 'hex') as hex_value,
  onlog_merchant_id,
  restaurant_name,
  is_active
FROM onlog_merchant_mapping
ORDER BY created_at DESC;
