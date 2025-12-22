-- İki teslimat isteğinin detaylı durumunu sorgula
-- Test order: ONL2025110247 (UUID: b2be4262-96a1-43c9-8de9-04603bf5485a)

SELECT 
    dr.id as "Teslimat ID",
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    dr.courier_id as "Atanan Kurye ID",
    courier.full_name as "Kurye Adı",
    courier.phone as "Kurye Tel",
    courier.is_active as "Kurye Aktif mi",
    dr.rejected_by as "Red Eden Kurye ID",
    rejected_courier.full_name as "Red Eden Kurye Adı",
    dr.created_at as "Oluşturulma",
    dr.updated_at as "Güncellenme"
FROM delivery_requests dr
LEFT JOIN users courier ON dr.courier_id = courier.id
LEFT JOIN users rejected_courier ON dr.rejected_by = rejected_courier.id
WHERE dr.order_number IN ('ONL2025110247', 'ONL2025110246')
   OR dr.id = 'b2be4262-96a1-43c9-8de9-04603bf5485a'
ORDER BY dr.created_at DESC;

-- Alternatif: Son 2 teslimat isteğini göster
SELECT 
    dr.id as "Teslimat ID",
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    dr.courier_id as "Atanan Kurye ID",
    courier.full_name as "Kurye Adı",
    courier.is_active as "Kurye Aktif mi",
    dr.rejected_by as "Red Eden Kurye ID",
    rejected_courier.full_name as "Red Eden Kurye Adı",
    dr.created_at as "Oluşturulma"
FROM delivery_requests dr
LEFT JOIN users courier ON dr.courier_id = courier.id
LEFT JOIN users rejected_courier ON dr.rejected_by = rejected_courier.id
ORDER BY dr.created_at DESC
LIMIT 2;
