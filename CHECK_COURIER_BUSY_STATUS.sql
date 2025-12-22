-- Kuryelerin meşguliyet durumunu kontrol et

SELECT 
    email,
    full_name,
    is_available as "Mesaide mi?",
    is_busy as "Paket taşıyor mu?" ,
    is_active as "Aktif mi?"
FROM users
WHERE role = 'courier'
ORDER BY is_busy DESC, email;

-- Aktif teslimat isteklerini kontrol et
SELECT 
    dr.id,
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    u.full_name as "Kurye",
    u.is_busy as "Kurye Meşgul mu?"
FROM delivery_requests dr
LEFT JOIN users u ON dr.courier_id = u.id
WHERE dr.status IN ('assigned', 'accepted', 'picked_up')
ORDER BY dr.created_at DESC;
