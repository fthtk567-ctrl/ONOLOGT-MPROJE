-- delivery_requests tablosundaki valid_status constraint'ini kontrol et

-- 1. Constraint tanımını bul
SELECT 
  con.conname AS constraint_name,
  pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'delivery_requests'
  AND con.contype = 'c'  -- check constraint
  AND con.conname LIKE '%status%';

-- 2. Mevcut status değerlerine bak
SELECT DISTINCT status, COUNT(*) as adet
FROM delivery_requests
GROUP BY status
ORDER BY adet DESC;

-- 3. Sütun detaylarını gör
SELECT 
  column_name,
  data_type,
  character_maximum_length,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND column_name = 'status';
