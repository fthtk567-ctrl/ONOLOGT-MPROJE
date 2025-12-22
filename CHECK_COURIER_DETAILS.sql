-- KURYE DETAYLARINI KONTROL ET
-- Neden Fatih Teke'ye sipariş gidiyor?

SELECT 
  id,
  full_name,
  email,
  is_available AS online,
  status AS durum,
  is_active AS aktif,
  average_rating AS rating,
  total_ratings AS oy_sayisi,
  current_location AS konum,
  metadata->>'courier_type' AS tip,
  created_at AS kayit_tarihi,
  updated_at AS guncelleme
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- SON TESLİMAT HANGI KURYEYE GİTTİ?
SELECT 
  dr.id AS siparis_id,
  dr.courier_id,
  u.full_name AS kurye_adi,
  u.email AS kurye_email,
  u.is_available AS mesaide,
  u.average_rating AS rating,
  dr.declared_amount AS tutar,
  dr.status,
  dr.created_at AS siparis_zamani
FROM delivery_requests dr
LEFT JOIN users u ON u.id = dr.courier_id
ORDER BY dr.created_at DESC
LIMIT 5;
