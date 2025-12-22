-- Database trigger'ı sil - Artık Flutter'dan direkt Edge Function çağırıyoruz
-- Bu dosyayı Supabase SQL Editor'de çalıştır

DROP TRIGGER IF EXISTS trigger_notify_courier_on_assign ON delivery_requests;
DROP FUNCTION IF EXISTS notify_courier_via_edge_function();

-- Kontrol: Trigger silindi mi?
SELECT trigger_name 
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_notify_courier_on_assign';
-- Sonuç: 0 rows (trigger silindi ✅)
