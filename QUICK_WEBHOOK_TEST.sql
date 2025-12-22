-- WEBHOOK TEST - Tam kod
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
  RAISE NOTICE 'Sending test webhook...';
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
  
  RAISE NOTICE 'HTTP Response Status: %', v_response.status;
  RAISE NOTICE 'HTTP Response Body: %', v_response.content;
  
  IF v_response.status >= 200 AND v_response.status < 300 THEN
    RAISE NOTICE 'WEBHOOK BASARILI!';
  ELSE
    RAISE WARNING 'WEBHOOK BASARISIZ - Status: %', v_response.status;
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'HTTP ISTEGI HATASI: %', SQLERRM;
END $$;
