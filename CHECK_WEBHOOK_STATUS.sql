-- Son Yemek App siparişini ve webhook durumunu kontrol et
SELECT 
  id,
  external_order_id as "Sipariş No",
  status as "Durum",
  courier_id as "Kurye ID",
  rejection_count as "Red Sayısı",
  created_at as "Oluşturulma",
  updated_at as "Son Güncelleme",
  (SELECT owner_name FROM users WHERE id = delivery_requests.courier_id) as "Kurye Adı"
FROM delivery_requests
WHERE source = 'yemek_app'
  AND external_order_id = 'YO-418592'
ORDER BY created_at DESC;

-- Webhook trigger'ının çalışıp çalışmadığını kontrol et
-- Supabase Dashboard → Database Logs'da şunu ara: "[Webhook]"
