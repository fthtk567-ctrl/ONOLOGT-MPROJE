-- ============================================
-- NOTIFICATIONS TYPE CONSTRAINT KONTROL
-- ============================================

-- Type için izin verilen değerleri göster
SELECT 
  constraint_name,
  check_clause
FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%type%' 
  AND constraint_schema = 'public';

-- Alternatif: Mevcut notification'ların type değerlerini gör
SELECT DISTINCT type 
FROM notifications 
WHERE type IS NOT NULL
LIMIT 10;
