-- Yemek App'ten gelen son siparişleri kontrol et
SELECT 
    id,
    external_order_id,
    source,
    status,
    merchant_id,
    courier_id,
    declared_amount,
    pickup_location->>'address' as pickup_address,
    delivery_location->>'latitude' as delivery_lat,
    delivery_location->>'longitude' as delivery_lng,
    delivery_location->>'address' as delivery_address,
    created_at
FROM delivery_requests
WHERE source = 'yemek_app'
ORDER BY created_at DESC
LIMIT 5;

-- Eğer kayıt varsa, validasyon geçilmiş demektir
-- Eğer kayıt yoksa, validasyon engelliyor demektir
