-- ============================================
-- TRİGGER KONTROLÜ - NEDEN ÇALIŞMIYOR?
-- ============================================

-- 1. Notification trigger'ları var mı?
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
  AND trigger_name LIKE '%notif%'
ORDER BY trigger_name;

-- 2. Trigger fonksiyonları var mı?
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines
WHERE routine_name IN ('add_notification_to_queue', 'notify_courier_simple')
ORDER BY routine_name;

-- 3. Son delivery_request'in detayları (trigger neden tetiklenmedi?)
SELECT 
  id,
  courier_id,
  status,
  created_at,
  updated_at,
  CASE 
    WHEN courier_id IS NOT NULL THEN '✅ courier_id DOLU - Trigger tetiklenmeliydi!'
    ELSE '❌ courier_id NULL - Trigger tetiklenmez'
  END as trigger_durumu
FROM delivery_requests
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 1;

-- ============================================
-- MANUEL TEST: Bildirim ekle (trigger bypass)
-- ============================================

-- Bu INSERT trigger'ı bypass eder ve DOĞRUDAN notifications'a yazar
-- Eğer bu çalışırsa, sorun trigger'da demektir
INSERT INTO notifications (user_id, title, message, type, is_read)
VALUES (
  '250f4abe-858a-457b-b972-9a76348a07c2',  -- fatih teke
  'MANUEL TEST BİLDİRİMİ',
  'Bu trigger bypass ile eklendi - görüyorsan sistem çalışıyor!',
  'delivery',
  false
);

-- Bu INSERT'ten sonra Courier App'te bildirim görünmeli!
-- Görünüyorsa → SORUN TRİGGER'DA
-- Görünmüyorsa → SORUN FLUTTER REALTIME'DA
