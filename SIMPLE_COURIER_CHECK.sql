-- Basit kurye kontrol sorgusu
SELECT 
    id,
    owner_name,
    email,
    is_available,
    status,
    current_location
FROM users 
WHERE role = 'courier'
ORDER BY owner_name;

-- Son teslimat hangi kuryeye gitti?
SELECT 
    dr.id,
    dr.courier_id,
    u.owner_name,
    dr.created_at
FROM delivery_requests dr
LEFT JOIN users u ON dr.courier_id = u.id
ORDER BY dr.created_at DESC
LIMIT 3;