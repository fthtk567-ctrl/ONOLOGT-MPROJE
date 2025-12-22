-- ======================================================================
-- WEBHOOK TEST - Manuel Trigger
-- ======================================================================
-- Mevcut siparişi 'accepted' yaparak webhook'u tetikleyelim
-- ======================================================================

-- 1. Son Yemek App siparişini bul
SELECT 
  id,
  external_order_id,
  status,
  courier_id,
  source,
  created_at
FROM delivery_requests
WHERE source = 'yemek_app'
ORDER BY created_at DESC
LIMIT 1;

-- 2. Eğer status 'assigned' ise, 'accepted' yap (webhook tetiklenecek)
UPDATE delivery_requests
SET status = 'accepted'
WHERE source = 'yemek_app'
  AND status = 'assigned'
  AND id = (
    SELECT id FROM delivery_requests 
    WHERE source = 'yemek_app' 
    ORDER BY created_at DESC 
    LIMIT 1
  );

-- 3. Supabase Logs'u kontrol et
-- Dashboard → Logs → Database Logs
-- Arama: "[Webhook]"
-- 
-- Göreceksiniz:
-- ✅ [Webhook] Status update sent to yemek_app for order YO-...: status=accepted
-- VEYA
-- ❌ [Webhook] HTTP request failed for yemek_app: ...
