-- ======================================================================
-- GÖREV 5: WEBHOOK SİGNATURE GÜVENLİĞİ
-- Webhook'lara HMAC-SHA256 imza ekleme (güvenlik artırma)
-- ======================================================================
-- Tarih: 17 Kasım 2025
-- Kullanım: Supabase Dashboard → SQL Editor → Yeni sorgu → Bu kodu yapıştır → Run
-- Not: YEMEK_APP_ENTEGRASYON.sql'deki notify_external_platform fonksiyonunu güncelliyor
-- ======================================================================

-- 1. Mevcut notify_external_platform_on_status_change() fonksiyonunu güncelle
CREATE OR REPLACE FUNCTION notify_external_platform_on_status_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  webhook_secret TEXT;
  payload JSONB;
  signature TEXT;
  http_response RECORD;
  courier_info RECORD;
BEGIN
  -- Saddle harici platformlardan gelen siparişler için çalış
  IF NEW.source IS NOT NULL AND NEW.source != 'manual' THEN
    
    -- Platform'a göre webhook URL ve secret belirle
    CASE NEW.source
      WHEN 'yemek_app' THEN
        -- ⚠️ Gerçek URL Yemek App ekibi tarafından verilecek
        webhook_url := 'https://YEMEK_APP_PROJECT.supabase.co/functions/v1/onlog-status-update';
        webhook_secret := 'yemek_app_webhook_secret_2025'; -- ⚠️ Güvenli yerde sakla!
      
      WHEN 'trendyol' THEN
        webhook_url := 'https://api.trendyol.com/webhook/delivery-status';
        webhook_secret := 'trendyol_webhook_secret';
      
      WHEN 'getir' THEN
        webhook_url := 'https://api.getir.com/webhook/delivery-status';
        webhook_secret := 'getir_webhook_secret';
      
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
      
      -- Payload oluştur
      payload := jsonb_build_object(
        'delivery_id', NEW.id,
        'external_order_id', NEW.external_order_id,
        'status', NEW.status,
        'courier_id', NEW.courier_id,
        'courier_name', courier_info.owner_name,
        'courier_phone', courier_info.phone,
        'updated_at', NEW.updated_at,
        'source', NEW.source,
        'timestamp', extract(epoch from now())::bigint -- Unix timestamp
      );
      
      -- ⭐ HMAC-SHA256 İmza Oluştur
      signature := encode(
        hmac(payload::text, webhook_secret, 'sha256'),
        'hex'
      );
      
      RAISE NOTICE '[Webhook] Sending to % with signature %...', 
        NEW.source, substring(signature from 1 for 16);
      
      -- HTTP POST gönder (pg_net extension kullanılmalı)
      BEGIN
        SELECT * INTO http_response FROM net.http_post(
          url := webhook_url,
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'X-Onlog-Source', 'onlog_webhook',
            'X-Onlog-Event', 'delivery_status_changed',
            'X-Onlog-Signature', signature, -- ⭐ HMAC imza
            'X-Onlog-Timestamp', extract(epoch from now())::text, -- ⭐ Replay attack önleme
            'X-Onlog-Delivery-Id', NEW.id::text,
            'User-Agent', 'ONLOG-Webhook/1.0'
          ),
          body := payload::text,
          timeout_milliseconds := 5000 -- 5 saniye timeout
        );
        
        IF http_response.status >= 200 AND http_response.status < 300 THEN
          RAISE NOTICE '[Webhook] Success: % for delivery % (HTTP %)', 
            NEW.source, NEW.id, http_response.status;
        ELSE
          RAISE WARNING '[Webhook] Failed: % for delivery % (HTTP %)', 
            NEW.source, NEW.id, http_response.status;
        END IF;
        
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[Webhook] Error for %: %', NEW.source, SQLERRM;
      END;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger zaten var (YEMEK_APP_ENTEGRASYON.sql'de oluşturuldu)
-- Fonksiyon güncellendiği için otomatik yeni kodu kullanacak

-- 3. Doğrulama
SELECT 
  routine_name,
  routine_type,
  security_type
FROM information_schema.routines
WHERE routine_name = 'notify_external_platform_on_status_change';

COMMIT;

-- ======================================================================
-- YEMEK APP EKİBİNE VERİLECEK BİLGİLER
-- ======================================================================

-- ⭐ Webhook Secret (imza doğrulama için):
-- yemek_app_webhook_secret_2025

-- ⭐ İmza Doğrulama Kodu (TypeScript - Yemek App Edge Function'da):
/*
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts"

serve(async (req) => {
  const receivedSignature = req.headers.get('x-onlog-signature')
  const timestamp = req.headers.get('x-onlog-timestamp')
  const secret = 'yemek_app_webhook_secret_2025'
  
  const body = await req.text()
  
  // HMAC-SHA256 imza hesapla
  const expectedSignature = createHmac('sha256', secret)
    .update(body)
    .digest('hex')
  
  // İmza doğrulama
  if (receivedSignature !== expectedSignature) {
    console.error('[Security] Invalid webhook signature')
    return new Response(
      JSON.stringify({ error: 'Invalid signature' }), 
      { status: 401 }
    )
  }
  
  // Replay attack önleme (5 dakikadan eski istekleri reddet)
  const now = Date.now() / 1000
  const requestTime = parseInt(timestamp || '0')
  if (Math.abs(now - requestTime) > 300) { // 5 dakika
    console.error('[Security] Request too old')
    return new Response(
      JSON.stringify({ error: 'Request expired' }), 
      { status: 401 }
    )
  }
  
  // İmza geçerli, webhook'u işle
  const payload = JSON.parse(body)
  console.log('[Webhook] Valid request:', payload.external_order_id)
  
  // ... işlem devam eder
  
  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
*/

-- ======================================================================
-- TEST KOMUTLARI
-- ======================================================================

-- Test 1: Mevcut bir delivery'nin statusunu değiştir (webhook tetiklenmeli)
/*
UPDATE delivery_requests
SET status = 'picked_up'
WHERE external_order_id = 'YO-TEST-001' AND source = 'yemek_app';
-- Supabase Logs'ta "[Webhook] Sending to yemek_app with signature..." göreceksin
*/

-- Test 2: İmza doğrulama (Manuel test - PostgreSQL'de)
/*
SELECT encode(
  hmac('{"test": "data"}'::text, 'yemek_app_webhook_secret_2025', 'sha256'),
  'hex'
) as test_signature;
-- Bu signature'ı Yemek App ekibi ile karşılaştırabilirsin
*/

-- Test 3: Webhook log'larını kontrol et
-- Dashboard → Logs → Database → Filter: "Webhook"

-- ======================================================================
-- GÜVENLİK ÖNERİLERİ
-- ======================================================================
-- 1. ✅ HMAC-SHA256 imza kullanıldı
-- 2. ✅ Timestamp eklendi (replay attack önleme)
-- 3. ✅ HTTPS zorunlu (webhook URL'ler https://)
-- 4. ⚠️ webhook_secret'i Supabase Vault'a taşı (production için):
--    SELECT vault.create_secret('yemek_app_webhook_secret_2025');
-- 5. ⚠️ IP whitelist ekle (Yemek App'in IP'lerini al)
-- 6. ⚠️ Rate limiting uygula (dakikada max X webhook)
-- ======================================================================

-- ======================================================================
-- SORUN GİDERME
-- ======================================================================
-- Sorun: "function hmac does not exist"
-- Çözüm: CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Sorun: "function net.http_post does not exist"
-- Çözüm: CREATE EXTENSION IF NOT EXISTS pg_net;

-- Sorun: Webhook gönderilmiyor
-- Çözüm: 
--   1. Trigger var mı? SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_external_platform';
--   2. Fonksiyon doğru mu? SELECT prosrc FROM pg_proc WHERE proname = 'notify_external_platform_on_status_change';
--   3. pg_net aktif mi? SELECT * FROM pg_extension WHERE extname = 'pg_net';
-- ======================================================================
