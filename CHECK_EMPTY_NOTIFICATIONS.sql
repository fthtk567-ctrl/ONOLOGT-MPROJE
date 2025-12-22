-- BOŞ BİLDİRİMLERİ KONTROL ET

-- 1. Title veya message NULL olan bildirimleri bul
SELECT 
    id,
    title,
    message,
    notification_status,
    created_at,
    CASE 
        WHEN title IS NULL THEN 'Title NULL'
        WHEN title = '' THEN 'Title BOŞ'
        WHEN message IS NULL THEN 'Message NULL'
        WHEN message = '' THEN 'Message BOŞ'
        ELSE 'OK'
    END as problem
FROM notifications
WHERE title IS NULL 
   OR title = '' 
   OR message IS NULL 
   OR message = ''
ORDER BY created_at DESC
LIMIT 20;

-- 2. Son oluşturulan tüm bildirimleri göster
SELECT 
    id,
    title,
    message,
    data,
    notification_status,
    created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10;

-- 3. Bildirim oluşturan trigger'ı kontrol et
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND (action_statement ILIKE '%INSERT INTO notifications%');
