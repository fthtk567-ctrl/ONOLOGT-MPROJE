-- Kuryelere Otomatik Bildirim Gönderen Database Trigger ve Function
-- Orders tablosuna yeni kayıt eklendiğinde veya courier_id güncellendiğinde
-- otomatik olarak Edge Function'ı tetikler

-- 1. Edge Function'ı çağıran PostgreSQL fonksiyonu
CREATE OR REPLACE FUNCTION notify_courier_on_assignment()
RETURNS TRIGGER AS $$
DECLARE
  v_courier_id UUID;
  v_merchant_name TEXT;
  v_delivery_address TEXT;
  v_delivery_fee NUMERIC;
  v_function_url TEXT;
  v_service_role_key TEXT;
  v_response TEXT;
BEGIN
  -- Sadece courier_id atandığında bildirim gönder
  IF (TG_OP = 'INSERT' AND NEW.courier_id IS NOT NULL) OR
     (TG_OP = 'UPDATE' AND OLD.courier_id IS NULL AND NEW.courier_id IS NOT NULL) OR
     (TG_OP = 'UPDATE' AND OLD.courier_id IS DISTINCT FROM NEW.courier_id AND NEW.courier_id IS NOT NULL) THEN
    
    -- Courier ID'yi al
    v_courier_id := NEW.courier_id;
    
    -- Merchant bilgisini al
    SELECT full_name INTO v_merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Teslimat adresini hazırla
    v_delivery_address := NEW.delivery_address;
    
    -- Teslimat ücretini al (varsayılan 25 TL)
    v_delivery_fee := COALESCE(NEW.delivery_fee, 25);
    
    -- Edge Function URL (Supabase project URL ile değiştirilecek)
    v_function_url := current_setting('app.settings.supabase_url', true) || '/functions/v1/send-courier-notification';
    
    -- Service role key (secrets olarak saklanmalı)
    v_service_role_key := current_setting('app.settings.supabase_service_role_key', true);
    
    -- Edge Function'ı HTTP POST ile çağır
    SELECT content INTO v_response
    FROM http((
      'POST',
      v_function_url,
      ARRAY[
        http_header('Authorization', 'Bearer ' || v_service_role_key),
        http_header('Content-Type', 'application/json')
      ],
      'application/json',
      json_build_object(
        'orderId', NEW.id::TEXT,
        'courierId', v_courier_id::TEXT,
        'merchantName', v_merchant_name,
        'deliveryAddress', v_delivery_address,
        'deliveryFee', v_delivery_fee
      )::TEXT
    )::http_request);
    
    -- Başarı logu
    RAISE NOTICE 'Kurye bildirim gönderildi: Order ID %, Courier ID %, Response: %', 
      NEW.id, v_courier_id, v_response;
    
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Hata olsa bile işlem devam etsin
    RAISE WARNING 'Kurye bildirimi gönderilemedi: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger oluştur
DROP TRIGGER IF EXISTS trigger_notify_courier_on_assignment ON orders;

CREATE TRIGGER trigger_notify_courier_on_assignment
  AFTER INSERT OR UPDATE OF courier_id ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_courier_on_assignment();

-- 3. pg_net extension kontrolü (HTTP istekleri için gerekli)
-- Not: Supabase Dashboard'da SQL Editor'de çalıştırılmalı
-- CREATE EXTENSION IF NOT EXISTS pg_net;

-- 4. Supabase settings yapılandırması (Supabase secrets kullanarak)
-- Supabase Dashboard > Project Settings > Database > Custom Postgres Configuration
-- Bu değerleri secrets olarak ekleyin:

-- app.settings.supabase_url = 'https://your-project.supabase.co'
-- app.settings.supabase_service_role_key = 'your-service-role-key'

COMMENT ON FUNCTION notify_courier_on_assignment() IS 
'Kuryelere yeni teslimat ataması yapıldığında otomatik bildirim gönderir';

COMMENT ON TRIGGER trigger_notify_courier_on_assignment ON orders IS 
'Orders tablosuna courier_id atandığında veya güncellendiğinde kurye bildirim Edge Function tetikler';
