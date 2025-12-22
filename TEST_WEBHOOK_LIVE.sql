-- ======================================================================
-- WEBHOOK'U CANLI TEST ET - YO-794063
-- ======================================================================
-- Mevcut status: delivered
-- Plan: Status'u picked_up → delivered yaparak webhook'u tetikle
-- Sonra Database logs'da gerçek zamanlı izle
-- ======================================================================

-- 1. Önce mevcut durumu kaydet
SELECT 
  id,
  external_order_id,
  status,
  courier_id,
  updated_at
FROM delivery_requests
WHERE external_order_id = 'YO-794063';

-- 2. Webhook fonksiyonunun RAISE NOTICE kullanıp kullanmadığını kontrol et
SELECT pg_get_functiondef(p.oid)
FROM pg_proc p
WHERE p.proname = 'notify_external_platform_on_status_change';

-- 3. Status'u picked_up'a çek (webhook GİTMEMELİ - test için)
UPDATE delivery_requests
SET 
  status = 'picked_up',
  updated_at = NOW()
WHERE external_order_id = 'YO-794063';

-- ⏱️ 3 saniye bekle...

-- 4. Status'u delivered yap (webhook GİTMELİ! 🚀)
UPDATE delivery_requests
SET 
  status = 'delivered',
  delivered_at = NOW(),
  updated_at = NOW()
WHERE external_order_id = 'YO-794063';

-- ✅ ŞİMDİ HEMEN:
-- 1. Supabase Dashboard > Logs & Analytics > Database
-- 2. Arama kutusuna: "YO-794063" veya "webhook"
-- 3. Zaman filtresi: "Last 5 minutes"
-- 4. Refresh butonuna bas (yenile)

-- BEKLENEN LOGLAR (5-10 saniye içinde):
/*
[Webhook] Processing status change for delivery: <UUID>
[Webhook] External order ID: YO-794063
[Webhook] New status: delivered
[Webhook] Sending webhook to: https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update
[Webhook] Payload: {"delivery_id":"...","external_order_id":"YO-794063","status":"delivered",...}
[Webhook] HTTP Response: 200 OK
[Webhook] Webhook sent successfully
*/

-- ======================================================================
-- EĞER HALA LOG GÖRMÜYORSAN
-- ======================================================================

-- Fonksiyonda RAISE NOTICE eksik olabilir - kontrol et:
SELECT 
  proname,
  prosrc
FROM pg_proc
WHERE proname = 'notify_external_platform_on_status_change';

-- Fonksiyon içinde şu satırlar OLMALI:
/*
RAISE NOTICE '[Webhook] Processing status change for delivery: %', NEW.id;
RAISE NOTICE '[Webhook] External order ID: %', v_external_order_id;
RAISE NOTICE '[Webhook] Webhook sent successfully';
*/

-- YOKSA: FIX_YEMEK_APP_WEBHOOK_TIMING.sql dosyasını tekrar çalıştır!
