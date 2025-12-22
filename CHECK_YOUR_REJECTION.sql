-- SEN RED ETTİN - KADİRHAN'A ATANDI MI KONTROL ET

SELECT 
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    dr.courier_id as "Atanan Kurye ID",
    courier.email as "Kurye Email",
    courier.full_name as "Kurye Adı",
    dr.rejected_by as "Red Eden Kurye ID",
    rejected.email as "Red Eden Email",
    rejected.full_name as "Red Eden Adı",
    dr.updated_at as "Son Güncelleme"
FROM delivery_requests dr
LEFT JOIN users courier ON dr.courier_id = courier.id
LEFT JOIN users rejected ON dr.rejected_by = rejected.id
WHERE dr.order_number = 'ONL202511032'  -- Sana atanan sipariş
ORDER BY dr.updated_at DESC;

-- Alternatif: Son 3 teslimatı göster
SELECT 
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    courier.full_name as "Kurye",
    rejected.full_name as "Red Eden",
    dr.updated_at as "Güncelleme"
FROM delivery_requests dr
LEFT JOIN users courier ON dr.courier_id = courier.id
LEFT JOIN users rejected ON dr.rejected_by = rejected.id
ORDER BY dr.updated_at DESC
LIMIT 3;
