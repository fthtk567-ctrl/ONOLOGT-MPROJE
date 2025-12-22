-- ONL2025110243 ve ONL2025110242 siparişlerinin detaylı durumunu kontrol et

SELECT 
  order_number as "Sipariş No",
  status as "Durum",
  courier_id as "Kurye ID",
  rejected_by as "Reddeden Kuryeler",
  rejection_count as "Red Sayısı",
  created_at as "Oluşturma",
  assigned_at as "Atama",
  rejected_at as "Red Tarihi"
FROM delivery_requests
WHERE order_number IN ('ONL2025110243', 'ONL2025110242')
ORDER BY created_at DESC;

-- Aktif kuryeler
SELECT 
  id as "Kurye ID",
  full_name as "İsim",
  is_available as "Müsait mi?",
  status as "Durum",
  is_active as "Aktif mi?"
FROM users
WHERE role = 'courier'
  AND status = 'approved';
