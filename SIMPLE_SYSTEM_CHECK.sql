-- ============================================
-- BİLDİRİM SİSTEMİ KONTROL - BASİT VERSİYON
-- ============================================

-- 1. Trigger'lar VAR MI?
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
  AND trigger_name LIKE '%notif%';

-- Beklenen: 4 trigger olmalı
-- trigger_add_notification_on_insert
-- trigger_add_notification_on_update
-- trigger_notify_courier_on_insert
-- trigger_notify_courier_on_update

-- 2. Fonksiyonlar VAR MI?
SELECT routine_name
FROM information_schema.routines
WHERE routine_name IN ('add_notification_to_queue', 'notify_courier_simple');

-- Beklenen: 2 fonksiyon olmalı

-- 3. REALTIME AÇIK MI? (notifications tablosu için)
SELECT schemaname, tablename, enabled
FROM pg_publication_tables
WHERE tablename = 'notifications';

-- Beklenen: enabled = true olmalı

-- 4. Son delivery_request'e bakalım
SELECT 
  id,
  merchant_id,
  courier_id,
  status,
  created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 1;

-- ✅ Eğer bunlardan biri YOK ise, o eksiktir!
