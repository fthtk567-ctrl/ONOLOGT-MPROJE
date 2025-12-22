-- ======================================================================
-- YEMEK APP WEBHOOK TİMİNG DÜZELTMESİ
-- ======================================================================
-- SORUN: Kurye otomatik atandığında (status='assigned') hemen webhook gidiyor
-- ÇÖZÜM: Sadece kurye KABUL ettiğinde (status='accepted') webhook gitsin
-- ======================================================================
-- Tarih: 27 Kasım 2025
-- Kullanım: Supabase Dashboard → SQL Editor → Bu kodu çalıştır
-- ======================================================================

-- Webhook fonksiyonunu güncelle - Sadece 'accepted' ve sonrası durumlar için çalışsın
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
        -- ⚠️ Gerçek URL Yemek App ekibi tarafından verilecek
        webhook_url := 'https://YEMEK_APP_PROJECT.supabase.co/functions/v1/onlog-status-update';
      
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

-- Trigger'ı yeniden oluştur (eski varsa sil)
DROP TRIGGER IF EXISTS trigger_notify_platform_on_status_change ON delivery_requests;

CREATE TRIGGER trigger_notify_platform_on_status_change
  AFTER UPDATE OF status ON delivery_requests
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status) -- Sadece status değiştiğinde
  EXECUTE FUNCTION notify_external_platform_on_status_change();

-- Doğrulama
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_platform_on_status_change';

COMMIT;

-- ======================================================================
-- AÇIKLAMA
-- ======================================================================
/*
ŞİMDİ NASIL ÇALIŞACAK:

1. Yemek App'tan sipariş gelir → status: 'pending'
   ❌ Webhook GİTMEZ

2. Otomatik kurye ataması → status: 'assigned'
   ❌ Webhook GİTMEZ (Kurye henüz kabul etmedi)

3. Kurye sipariş kabul eder → status: 'accepted'
   ✅ WEBHOOK GİDER: "Kurye yolda - Siparişiniz teslim edilmek üzere yola çıktı"

4. Kurye paketi alır → status: 'picked_up'
   ✅ WEBHOOK GİDER: "Kurye paketi aldı - Teslimat adresine gidiyor"

5. Kurye teslim eder → status: 'delivered'
   ✅ WEBHOOK GİDER: "Teslim edildi - Afiyet olsun!"

KURYE RED EDERSE:
- Status 'assigned' → 'pending' olur (yeni kurye atanır)
- Webhook gitmez (çünkü 'pending' whitelist'te değil)
*/

-- ======================================================================
-- TEST SENARYOSU
-- ======================================================================

-- Test: Mevcut bir Yemek App siparişini accepted yap
/*
UPDATE delivery_requests
SET status = 'accepted'
WHERE source = 'yemek_app'
  AND status = 'assigned'
  AND external_order_id = 'YO-4521'
LIMIT 1;

-- Logları kontrol et
SELECT * FROM webhook_logs 
WHERE delivery_id = 'YUKARDAKI_DELIVERY_ID'
ORDER BY created_at DESC 
LIMIT 5;
*/
