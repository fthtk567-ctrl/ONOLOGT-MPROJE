-- SON 5 DAKİKADAKİ TÜM delivery_requests KAYITLARINI KONTROL ET

SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    created_at
FROM delivery_requests
WHERE created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC;
