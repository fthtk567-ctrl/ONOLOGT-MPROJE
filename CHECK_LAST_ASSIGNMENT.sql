-- TEST KURYE'nin durumunu kontrol et
-- Deaktif olması gerekiyordu!

SELECT 
    email,
    full_name,
    owner_name,
    is_active as "Aktif mi?",
    is_available as "Mesaide mi?",
    status,
    current_location
FROM users
WHERE email = 'trolloji.ai@gmail.com' OR owner_name = 'TEST KURYE'
ORDER BY email;

-- Son teslimat isteği kime atandı?
SELECT 
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    courier.email as "Kurye Email",
    courier.full_name as "Kurye Adı",
    courier.is_active as "Kurye Aktif mi?",
    courier.is_available as "Kurye Mesaide mi?",
    dr.created_at as "Oluşturulma"
FROM delivery_requests dr
LEFT JOIN users courier ON dr.courier_id = courier.id
ORDER BY dr.created_at DESC
LIMIT 3;
