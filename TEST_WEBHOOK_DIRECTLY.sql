-- ======================================================================
-- WEBHOOK'U DOĞRUDAN TEST ET - HTTP İSTEĞİ GİDİYOR MU?
-- ======================================================================

-- 1. HTTP extension kontrolü
SELECT * FROM pg_extension WHERE extname = 'http';

-- Eğer boş dönerse HTTP extension kurulu değil!
-- Supabase'de normalde kurulu olmalı

-- ======================================================================
-- 2. MANUEL HTTP TESTİ - Webhook'a doğrudan istek at
-- ======================================================================

DO $$
DECLARE
  v_response RECORD;
  v_webhook_url TEXT := 'https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update';
  v_test_payload JSONB := jsonb_build_object(
    'delivery_id', 'TEST-UUID-12345',
    'external_order_id', 'YO-TEST-MANUEL',
    'status', 'delivered',
    'status_message', 'MANUEL TEST - Webhook çalışıyor mu?',
    'courier_name', 'Test Kurye',
    'courier_phone', '5551234567'
  );
BEGIN
  -- HTTP POST gönder
  RAISE NOTICE '🚀 Sending test webhook...';
  RAISE NOTICE 'URL: %', v_webhook_url;
  RAISE NOTICE 'Payload: %', v_test_payload;
  
  SELECT * INTO v_response FROM extensions.http_post(
    url := v_webhook_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer default-key'
    ),
    body := v_test_payload::text
  );
  
  RAISE NOTICE '✅ HTTP Response Status: %', v_response.status;
  RAISE NOTICE '📦 HTTP Response Body: %', v_response.content;
  
  IF v_response.status >= 200 AND v_response.status < 300 THEN
    RAISE NOTICE '🎉 WEBHOOK BAŞARILI!';
  ELSE
    RAISE WARNING '❌ WEBHOOK BAŞARISIZ - Status: %', v_response.status;
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '💥 HTTP İSTEĞİ HATASI: %', SQLERRM;
END $$;

-- ======================================================================
-- 3. HEMEN YEMEK APP LOGS'A BAK!
-- ======================================================================

/*
Supabase Dashboard:
1. Logs & Analytics
2. Edge Functions sekmesi
3. onlog-status-update fonksiyonu seç
4. Şu anda bir log görmelisin!

Eğer log görmüyorsan:
- HTTP extension yok
- veya net.http_post çalışmıyor
- veya firewall/network sorunu
*/

-- ======================================================================
-- 4. TRİGGER + WEBHOOK FULL TEST
-- ======================================================================

-- Gerçek bir sipariş update'i yap
UPDATE delivery_requests
SET status = 'picked_up'
WHERE external_order_id = 'YO-794063';

-- 3 saniye bekle

UPDATE delivery_requests
SET status = 'delivered', delivered_at = NOW()
WHERE external_order_id = 'YO-794063';

-- ŞİMDİ HEMEN:
-- Yemek App > Edge Functions > onlog-status-update > Logs
-- YO-794063 için log olmalı!

SELECT 'Test tamamlandı. Yemek App Edge Function logs kontrolü yap!' as sonuc;
