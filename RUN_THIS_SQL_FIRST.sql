-- =====================================================
-- ÖNCE BU SQL'İ SUPABASE SQL EDITOR'DA ÇALIŞTIR!
-- =====================================================

-- 1. Eski pending notification'ları temizle
DELETE FROM notifications WHERE notification_status = 'pending';

-- 2. GERÇEK FCM TOKEN ile YENİ TEST bildirimi oluştur
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
    '🎉 TEST BİLDİRİMİ',
    'Yeni teslimat isteği var! Bu gerçek bir FCM bildirimidir.',
    'delivery',
    'pending',
    '{"order_id": "test-123", "delivery_address": "Test Mahallesi"}',
    NOW()
);

-- 3. Kontrol et
SELECT id, title, fcm_token, notification_status 
FROM notifications 
WHERE notification_status = 'pending';
