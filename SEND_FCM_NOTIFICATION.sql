-- ============================================
-- FCM BİLDİRİM GÖNDERME FONKSİYONU
-- Bu fonksiyon courier'a FCM ile push notification gönderir
-- ============================================

CREATE OR REPLACE FUNCTION send_fcm_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_fcm_token TEXT;
  v_fcm_server_key TEXT := 'YOUR_FCM_SERVER_KEY_HERE'; -- Firebase Console'dan alınacak
  v_response TEXT;
BEGIN
  -- Kullanıcının FCM token'ını al
  SELECT fcm_token INTO v_fcm_token
  FROM users
  WHERE id = p_user_id AND fcm_token IS NOT NULL;
  
  IF v_fcm_token IS NULL THEN
    RAISE NOTICE 'FCM token bulunamadı: %', p_user_id;
    RETURN FALSE;
  END IF;
  
  -- FCM API'ye HTTP POST isteği gönder
  -- NOT: Supabase'de http extension kullanılıyor
  SELECT content INTO v_response
  FROM http((
    'POST',
    'https://fcm.googleapis.com/fcm/send',
    ARRAY[
      http_header('Authorization', 'key=' || v_fcm_server_key),
      http_header('Content-Type', 'application/json')
    ],
    'application/json',
    json_build_object(
      'to', v_fcm_token,
      'notification', json_build_object(
        'title', p_title,
        'body', p_body,
        'sound', 'default',
        'badge', '1'
      ),
      'data', p_data,
      'priority', 'high'
    )::text
  )::http_request);
  
  RAISE NOTICE 'FCM Response: %', v_response;
  RETURN TRUE;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'FCM gönderme hatası: %', SQLERRM;
  RETURN FALSE;
END;
$$;

-- ============================================
-- TRİGGER FONKSİYONUNU GÜNCELLE (FCM Ekle)
-- ============================================

CREATE OR REPLACE FUNCTION add_notification_to_queue()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_courier_id UUID;
  v_merchant_name TEXT;
  v_amount NUMERIC;
  v_title TEXT;
  v_message TEXT;
BEGIN
  -- Courier ID'yi al
  v_courier_id := NEW.courier_id;
  
  IF v_courier_id IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Merchant bilgilerini al
  SELECT business_name INTO v_merchant_name
  FROM users
  WHERE id = NEW.merchant_id;
  
  v_amount := COALESCE(NEW.declared_amount, 0);
  v_title := 'Yeni Teslimat!';
  v_message := format('Tutar: %s TL', v_amount::TEXT);
  
  -- Notification tablosuna ekle
  INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    related_id,
    is_read,
    created_at
  ) VALUES (
    v_courier_id,
    v_title,
    v_message,
    'delivery',
    NEW.id,
    FALSE,
    NOW()
  );
  
  -- 🔥 YENİ: FCM ile push notification gönder
  PERFORM send_fcm_notification(
    v_courier_id,
    v_title,
    v_message,
    jsonb_build_object(
      'type', 'new_delivery',
      'delivery_id', NEW.id,
      'amount', v_amount
    )
  );
  
  RAISE NOTICE 'Bildirim eklendi ve FCM gönderildi: courier_id=%, title=%', v_courier_id, v_title;
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Bildirim ekleme hatası: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- ============================================
-- HTTP EXTENSION'I AKTİF ET (Gerekirse)
-- ============================================
-- Supabase Dashboard > SQL Editor'den çalıştır:
-- CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;
