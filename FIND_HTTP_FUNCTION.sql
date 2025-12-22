-- HTTP POST fonksiyonunu bul
SELECT 
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname LIKE '%http%post%'
ORDER BY n.nspname, p.proname;

-- Alternatif: Tüm http fonksiyonlarını listele
SELECT 
  n.nspname AS schema_name,
  p.proname AS function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname LIKE '%http%'
ORDER BY n.nspname, p.proname;
