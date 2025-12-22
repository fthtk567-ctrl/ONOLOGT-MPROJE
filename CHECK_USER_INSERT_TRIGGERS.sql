-- ═══════════════════════════════════════════════════
-- USERS TABLOSUNA INSERT EDİLİRKEN ROLE DEĞİŞTİREN TRİGGER VARMI?
-- ═══════════════════════════════════════════════════

-- 1️⃣ Users tablosundaki tüm trigger'ları listele
SELECT 
    t.tgname AS trigger_name,
    p.proname AS function_name,
    pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_class c ON t.tgrelid = c.oid
WHERE c.relname = 'users'
  AND t.tgisinternal = false
ORDER BY t.tgname;

-- 2️⃣ Role ile ilgili trigger function'ları bul
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname ILIKE '%user%'
  AND p.proname ILIKE '%role%'
ORDER BY p.proname;

-- 3️⃣ Handle_new_user gibi function'lar var mı? (Supabase'de yaygın)
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname ILIKE '%handle%new%user%'
ORDER BY p.proname;

-- 4️⃣ Son eklenen user'ı kontrol et
SELECT 
    id,
    email,
    role,
    business_name,
    owner_name,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 5;
