-- ======================================================================
-- WEBHOOK NEDEN LOG ÜRETMÝYOR?
-- ======================================================================

-- 1. Sipariş gerçekten güncellendi mi?
SELECT 
  id,
  external_order_id,
  status,
  source,
  courier_id,
  updated_at
FROM delivery_requests
WHERE external_order_id = 'YO-794063'
ORDER BY updated_at DESC
LIMIT 1;

-- 2. Trigger çalışıyor mu? (Test için basit log ekleyelim)
CREATE OR REPLACE FUNCTION test_trigger_working()
RETURNS TRIGGER AS $$
BEGIN
  RAISE NOTICE '🔥 TRIGGER ÇALIŞTI! Order: %, Old Status: %, New Status: %', 
    NEW.external_order_id, OLD.status, NEW.status;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Test trigger'ı ekle
DROP TRIGGER IF EXISTS test_trigger_working ON delivery_requests;

CREATE TRIGGER test_trigger_working
  BEFORE UPDATE OF status ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION test_trigger_working();

-- 3. Şimdi status'u değiştir ve log'u gör
UPDATE delivery_requests
SET status = 'accepted'
WHERE external_order_id = 'YO-794063';

-- Hemen Database logs'a git ve "TRIGGER ÇALIŞTI" ara
-- Eğer bu mesajı göremiyorsan: PostgreSQL logları Dashboard'da görünmüyor olabilir

-- 4. Test trigger'ı temizle
DROP TRIGGER IF EXISTS test_trigger_working ON delivery_requests;
DROP FUNCTION IF EXISTS test_trigger_working();

-- 5. Ana webhook trigger'ı kontrol et
SELECT 
  t.trigger_name,
  t.event_manipulation,
  t.action_timing,
  t.action_statement,
  t.event_object_table
FROM information_schema.triggers t
WHERE t.event_object_table = 'delivery_requests'
  AND t.trigger_name LIKE '%webhook%'
ORDER BY t.trigger_name;

-- ======================================================================
-- ALTERNATİF: PostgreSQL log_min_messages ayarını kontrol et
-- ======================================================================

-- PostgreSQL NOTICE mesajlarını gösteriyor mu?
SHOW log_min_messages;

-- Eğer 'warning' veya daha yüksekse, NOTICE mesajları loglanmaz
-- Supabase'de bu ayar genellikle sabit (değiştiremezsin)

-- ======================================================================
-- ALTERNATİF TEST: Webhook'u doğrudan çağır
-- ======================================================================

-- Manuel test: Webhook fonksiyonunu doğrudan çalıştıramazsın ama
-- Status'u değiştirip hemen kontrol edebilirsin

SELECT 
  'Test tamamlandı. Eğer Database logs boşsa:' AS sonuc,
  '1. Supabase Dashboard log retention çok kısa olabilir' AS neden_1,
  '2. RAISE NOTICE mesajları Supabase Dashboard''da görünmüyor olabilir' AS neden_2,
  '3. Trigger çalışıyor ama HTTP isteği sessizce başarısız olabilir' AS neden_3;
