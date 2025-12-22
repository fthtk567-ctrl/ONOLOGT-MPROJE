-- ======================================================================
-- YEMEK APP GERÇEK WEBHOOK URL GÜNCELLEMESİ
-- ======================================================================
-- Gerçek Yemek App webhook URL'i: 
-- https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update
-- ======================================================================
-- Tarih: 27 Kasım 2025
-- ======================================================================

CREATE OR REPLACE FUNCTION notify_external_platform_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  http_response RECORD;
  courier_info RECORD;
  status_message TEXT;
BEGIN
  -- Sadece harici platformlardan gelen siparişler için çalış
  IF NEW.source IS NOT NULL AND NEW.source != 'manual' THEN
    
    -- ⭐ ÖNEMLİ: Sadece kurye KABUL ettiğinde veya sonraki durumlarda webhook gönder
    -- 'pending' ve 'assigned' durumlarında webhook gönderme!
    IF NEW.status NOT IN ('accepted', 'picked_up', 'delivered', 'cancelled') THEN
      RAISE NOTICE '[Webhook] Skipping webhook for status: % (waiting for courier acceptance)', NEW.status;
      RETURN NEW;
    END IF;
    
    -- Platform'a göre webhook URL'i belirle
    CASE NEW.source
      WHEN 'yemek_app' THEN
        -- ✅ GERÇEK YEMEK APP WEBHOOK URL
        webhook_url := 'https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update';
      
      WHEN 'trendyol' THEN
        webhook_url := 'https://api.trendyol.com/webhook/delivery-status';
      
      WHEN 'getir' THEN
        webhook_url := 'https://api.getir.com/webhook/delivery-status';
      
      ELSE
        webhook_url := NULL;
    END CASE;
    
    -- Webhook URL geçerliyse gönder
    IF webhook_url IS NOT NULL THEN
      
      -- Kurye bilgilerini al
      IF NEW.courier_id IS NOT NULL THEN
        SELECT owner_name, phone INTO courier_info
        FROM users 
        WHERE id = NEW.courier_id;
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
        'external_order_id', NEW.external_order_id,
        'status', NEW.status,
        'status_message', status_message,
        'courier_id', NEW.courier_id,
        'courier_name', COALESCE(courier_info.owner_name, 'Bilinmiyor'),
        'courier_phone', COALESCE(courier_info.phone, ''),
        'updated_at', NEW.updated_at,
        'estimated_delivery_time', NEW.estimated_delivery_time
      );
      
      -- HTTP POST gönder
      BEGIN
        SELECT * INTO http_response FROM net.http_post(
          url := webhook_url,
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.yemek_app_webhook_key', true)
          ),
          body := payload::text
        );
        
        RAISE NOTICE '[Webhook] Status update sent to % for order %: status=%', 
          NEW.source, NEW.external_order_id, NEW.status;
        
        -- Log webhook gönderimini (opsiyonel - webhook_logs tablosu varsa)
        BEGIN
          INSERT INTO webhook_logs (
            delivery_id,
            platform,
            webhook_url,
            payload,
            http_status,
            response_body,
            created_at
          ) VALUES (
            NEW.id,
            NEW.source,
            webhook_url,
            payload,
            http_response.status,
            http_response.content::JSONB,
            NOW()
          );
        EXCEPTION WHEN OTHERS THEN
          RAISE WARNING '[Webhook] Log save failed: %', SQLERRM;
        END;
        
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[Webhook] HTTP request failed for %: %', NEW.source, SQLERRM;
      END;
      
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Doğrulama
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'notify_external_platform_on_status_change';

COMMIT;

-- ======================================================================
-- TEST
-- ======================================================================
-- Şimdi yeni bir sipariş kabul edildiğinde webhook gerçek URL'e gidecek!
-- Test için mevcut bir siparişi 'accepted' yapabilirsiniz:
/*
UPDATE delivery_requests
SET status = 'accepted'
WHERE source = 'yemek_app'
  AND status = 'assigned'
  AND external_order_id = 'YO-418592';
*/
