-- AYNI FCM TOKEN'A SAHİP KULLANICILARI BUL

SELECT 
    id,
    email,
    full_name,
    role,
    fcm_token,
    created_at
FROM users
WHERE fcm_token = 'dfLkpcv2RDmBSJ5-D_04t8:APA91bEQORJenXST8mA1Ii22WGY3XUZuawBDzFQECOj_k9B6824LLeZQIc7O2hndYNiuhbFb2pS0PQi--gzq5L7YEGlF1PLEVeiS2a5JrXiHyQ3-oEqyeM0'
ORDER BY created_at DESC;
