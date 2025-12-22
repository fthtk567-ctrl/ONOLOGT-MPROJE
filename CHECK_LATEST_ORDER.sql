-- Yeni sipariş durumunu kontrol et (order_number'ı değiştir)

SELECT 
  order_number as "Sipariş No",
  status as "Durum",
  courier_id as "Kurye ID",
  rejected_by as "Reddeden Kuryeler",
  rejection_count as "Red Sayısı",
  created_at as "Oluşturma",
  assigned_at as "Atama"
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 3;
