-- ============================================
-- FCM FONKSİYONU TEST ET - MANUEL ÇAĞIR
-- ============================================

-- Test için son teslimati al
DO $$
DECLARE
  test_delivery RECORD;
BEGIN
  -- Son teslimati al
  SELECT * INTO test_delivery 
  FROM delivery_requests 
  WHERE courier_id IS NOT NULL
  ORDER BY created_at DESC 
  LIMIT 1;
  
  -- Log yaz
  RAISE NOTICE '🔥 Test ediliyor - Delivery ID: %', test_delivery.id;
  RAISE NOTICE '📱 Courier ID: %', test_delivery.courier_id;
  
  -- FCM token var mı kontrol et
  DECLARE
    token TEXT;
  BEGIN
    SELECT fcm_token INTO token FROM users WHERE id = test_delivery.courier_id;
    
    IF token IS NULL THEN
      RAISE WARNING '❌ FCM TOKEN YOK! Courier: %', test_delivery.courier_id;
    ELSE
      RAISE NOTICE '✅ FCM Token var (uzunluk: %)', LENGTH(token);
    END IF;
  END;
END $$;

-- HTTP extension test
SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ HTTP Extension AKTİF'
    ELSE '❌ HTTP Extension YOK!'
  END as http_status
FROM pg_extension 
WHERE extname = 'http';

-- FCM fonksiyonu var mı?
SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ notify_courier_with_fcm() fonksiyonu VAR'
    ELSE '❌ Fonksiyon YOK!'
  END as function_status
FROM information_schema.routines 
WHERE routine_name = 'notify_courier_with_fcm';
