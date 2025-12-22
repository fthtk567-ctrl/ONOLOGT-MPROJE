-- auth.users tablosundan public.users'a otomatik kayıt yapan trigger'ı bul
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE (
    p.proname ILIKE '%handle%new%user%'
    OR p.proname ILIKE '%create%user%'
    OR p.proname ILIKE '%insert%user%'
    OR p.proname ILIKE '%auth%'
)
AND n.nspname = 'public'
ORDER BY p.proname;
