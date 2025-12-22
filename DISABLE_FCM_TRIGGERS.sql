-- ============================================
-- TÜM FCM TRİGGERLARINI GEÇİCİ OLARAK DEVRE DIŞI BIRAK
-- Yemek App entegrasyonu test için
-- ============================================

-- 1. delivery_requests tablosundaki tüm bildirim trigger'larını kaldır
DROP TRIGGER IF EXISTS trigger_send_courier_notification ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_queue_courier_notification ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_on_insert ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_insert ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_update ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_add_notification_on_delivery_request ON delivery_requests;

-- 2. notifications tablosundaki auto-send trigger'larını kaldır
DROP TRIGGER IF EXISTS on_notification_insert_trigger ON notifications;
DROP TRIGGER IF EXISTS trigger_call_fcm_edge_function ON notifications;
DROP TRIGGER IF EXISTS trigger_send_fcm_on_notification_insert ON notifications;

-- 3. Kontrol: Aktif trigger'ları listele
SELECT 
    trigger_name,
    event_object_table as table_name,
    action_statement as function_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND event_object_table IN ('delivery_requests', 'notifications')
ORDER BY event_object_table, trigger_name;

-- Sonuç boş dönerse = tüm trigger'lar devre dışı ✅
