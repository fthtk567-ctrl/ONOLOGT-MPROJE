-- ============================================
-- YEMEK APP ENTEGRASYONU KONTROL
-- ============================================

-- 1. Durum bildirimi trigger'ı var mı?
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_name ILIKE '%notify_external%'
ORDER BY trigger_name;

-- 2. Komisyon hesaplama trigger'ı çalışıyor mu?
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_name ILIKE '%commission%'
ORDER BY trigger_name;

-- 3. Son teslimatın ücret detayları
SELECT 
  id,
  external_order_id,
  declared_amount,
  merchant_payment_due,
  courier_payment_due,
  status,
  source
FROM delivery_requests
WHERE source = 'yemek_app'
ORDER BY created_at DESC
LIMIT 1;

-- 4. notify_external_platform_on_status_change fonksiyonunu göster
SELECT pg_get_functiondef(oid) as function_code
FROM pg_proc
WHERE proname = 'notify_external_platform_on_status_change';
