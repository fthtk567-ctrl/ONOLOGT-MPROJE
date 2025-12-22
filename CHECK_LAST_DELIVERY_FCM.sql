-- ============================================
-- SON TESLİMAT VE FCM DURUM KONTROLÜ
-- ============================================

-- 1. Son teslimat
SELECT 
  id,
  merchant_id,
  courier_id,
  status,
  declared_amount,
  created_at
FROM delivery_requests 
ORDER BY created_at DESC 
LIMIT 1;

-- 2. Courier'ın FCM token'ı var mı?
SELECT 
  id,
  email,
  fcm_token IS NOT NULL as has_fcm_token,
  LENGTH(fcm_token) as token_length
FROM users 
WHERE id = '250f4abe-858a-457b-b972-9a76340b07c2';

-- 3. Son bildirimi kontrol et
SELECT 
  id,
  user_id,
  title,
  message,
  is_read,
  created_at
FROM notifications 
ORDER BY created_at DESC 
LIMIT 1;

-- 4. FCM trigger'ları kontrol et
SELECT 
  trigger_name,
  event_object_table,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%fcm%';
