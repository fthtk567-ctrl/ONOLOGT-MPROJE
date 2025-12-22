-- ======================================================================
-- WEBHOOK URL'İNİ DOĞRU YEMEK APP PROJESİNE ÇEVİR
-- ======================================================================
-- Sorun: Webhook yanlış project URL'ine gidiyor
-- Çözüm: Yemek App'ın gerçek Supabase project URL'ini kullan
-- ======================================================================

-- 1. Yemek App'ın gerçek project URL'ini bul:
-- Supabase Dashboard > Project Settings > API
-- Project URL: https://XXXXX.supabase.co

-- 2. Webhook fonksiyonunu DOĞRU URL ile güncelle

CREATE OR REPLACE FUNCTION notify_external_platform_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  http_response RECORD;
  courier_info RECORD;
  status_message TEXT;
  v_external_order_id TEXT;
BEGIN
  RAISE NOTICE '[Webhook] Trigger fired for delivery_id: %, status: %', NEW.id, NEW.status;
  
  IF NEW.source IS NULL OR NEW.source = 'manual' THEN
    RAISE NOTICE '[Webhook] Skipping - source is manual or null';
    RETURN NEW;
  END IF;
  
  IF NEW.status NOT IN ('accepted', 'picked_up', 'delivered', 'cancelled') THEN
    RAISE NOTICE '[Webhook] Skipping webhook for status: % (waiting for courier acceptance)', NEW.status;
    RETURN NEW;
  END IF;
  
  v_external_order_id := NEW.external_order_id;
  
  RAISE NOTICE '[Webhook] Processing status change for delivery: %', NEW.id;
  RAISE NOTICE '[Webhook] External order ID: %', v_external_order_id;
  RAISE NOTICE '[Webhook] Source: %, Status: %', NEW.source, NEW.status;
  
  -- ⭐ Platform'a göre webhook URL'i belirle
  CASE NEW.source
    WHEN 'yemek_app' THEN
      -- ✅ YEMEK APP'IN GERÇEK PROJECT URL'İNİ BURAYA YAZ!
      -- Supabase Dashboard > Project Settings > API > Project URL
      webhook_url := 'https://YEMEK_APP_PROJECT_ID.supabase.co/functions/v1/onlog-status-update';
      
      -- ÖRNEKLERİ KALDIRDIM - YUKARI SADECE DOĞRU URL'İ YAZ ☝️
    
    WHEN 'trendyol' THEN
      webhook_url := 'https://api.trendyol.com/webhook/delivery-status';
    
    WHEN 'getir' THEN
      webhook_url := 'https://api.getir.com/webhook/delivery-status';
    
    ELSE
      webhook_url := NULL;
  END CASE;
  
  IF webhook_url IS NULL THEN
    RAISE NOTICE '[Webhook] No webhook URL configured for source: %', NEW.source;
    RETURN NEW;
  END IF;
  
  RAISE NOTICE '[Webhook] Webhook URL: %', webhook_url;
  
  -- Kurye bilgilerini al
  IF NEW.courier_id IS NOT NULL THEN
    SELECT owner_name, phone INTO courier_info
    FROM users 
    WHERE id = NEW.courier_id;
    
    RAISE NOTICE '[Webhook] Courier: % (%)', courier_info.owner_name, courier_info.phone;
  ELSE
    RAISE NOTICE '[Webhook] No courier assigned';
  END IF;
  
  -- Status'e göre mesaj belirle
  CASE NEW.status
    WHEN 'accepted' THEN
      status_message := 'Kurye yolda - Siparişiniz teslim edilmek üzere yola çıktı';
    WHEN 'picked_up' THEN
      status_message := 'Kurye paketi aldı - Teslimat adresine gidiyor';
    WHEN 'delivered' THEN
      status_message := 'Teslim edildi - Afiyet olsun!';
    WHEN 'cancelled' THEN
      status_message := 'Sipariş iptal edildi';
    ELSE
      status_message := 'Sipariş durumu güncellendi';
  END CASE;
  
  -- Payload oluştur
  payload := jsonb_build_object(
    'delivery_id', NEW.id,
    'external_order_id', v_external_order_id,
    'status', NEW.status,
    'status_message', status_message,
    'courier_id', NEW.courier_id,
    'courier_name', COALESCE(courier_info.owner_name, 'Bilinmiyor'),
    'courier_phone', COALESCE(courier_info.phone, ''),
    'updated_at', NEW.updated_at,
    'estimated_delivery_time', NEW.estimated_delivery_time,
    'delivered_at', NEW.delivered_at,
    'cancellation_reason', NEW.cancellation_reason
  );
  
  RAISE NOTICE '[Webhook] Payload: %', payload::text;
  RAISE NOTICE '[Webhook] Sending HTTP POST to %', webhook_url;
  
  -- HTTP POST gönder
  BEGIN
    SELECT * INTO http_response FROM net.http_post(
      url := webhook_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(current_setting('app.yemek_app_webhook_key', true), 'default-key')
      ),
      body := payload::text
    );
    
    RAISE NOTICE '[Webhook] HTTP Response Status: %', http_response.status;
    RAISE NOTICE '[Webhook] HTTP Response Body: %', http_response.content;
    
    IF http_response.status >= 200 AND http_response.status < 300 THEN
      RAISE NOTICE '[Webhook] ✅ Webhook sent successfully to % for order %', NEW.source, v_external_order_id;
    ELSE
      RAISE WARNING '[Webhook] ❌ Webhook failed with status % for order %', http_response.status, v_external_order_id;
    END IF;
    
    -- Log webhook gönderimini (opsiyonel)
    BEGIN
      INSERT INTO webhook_logs (
        delivery_id,
        external_order_id,
        platform,
        webhook_url,
        payload,
        http_status,
        response_body,
        created_at
      ) VALUES (
        NEW.id,
        v_external_order_id,
        NEW.source,
        webhook_url,
        payload,
        http_response.status,
        http_response.content::JSONB,
        NOW()
      );
      RAISE NOTICE '[Webhook] Log saved to webhook_logs table';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '[Webhook] webhook_logs table not found (optional feature) - %', SQLERRM;
    END;
    
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '[Webhook] ❌ HTTP request exception for %: %', NEW.source, SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ======================================================================
-- YEMEK APP PROJECT URL'İNİ NASIL BULURSUN?
-- ======================================================================

/*
1. Yemek App Supabase Dashboard'a git
2. Sol altta: ⚙️ Settings (Ayarlar)
3. API sekmesine tıkla
4. "Project URL" kopyala
   Örnek: https://fthtk567ctrl.supabase.co

5. Webhook URL'ini oluştur:
   https://YUKARDAKI_PROJECT_URL/functions/v1/onlog-status-update

6. SQL'deki webhook_url satırına yapıştır (satır 32)

ÖRNEKLERİ KALDIR, SADECE YEMEK APP URL'İNİ BIRAK!
*/
