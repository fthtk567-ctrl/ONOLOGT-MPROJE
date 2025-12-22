-- ============================================
-- FCM HTTP v1 API İLE ÇÖZÜM
-- ============================================

-- Legacy API kapalı! Yeni HTTP v1 API kullanacağız
-- ANCAK HTTP v1 için OAuth2 token lazım, bu da Supabase'den zor
-- 
-- EN KOLAY ÇÖZÜM: Supabase Edge Function kullan!

-- ADIM 1: Supabase Dashboard -> Edge Functions -> "New function"
-- Function name: send-fcm-push
-- 
-- ADIM 2: Bu kodu yapıştır:

/*
// supabase/functions/send-fcm-push/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FIREBASE_SERVER_KEY = "AIzaSyBWO_lr-73AxfBlulvRD0W_wA0fzuTHAXg"

serve(async (req) => {
  try {
    const { fcmToken, title, body, data } = await req.json()

    // Legacy API yerine yeni endpoint dene (bazen hala çalışır bazı projeler için)
    const legacyResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FIREBASE_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: {
          title: title,
          body: body,
          sound: 'default',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        data: data || {},
        priority: 'high',
        android: {
          priority: 'high',
          notification: {
            channel_id: 'new_order_channel',
            sound: 'default'
          }
        }
      })
    })

    const result = await legacyResponse.json()
    
    console.log('FCM Response:', result)
    
    return new Response(
      JSON.stringify({ 
        success: legacyResponse.ok, 
        status: legacyResponse.status,
        result 
      }),
      { 
        status: legacyResponse.ok ? 200 : 500,
        headers: { "Content-Type": "application/json" } 
      }
    )
  } catch (error) {
    console.error('FCM Error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
*/

-- ADIM 3: Deploy et: 
-- Terminal: supabase functions deploy send-fcm-push

-- ADIM 4: Trigger fonksiyonunu güncelle

CREATE OR REPLACE FUNCTION notify_courier_with_fcm()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  courier_fcm_token TEXT;
  edge_function_url TEXT := 'https://piqhfygnbfaxvxbzqjkm.supabase.co/functions/v1/send-fcm-push';
  anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBpcWhmyWduYmZheHZ4YnpxamttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcyODk5MTIsImV4cCI6MjA0Mjg2NTkxMn0.rRCdjZt5UpiqCdm8g5qKM9cV7J0CnDwV6gk2Vt2HjZQ';
  fcm_response RECORD;
  request_payload JSON;
BEGIN
  -- Kurye FCM token'ını al
  SELECT fcm_token INTO courier_fcm_token
  FROM users
  WHERE id = NEW.courier_id;

  IF courier_fcm_token IS NULL THEN
    RAISE NOTICE '❌ Kurye FCM token bulunamadı: %', NEW.courier_id;
    RETURN NEW;
  END IF;

  -- Merchant adını al
  SELECT COALESCE(business_name, owner_name, full_name, 'Yeni Merchant')
  INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;

  -- Request payload hazırla
  request_payload := json_build_object(
    'fcmToken', courier_fcm_token,
    'title', '🚀 Yeni Teslimat İsteği!',
    'body', merchant_name || ' - ' || NEW.declared_amount || ' TL',
    'data', json_build_object(
      'type', 'new_delivery',
      'delivery_id', NEW.id::text,
      'merchant_name', merchant_name,
      'amount', NEW.declared_amount::text
    )
  );

  -- Edge Function'a istek gönder
  BEGIN
    SELECT * INTO fcm_response FROM extensions.http((
      'POST',
      edge_function_url,
      ARRAY[
        extensions.http_header('Content-Type', 'application/json'),
        extensions.http_header('Authorization', 'Bearer ' || anon_key)
      ],
      'application/json',
      request_payload::text
    )::extensions.http_request);

    IF fcm_response.status BETWEEN 200 AND 299 THEN
      RAISE NOTICE '✅ FCM gönderildi! Courier: %, Status: %', NEW.courier_id, fcm_response.status;
    ELSE
      RAISE WARNING '⚠️ FCM yanıt: Status=%, Body=%', fcm_response.status, fcm_response.content;
    END IF;
    
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '❌ FCM hatası: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları yeniden oluştur
DROP TRIGGER IF EXISTS trigger_notify_courier_with_fcm ON delivery_requests;
DROP TRIGGER IF EXISTS trigger_notify_courier_fcm_on_update ON delivery_requests;

CREATE TRIGGER trigger_notify_courier_with_fcm
AFTER INSERT ON delivery_requests
FOR EACH ROW
WHEN (NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION notify_courier_with_fcm();

CREATE TRIGGER trigger_notify_courier_fcm_on_update
AFTER UPDATE ON delivery_requests
FOR EACH ROW
WHEN (OLD.courier_id IS NULL AND NEW.courier_id IS NOT NULL)
EXECUTE FUNCTION notify_courier_with_fcm();

-- Test et
SELECT 'Trigger ve fonksiyon güncellendi! Şimdi Edge Function oluştur.' as status;
