-- Courier kullanıcısını otomatik aktif yap
UPDATE users 
SET is_available = true 
WHERE email = 'courier@onlog.com' 
  AND role = 'courier';

-- Kontrol et
SELECT id, email, owner_name, is_available, role 
FROM users 
WHERE email = 'courier@onlog.com';
