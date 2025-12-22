-- Son 30 dakikadaki tüm delivery_requests
SELECT * FROM delivery_requests 
WHERE created_at >= NOW() - INTERVAL '30 minutes'
ORDER BY created_at DESC;

-- Pending durumundaki istekler  
SELECT * FROM delivery_requests 
WHERE status = 'pending'
ORDER BY created_at DESC;

-- Test kuryenin ID'si
SELECT id, email, full_name, is_available, is_active 
FROM users 
WHERE email = 'trolloji.ai@gmail.com';

-- Test kuryeye atanmış istekler (ID ile değiştir)
SELECT * FROM delivery_requests 
WHERE courier_id = 'KURYE_ID_BURAYA'
ORDER BY created_at DESC;