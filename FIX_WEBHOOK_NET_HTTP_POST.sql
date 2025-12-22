-- ======================================================================
-- WEBHOOK FONKSİYONU - SUPABASE net.http_post İLE
-- ======================================================================
-- net.http_post asenkron çalışır, response döndürmez
-- Webhook arka planda gönderilir
-- ======================================================================

CREATE OR REPLACE FUNCTION notify_external_platform_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  request_id BIGINT;
  courier_info RECORD;
  status_message TEXT;
  v_external_order_id TEXT;
BEGIN
  -- Sadece harici platformlardan gelen siparişler için çalış
  IF NEW.source IS NULL OR NEW.source = 'manual' THEN
    RETURN NEW;
  END IF;
  
  -- Sadece kurye KABUL ettiğinde veya sonraki durumlarda webhook gönder
  IF NEW.status NOT IN ('accepted', 'picked_up', 'delivered', 'cancelled') THEN
    RETURN NEW;
  END IF;
  
  v_external_order_id := NEW.external_order_id;
  
  -- Platform'a göre webhook URL'i belirle
  CASE NEW.source
    WHEN 'yemek_app' THEN
      webhook_url := 'https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update';
    WHEN 'trendyol' THEN
      webhook_url := 'https://api.trendyol.com/webhook/delivery-status';
    WHEN 'getir' THEN
      webhook_url := 'https://api.getir.com/webhook/delivery-status';
    ELSE
      webhook_url := NULL;
  END CASE;
  
  IF webhook_url IS NULL THEN
    RETURN NEW;
  END IF;
  
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
  
  -- ⭐ net.http_post ile asenkron webhook gönder (response yok)
  BEGIN
    SELECT net.http_post(
      url := webhook_url,
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2cGJyY3FiaHh5Y3Rtd254dG1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE4NjQ0MjMsImV4cCI6MjA0NzQ0MDQyM30.mh8XBXYIlJ6WN9lLORoL06wMOWx5_mwrSCRBZCfW4nk"}'::jsonb,
      body := payload
    ) INTO request_id;
    
    -- Request ID alındı = webhook kuyruğa eklendi
    RAISE NOTICE '[Webhook] Queued for %. Request ID: %, Order: %', 
      NEW.source, request_id, v_external_order_id;
    
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '[Webhook] Failed to queue: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger'ı güncelle
DROP TRIGGER IF EXISTS trigger_notify_platform_on_status_change ON delivery_requests;

CREATE TRIGGER trigger_notify_platform_on_status_change
  AFTER UPDATE OF status ON delivery_requests
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION notify_external_platform_on_status_change();

-- Doğrulama
SELECT 
  trigger_name,
  event_object_table,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_platform_on_status_change';

-- ✅ Fonksiyon güncellendi - net.http_post kullanıyor
-- ✅ Asenkron çalışır, response beklemez
-- ✅ Webhook arka planda gönderilir
