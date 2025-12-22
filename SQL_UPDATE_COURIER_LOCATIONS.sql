-- ================================================================
-- Kuryeler için test konum verileri ekle
-- ================================================================

-- 1. Önce kuryeler var mı kontrol et
SELECT id, email, full_name, role, is_available, current_location
FROM users
WHERE role = 'courier';

-- 2. Eğer kurye yoksa, bir test kuryesi oluştur
INSERT INTO users (email, role, full_name, is_available, current_location)
VALUES (
    'kurye1@test.com',
    'courier',
    'Test Kurye 1',
    true,
    '{"lat": 41.0082, "lng": 28.9784}'::jsonb
)
ON CONFLICT (email) DO UPDATE
SET 
    is_available = true,
    current_location = '{"lat": 41.0082, "lng": 28.9784}'::jsonb;

-- 3. Mevcut tüm kuryelere konum ekle (İstanbul merkezli random konumlar)
UPDATE users
SET 
    is_available = true,
    current_location = '{"lat": 41.0082, "lng": 28.9784}'::jsonb
WHERE role = 'courier' AND id = (
    SELECT id FROM users WHERE role = 'courier' LIMIT 1
);

-- 4. Sonuç kontrol
SELECT id, email, full_name, role, is_available, current_location
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;
