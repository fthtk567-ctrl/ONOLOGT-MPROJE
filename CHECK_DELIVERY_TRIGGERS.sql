-- DELIVERY_REQUESTS TABLOSUNDAKI TRIGGER'LARI KONTROL ET

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;
