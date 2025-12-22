-- Fatih Teke kuryesini offline yap (is_available = false)
-- Böylece yeni siparişler TEST KURYE'ye gidecek

UPDATE users 
SET is_available = false
WHERE role = 'courier' 
AND owner_name = 'fatih teke';

-- Kontrol et
SELECT id, owner_name, role, is_available, status 
FROM users 
WHERE role = 'courier'
ORDER BY created_at DESC;
