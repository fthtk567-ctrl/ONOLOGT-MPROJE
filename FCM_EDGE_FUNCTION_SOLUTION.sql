-- ============================================
-- FCM - WEBHOOK İLE ÇÖZÜM (Supabase Edge Function)
-- ============================================

-- Edge Function kullan çünkü HTTP extension 404 veriyor!
-- 
-- ADIM 1: Supabase Dashboard -> Edge Functions -> New Function
-- Function name: send-fcm-notification
--
-- ADIM 2: Aşağıdaki kodu kopyala-yapıştır:

/*
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { fcmToken, title, body, data } = await req.json()

    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': 'key=AIzaSyBWO_lr-73AxfBlulvRD0W_wA0fzuTHAXg',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: {
          title: title,
          body: body,
          sound: 'default'
        },
        data: data,
        android: {
          priority: 'high',
          notification: {
            channel_id: 'new_order_channel'
          }
        }
      })
    })

    const result = await response.json()
    
    return new Response(
      JSON.stringify({ success: true, result }),
      { headers: { "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
*/

-- ADIM 3: Trigger fonksiyonunu güncelle (Edge Function çağır)

CREATE OR REPLACE FUNCTION notify_courier_with_fcm()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  courier_fcm_token TEXT;
  edge_function_url TEXT := 'https://piqhfygnbfaxvxbzqjkm.supabase.co/functions/v1/send-fcm-notification';
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
  SELECT COALESCE(business_name, owner_name, full_name, 'Merchant')
  INTO merchant_name
  FROM users
  WHERE id = NEW.merchant_id;

  -- Request payload hazırla
  request_payload := json_build_object(
    'fcmToken', courier_fcm_token,
    'title', '🚀 Yeni Teslimat İsteği!',
    'body', merchant_name || ' - Tutar: ' || NEW.declared_amount || ' TL',
    'data', json_build_object(
      'type', 'new_delivery_request',
      'delivery_request_id', NEW.id::text,
      'merchant_name', merchant_name,
      'declared_amount', NEW.declared_amount::text
    )
  );

  -- Edge Function'a POST gönder
  BEGIN
    SELECT * INTO fcm_response FROM extensions.http((
      'POST',
      edge_function_url,
      ARRAY[
        extensions.http_header('Content-Type', 'application/json'),
        extensions.http_header('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBpcWhmyWduYmZheHZ4YnpxamttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcyODk5MTIsImV4cCI6MjA0Mjg2NTkxMn0.rRCdjZt5UpiqCdm8g5qKM9cV7J0CnDwV6gk2Vt2HjZQ')
      ],
      'application/json',
      request_payload::text
    )::extensions.http_request);

    IF fcm_response.status = 200 THEN
      RAISE NOTICE '✅ FCM bildirimi gönderildi (Edge Function)! Courier: %', NEW.courier_id;
    ELSE
      RAISE WARNING '❌ Edge Function hatası: Status=%, Content=%', fcm_response.status, fcm_response.content;
    END IF;
    
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '❌ Edge Function isteği başarısız: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
