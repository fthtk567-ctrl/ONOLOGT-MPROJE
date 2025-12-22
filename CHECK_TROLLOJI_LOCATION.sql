-- trolloji.ai@gmail.com kuryesinin konum bilgilerini kontrol et

SELECT 
    email,
    full_name,
    current_location,
    is_available as "Mesaide mi?",
    is_active as "Aktif mi?",
    status,
    last_login as "Son Giriş",
    updated_at as "Son Güncelleme"
FROM users
WHERE email = 'trolloji.ai@gmail.com';

-- Tüm aktif kuryelerin konum durumunu karşılaştır
SELECT 
    email,
    full_name,
    current_location,
    is_available,
    CASE 
        WHEN current_location IS NULL THEN '❌ Konum YOK'
        WHEN current_location->>'latitude' IS NULL THEN '❌ Lat/Lng YOK'
        ELSE '✅ Konum VAR'
    END as "Konum Durumu"
FROM users
WHERE role = 'courier' 
  AND is_active = true
ORDER BY email;
