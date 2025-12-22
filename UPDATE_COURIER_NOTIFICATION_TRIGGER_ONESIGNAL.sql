-- OneSignal ile Çalışan Kurye Bildirimi Database Trigger
-- FCM yerine OneSignal Edge Function çağırır

-- HTTP extension'ı aktif et (Supabase'de genelde default aktiftir)
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- Eski trigger'ı kaldır
DROP TRIGGER IF EXISTS trigger_send_courier_notification ON delivery_requests;
DROP FUNCTION IF EXISTS send_courier_fcm_notification();

-- YENİ: OneSignal Edge Function çağıran fonksiyon
CREATE OR REPLACE FUNCTION send_courier_onesignal_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_player_id TEXT;
  v_merchant_name TEXT;
  v_delivery_address TEXT;
  v_delivery_fee NUMERIC;
  v_edge_function_url TEXT;
  v_response extensions.http_response;
BEGIN
  -- Sadece courier_id atandığında veya değiştiğinde çalış
  IF (TG_OP = 'UPDATE' AND NEW.courier_id IS NOT NULL AND 
      (OLD.courier_id IS NULL OR OLD.courier_id != NEW.courier_id)) OR
     (TG_OP = 'INSERT' AND NEW.courier_id IS NOT NULL) THEN
    
    RAISE NOTICE '[OneSignal Trigger] 📱 Kuryeye bildirim gönderiliyor: %', NEW.courier_id;
    
    -- Kurye OneSignal Player ID'sini al
    SELECT player_id INTO v_player_id
    FROM push_tokens
    WHERE user_id = NEW.courier_id
      AND is_active = true
    ORDER BY updated_at DESC
    LIMIT 1;
    
    IF v_player_id IS NULL THEN
      RAISE WARNING '[OneSignal Trigger] ❌ Kurye OneSignal Player ID bulunamadı: %', NEW.courier_id;
      RETURN NEW;
    END IF;
    
    RAISE NOTICE '[OneSignal Trigger] ✅ Player ID bulundu: %', SUBSTRING(v_player_id, 1, 20);
    
    -- Merchant bilgisini al
    SELECT COALESCE(business_name, owner_name, 'Merchant')
    INTO v_merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Teslimat bilgileri
    v_delivery_address := COALESCE(NEW.delivery_location->>'address', 'Adres bilgisi yok');
    v_delivery_fee := COALESCE(NEW.delivery_fee, 0);
    
    -- Edge Function URL (hardcoded - Supabase project URL)
    v_edge_function_url := 'https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/send-courier-notification';
    
    RAISE NOTICE '[OneSignal Trigger] 📤 Edge Function çağırılıyor: %', v_edge_function_url;
    
    -- Edge Function'a HTTP POST isteği gönder
    -- NOT: Authorization header gerekmez, Edge Function Service Role ile çalışıyor
    SELECT * INTO v_response
    FROM extensions.http((
      'POST',
      v_edge_function_url,
      ARRAY[
        extensions.http_header('Content-Type', 'application/json')
      ],
      'application/json',
      json_build_object(
        'orderId', COALESCE(NEW.order_id::TEXT, NEW.id::TEXT),
        'courierId', NEW.courier_id::TEXT,
        'merchantName', v_merchant_name,
        'deliveryAddress', v_delivery_address,
        'deliveryFee', v_delivery_fee
      )::text
    )::extensions.http_request);
    
    IF v_response.status >= 200 AND v_response.status < 300 THEN
      RAISE NOTICE '[OneSignal Trigger] ✅ Bildirim başarıyla gönderildi (HTTP %)', v_response.status;
    ELSE
      RAISE WARNING '[OneSignal Trigger] ⚠️ Bildirim gönderilemedi (HTTP %) - Response: %', 
        v_response.status, v_response.content;
    END IF;
    
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Hata olsa bile trigger'ı geçsin (sipariş işlemi bozulmasın)
    RAISE WARNING '[OneSignal Trigger] ❌ Hata oluştu: % - %', SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger'ı ekle (delivery_requests tablosuna)
CREATE TRIGGER trigger_send_courier_onesignal_notification
  AFTER INSERT OR UPDATE OF courier_id ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION send_courier_onesignal_notification();

-- Supabase konfigürasyonunu set et (ALTER DATABASE ile)
-- NOT: Bu komutlar Supabase Dashboard'da manuel çalıştırılmalı veya zaten ayarlanmış olabilir

-- Trigger test kontrolü
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_send_courier_onesignal_notification';

-- Başarılı mesaj
SELECT '✅ OneSignal Trigger başarıyla oluşturuldu!' as message;
