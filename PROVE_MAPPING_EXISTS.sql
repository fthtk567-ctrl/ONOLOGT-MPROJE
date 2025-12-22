-- KANIT: Mapping zaten var!
SELECT 
  'KAYIT VAR!' as durum,
  yemek_app_restaurant_id,
  onlog_merchant_id,
  restaurant_name,
  is_active,
  created_at
FROM onlog_merchant_mapping
WHERE yemek_app_restaurant_id = '4445ceef-0706-4ba6-a6cf-d13c21171bfe';

-- Tablo yapısını kontrol et
SELECT 
  column_name, 
  data_type, 
  character_maximum_length
FROM information_schema.columns
WHERE table_name = 'onlog_merchant_mapping'
ORDER BY ordinal_position;
