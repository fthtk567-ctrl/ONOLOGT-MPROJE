-- SON ARKA PLAN TESTİ (Pil optimizasyonu kapatıldıktan sonra)
DELETE FROM notifications WHERE notification_status = 'pending';

INSERT INTO notifications (
    user_id,
    fcm_token,
    title,
    message,
    type,
    notification_status,
    data,
    created_at
) VALUES (
    '4ff777e0-5bcc-4c21-8785-c650f5667d86',
    'dfLkpcv2RDmBSJ5-D_04t8:APA91bEQORJenXST8mA1Ii22WGY3XUZuawBDzFQECOj_k9B6824LLeZQIc7O2hndYNiuhbFb2pS0PQi--gzq5L7YEGlF1PLEVeiS2a5JrXiHyQ3-oEqyeM0',
    '✅ FİNAL TEST - Pil Optimizasyonu Kapalı',
    'Arka plan interneti açık - ŞIMDI GELMELI! 🎉',
    'delivery',
    'pending',
    '{"test": "battery_optimization_disabled"}',
    NOW()
);

SELECT id, title FROM notifications WHERE notification_status = 'pending';
