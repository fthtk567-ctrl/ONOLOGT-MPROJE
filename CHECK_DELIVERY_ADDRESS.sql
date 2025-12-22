-- delivery_requests TABLOSUNUN ADRES KOLONLARINI KONTROL ET

SELECT 
    id,
    pickup_address,
    delivery_address,
    status
FROM delivery_requests
WHERE id = 'daf6c154-71e0-42d8-a3c9-c7764722686c'
LIMIT 1;
