-- SON TESLİMAT İSTEĞİ İÇİN OLUŞAN BİLDİRİMLERİ KONTROL ET

SELECT 
    id,
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
FROM notifications
WHERE type = 'new_delivery_request'
ORDER BY created_at DESC
LIMIT 10;
