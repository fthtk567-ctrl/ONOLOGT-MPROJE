-- ============================================
-- notify_courier_with_fcm FONKSİYONUNU KONTROL ET
-- ============================================

SELECT pg_get_functiondef(oid) as function_code
FROM pg_proc
WHERE proname = 'notify_courier_with_fcm';
