-- =====================================================
-- YENİ KOD TESTİ - SQL
-- =====================================================

-- 1. Eski pending bildirimleri temizle
DELETE FROM notifications WHERE notification_status = 'pending';

-- 2. YENİ TEST bildirimi oluştur
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
    '🚀 YENİ KOD TESTİ',
    'Bu güncellenmiş Edge Function ile gönderiliyor! Ses ve titreşim olmalı.',
    'delivery',
    'pending',
    '{"order_id": "test-789", "test": "updated_code"}',
    NOW()
);

-- 3. Kontrol et
SELECT id, title, notification_status FROM notifications WHERE notification_status = 'pending';
