-- HER İKİ KURYE HESABININ TOKEN DURUMUNU KONTROL ET

SELECT 
    id,
    email,
    full_name,
    role,
    fcm_token,
    updated_at,
    created_at
FROM users
WHERE email IN ('courier@onlog.com', 'trolloji.ai@gmail.com')
ORDER BY updated_at DESC;
