-- handle_new_user fonksiyonunun TAMAMI
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as full_definition
FROM pg_proc p
WHERE p.proname = 'handle_new_user';
