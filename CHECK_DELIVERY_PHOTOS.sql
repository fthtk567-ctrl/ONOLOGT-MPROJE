-- Teslimat fotoğraflarının durumunu kontrol et
SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    delivery_photo_url,
    CASE 
        WHEN delivery_photo_url IS NULL THEN '❌ Fotoğraf URL yok'
        WHEN delivery_photo_url = '' THEN '❌ Fotoğraf URL boş'
        WHEN delivery_photo_url LIKE 'http%' THEN '✅ URL formatı doğru'
        ELSE '⚠️ Belirsiz format'
    END as photo_status,
    created_at,
    updated_at
FROM delivery_requests 
WHERE status = 'delivered'
ORDER BY created_at DESC
LIMIT 10;

-- Toplam teslimat istatistikleri
SELECT 
    status,
    COUNT(*) as total,
    COUNT(delivery_photo_url) as with_photo,
    COUNT(*) - COUNT(delivery_photo_url) as without_photo
FROM delivery_requests 
GROUP BY status
ORDER BY status;