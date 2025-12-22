-- ======================================================================
-- WEBHOOK GERÇEKTEn GiTTi Mi? - YEMEk APP TARAFINDA KONTROL
-- ======================================================================

-- 1. Son durumu kontrol et
SELECT 
  external_order_id,
  order_number,
  status,
  source,
  courier_id,
  updated_at,
  delivered_at
FROM delivery_requests
WHERE external_order_id = 'YO-794063';

-- Status 'delivered' ve source 'yemek_app' ise webhook GiTMELi!

-- ======================================================================
-- 2. YEMEK APP EDGE FUNCTiON LOGLARINI KONTROL ET
-- ======================================================================

/*
Supabase Dashboard:
1. Logs & Analytics
2. **Edge Functions** sekmesi (Database değil!)
3. Filtre: "onlog-status-update" fonksiyonu seç
4. Zaman: Last 1 hour
5. Ara: "YO-794063" veya "delivered"

BEKLENEN:
✅ POST /functions/v1/onlog-status-update
✅ Body: {"external_order_id":"YO-794063","status":"delivered",...}
✅ Response: 200 OK

veya

❌ 404 / 500 hata kodu
*/

-- ======================================================================
-- 3. HTTP EXTENSION AKTiF Mi?
-- ======================================================================

-- net.http_post fonksiyonu çalışıyor mu kontrol et
SELECT * FROM pg_available_extensions 
WHERE name = 'http';

-- Kurulu mu?
SELECT * FROM pg_extension 
WHERE extname = 'http';

-- ======================================================================
-- 4. MANUEL WEBHOOK TESTi - HTTP iSTEGi GÖNDER
-- ======================================================================

-- Webhook URL'ini ve payload'u test et
DO $$
DECLARE
  v_response RECORD;
  v_webhook_url TEXT := 'https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update';
  v_payload JSONB := jsonb_build_object(
    'delivery_id', 'c979945d-8a87-4210-a68d-a5cb3862ea4c',
    'external_order_id', 'YO-794063',
    'status', 'delivered',
    'status_message', 'TEST - Teslim edildi',
    'courier_name', 'Test Kurye',
    'courier_phone', '5551234567'
  );
BEGIN
  RAISE NOTICE 'Webhook URL: %', v_webhook_url;
  RAISE NOTICE 'Payload: %', v_payload;
  
  -- HTTP POST gönder
  SELECT * INTO v_response FROM net.http_post(
    url := v_webhook_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer default-key'
    ),
    body := v_payload::text
  );
  
  RAISE NOTICE 'HTTP Status: %', v_response.status;
  RAISE NOTICE 'HTTP Response: %', v_response.content;
  
  IF v_response.status >= 200 AND v_response.status < 300 THEN
    RAISE NOTICE '✅ Webhook başarılı!';
  ELSE
    RAISE WARNING '❌ Webhook başarısız! Status: %', v_response.status;
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ HTTP istegi hatası: %', SQLERRM;
END $$;

-- ======================================================================
-- 5. WEBHOOK LOGS TABLOSU OLUŞTUR (OPSiYONEL)
-- ======================================================================

-- Eğer webhook loglarını görmek istiyorsan tablo oluştur
CREATE TABLE IF NOT EXISTS webhook_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID REFERENCES delivery_requests(id),
  external_order_id TEXT,
  platform TEXT,
  webhook_url TEXT,
  payload JSONB,
  http_status INTEGER,
  response_body JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index ekle
CREATE INDEX IF NOT EXISTS idx_webhook_logs_external_order 
ON webhook_logs(external_order_id);

CREATE INDEX IF NOT EXISTS idx_webhook_logs_created_at 
ON webhook_logs(created_at DESC);

-- Mevcut webhook loglarını kontrol et
SELECT 
  external_order_id,
  platform,
  http_status,
  created_at,
  payload->>'status' as status
FROM webhook_logs
WHERE external_order_id = 'YO-794063'
ORDER BY created_at DESC
LIMIT 10;

-- ======================================================================
-- SONUÇ
-- ======================================================================

SELECT 
  'Webhook çalışıyor mu?' AS soru,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM delivery_requests 
      WHERE external_order_id = 'YO-794063' 
        AND status = 'delivered'
        AND source = 'yemek_app'
    ) THEN '✅ Webhook GiTMELi (Yemek App Edge Function loglarını kontrol et)'
    ELSE '⚠️ Sipariş delivered değil veya source yemek_app değil'
  END AS durum;
