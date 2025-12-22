-- ======================================================================
-- YO-794063 SİPARİŞİ İÇİN WEBHOOK LOGLARINI BUL
-- ======================================================================
-- Status: delivered ✅
-- Webhook GİTMİŞ OLMALI!
-- ======================================================================

-- 1. Siparişin tam detaylarını göster
SELECT 
  id,
  external_order_id,
  order_number,
  status,
  courier_id,
  rejection_count,
  created_at,
  updated_at,
  delivered_at
FROM delivery_requests
WHERE external_order_id = 'YO-794063';

-- 2. Webhook trigger'ın çalıştığını doğrula
-- NOT: Bu sorguyu Supabase Dashboard > Logs > Database'de çalıştırman gerekiyor
-- Çünkü postgres_logs sadece orada görünüyor

-- Supabase Dashboard'da şunu ara:
-- 
-- Logs & Analytics > Database sekmesi
-- 
-- Arama kutusuna yaz:
-- "YO-794063"
-- veya
-- "webhook"
-- veya
-- "notify_external_platform"

-- 3. Beklenen log mesajları (Database logs'da):
/*
[Webhook] Processing status change for delivery: <UUID>
[Webhook] External order ID: YO-794063
[Webhook] Status: delivered
[Webhook] Sending webhook for delivery: <UUID>
[Webhook] Webhook URL: https://avpbrcqbhxyctmwnxtmm.supabase.co/functions/v1/onlog-status-update
[Webhook] Payload: {"delivery_id":"...","external_order_id":"YO-794063","status":"delivered",...}
[Webhook] Webhook sent successfully
[Webhook] Response status: 200
*/

-- 4. Eğer webhook BAŞARISIZ olduysa:
/*
[Webhook] Webhook failed: <hata mesajı>
[Webhook] Error details: ...
*/

-- ======================================================================
-- MANİPÜLASYON TARİHİNİ KONTROL ET
-- ======================================================================

-- Status ne zaman 'delivered' oldu?
SELECT 
  external_order_id,
  status,
  updated_at AS status_changed_at,
  NOW() AS current_time,
  AGE(NOW(), updated_at) AS time_since_delivery
FROM delivery_requests
WHERE external_order_id = 'YO-794063';

-- Eğer 1 saatten önce delivered olduysa ve Database logs'da log göremiyorsan:
-- → Trigger çalışmamış olabilir (kontrol et)
-- → Veya log retention süresi dolmuş olabilir

-- ======================================================================
-- TRİGGER KONTROLÜ
-- ======================================================================

SELECT 
  t.trigger_name,
  t.event_manipulation,
  t.event_object_table,
  t.action_timing,
  t.action_statement
FROM information_schema.triggers t
WHERE t.trigger_name = 'trigger_notify_platform_on_status_change'
  AND t.event_object_table = 'delivery_requests';

-- Trigger yoksa → SQL'i tekrar çalıştır: FIX_YEMEK_APP_WEBHOOK_TIMING.sql
-- Trigger varsa → Database logs'a bak

-- ======================================================================
-- WEBHOOK FONKS İYONUNU KONTROL ET
-- ======================================================================

SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_external_platform_on_status_change'
  AND n.nspname = 'public';

-- Fonksiyon içinde 'status IN (accepted, picked_up, delivered, cancelled)' kontrolü olmalı

-- ======================================================================
-- SUPABASE DASHBOARD'DA YAPILACAKLAR
-- ======================================================================
/*
1. Sol menüden: Logs & Analytics
2. Üst sekmeden: Database (Edge Functions DEĞİL!)
3. Sağ üstte zaman filtresi: "Last 24 hours" 
4. Arama kutusuna: "YO-794063"
5. Run Query

BEKLENEN SONUÇ:
✅ [Webhook] mesajları görmelisin
✅ "delivered" status için webhook gönderim logları olmalı
✅ HTTP response status (200, 201, veya hata kodu)

❌ Hiçbir şey görmüyorsan:
- Trigger çalışmamış olabilir
- Log retention süresi dolmuş olabilir (24+ saat önceyse)
- Fonksiyon RAISE NOTICE kullanmıyor olabilir
*/

-- ======================================================================
-- ACİL TEST: WEBHOOK'U TEKRAR TETİKLE
-- ======================================================================

-- Eğer log bulamıyorsan, status'u picked_up → delivered yap tekrar:
/*
-- Önce picked_up yap
UPDATE delivery_requests
SET status = 'picked_up'
WHERE external_order_id = 'YO-794063';

-- 5 saniye bekle, sonra delivered yap
UPDATE delivery_requests
SET status = 'delivered',
    delivered_at = NOW()
WHERE external_order_id = 'YO-794063';

-- Şimdi HEMEN Database logs'a git ve "YO-794063" ara
-- 5-10 saniye içinde webhook mesajları görmelisin
*/
