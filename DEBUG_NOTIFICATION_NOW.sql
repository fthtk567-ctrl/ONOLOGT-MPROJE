-- ============================================
-- ACİL BİLDİRİM DEBUG - ŞİMDİ!
-- ============================================

-- 1. Son 10 dakikadaki tüm delivery_requests kayıtları
SELECT 
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

-- 2. Son 10 dakikadaki tüm notifications kayıtları
SELECT 
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

-- 3. Trigger'lar aktif mi?
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_name LIKE '%notif%'
ORDER BY trigger_name;

-- 4. Courier bilgileri (courier_id doğru mu?)
SELECT 
  id,
  email,
  full_name,
  role,
  is_available
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC;

-- ✅ Supabase'de çalıştır - sonuçları göster!
