-- ============================================
-- TÜM SORGULARI TEK SEFERDE ÇALIŞTIR
-- ============================================

-- SORGU 1: Son 10 dakikadaki delivery_requests
SELECT 
  'DELIVERY_REQUESTS' as tablo,
  id,
  merchant_id,
  courier_id,
  status,
  declared_amount,
  courier_payment_due,
  created_at,
  updated_at
FROM delivery_requests
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- SORGU 2: Son 10 dakikadaki notifications
SELECT 
  'NOTIFICATIONS' as tablo,
  id,
  user_id,
  title,
  message,
  type,
  is_read,
  created_at
FROM notifications
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- SORGU 3: Aktif notification trigger'ları
SELECT 
  'TRIGGERS' as tablo,
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing
FROM information_schema.triggers
WHERE trigger_name LIKE '%notif%'
ORDER BY trigger_name;

-- SORGU 4: Courier bilgileri
SELECT 
  'COURIERS' as tablo,
  id,
  email,
  full_name,
  role,
  is_available
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- ✅ Bu SQL'i Supabase'de çalıştır - 4 sonuç gelecek!
