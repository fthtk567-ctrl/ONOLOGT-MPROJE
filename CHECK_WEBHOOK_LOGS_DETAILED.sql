-- ======================================================================
-- WEBHOOK LOGLARINI DETAYLI KONTROL ET
-- ======================================================================
-- YO-794063 siparişi için webhook gönderildi mi?
-- ======================================================================

-- 1. Siparişin mevcut durumunu kontrol et
SELECT 
  id,
  external_order_id,
  order_number,
  status,
  courier_id,
  rejection_count,
  created_at,
  updated_at
FROM delivery_requests
WHERE external_order_id = 'YO-794063'
ORDER BY created_at DESC
LIMIT 1;

-- 2. Siparişin durum değişiklik geçmişi
SELECT 
  id,
  external_order_id,
  status,
  courier_id,
  updated_at
FROM delivery_requests
WHERE external_order_id = 'YO-794063'
ORDER BY updated_at DESC;

-- 3. Webhook trigger aktif mi?
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_notify_platform_on_status_change';

-- 4. Webhook fonksiyonunun içeriğini kontrol et
SELECT 
  proname AS function_name,
  prosrc AS function_body
FROM pg_proc
WHERE proname = 'notify_external_platform_on_status_change';

-- 5. Son 10 webhook için PostgreSQL log kontrolü
-- NOT: Bu sadece RAISE NOTICE mesajlarını gösterir
-- Gerçek HTTP POST logları Supabase Dashboard > Logs > Database'de

-- 6. Eğer webhook_logs tablosu varsa (opsiyonel)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'webhook_logs') THEN
    EXECUTE '
      SELECT 
        id,
        delivery_id,
        external_order_id,
        status,
        webhook_url,
        response_status,
        created_at
      FROM webhook_logs
      WHERE external_order_id = ''YO-794063''
      ORDER BY created_at DESC
      LIMIT 5
    ';
  ELSE
    RAISE NOTICE 'webhook_logs tablosu bulunamadı (opsiyonel özellik)';
  END IF;
END $$;

-- ======================================================================
-- MANÜELLİ STATUS DEĞİŞTİRME TEST
-- ======================================================================

-- Eğer webhook test etmek istersen:
/*
-- Status'u 'accepted' yap
UPDATE delivery_requests
SET 
  status = 'accepted',
  courier_id = (SELECT id FROM users WHERE role = 'courier' LIMIT 1)
WHERE external_order_id = 'YO-794063';

-- Sonra Supabase Dashboard > Logs > Database'de şu mesajları ara:
-- "[Webhook] Sending webhook for delivery..."
-- "[Webhook] Webhook sent successfully..."
-- veya
-- "[Webhook] Webhook failed..."
*/

-- ======================================================================
-- SUPABASE DASHBOARD'DA LOG KONTROLÜ
-- ======================================================================
/*
1. Supabase Dashboard'a git: https://supabase.com/dashboard/project/o11ldfywtzbrmpy1xx

2. Sol menüden "Logs" > "Database" seç

3. Arama kutusuna şunları yaz:
   - "Webhook" (case-insensitive)
   - "YO-794063"
   - "notify_external_platform"

4. Zaman filtresi: Son 1 saat

5. Beklenen log mesajları:
   ✅ "[Webhook] Sending webhook for delivery: <ID>"
   ✅ "[Webhook] Payload: {...}"
   ✅ "[Webhook] Webhook sent successfully"
   
   veya
   
   ❌ "[Webhook] Skipping webhook for status: pending"
   ❌ "[Webhook] Skipping webhook for status: assigned"
   ❌ "[Webhook] Webhook failed: ..."

ÖNEMLI: Webhook sadece şu status'larda gider:
- accepted
- picked_up
- delivered
- cancelled

pending ve assigned status'ları webhook göndermez!
*/
