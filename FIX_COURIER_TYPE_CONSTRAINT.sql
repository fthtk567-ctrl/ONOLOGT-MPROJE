-- Courier Type Constraint'ini düzelt - "esnaf" ekle

-- 1. Eski constraint'i sil
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_courier_type_check;

-- 2. Yeni constraint ekle - "esnaf" dahil
ALTER TABLE users
ADD CONSTRAINT users_courier_type_check 
CHECK (
  courier_type IS NULL 
  OR 
  courier_type IN ('sgk', 'esnaf', 'freelance')
);

-- ✅ Artık esnaf kuryeler kayıt olabilir!

-- Test et:
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'users_courier_type_check';
