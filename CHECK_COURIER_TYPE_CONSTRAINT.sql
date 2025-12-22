-- Courier Type CHECK constraint'ini kontrol et

-- 1. Constraint'i görüntüle
SELECT 
  con.conname AS constraint_name,
  pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE rel.relname = 'users'
  AND con.contype = 'c'
  AND con.conname LIKE '%courier_type%';

-- 2. Şu anki courier type değerlerini gör
SELECT DISTINCT courier_type, COUNT(*) as adet
FROM users
WHERE courier_type IS NOT NULL
GROUP BY courier_type;
