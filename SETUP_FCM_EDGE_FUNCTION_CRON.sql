-- ========================================================
-- FCM EDGE FUNCTION CRON JOB - Her 10 saniyede bir bildirim gönder
-- ========================================================

-- pg_cron extension'ı aktif mi kontrol et
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Mevcut cron job'ı temizle (varsa)
SELECT cron.unschedule('send-fcm-notifications');

-- Her 10 saniyede bir Edge Function'ı tetikle
SELECT cron.schedule(
  'send-fcm-notifications',       -- Job adı
  '*/10 * * * * *',                -- Her 10 saniye (cron expression)
  $$
  SELECT
    net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-fcm-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := '{}'::jsonb
    ) as request_id;
  $$
);

-- Alternatif: pg_net kullan (Supabase önerisi)
-- NOT: Yukarıdaki cron yerine bu trigger'ı kullanabilirsiniz

CREATE OR REPLACE FUNCTION trigger_fcm_edge_function()
RETURNS TRIGGER AS $$
BEGIN
  -- Yeni pending notification eklendiğinde Edge Function'ı çağır
  PERFORM
    net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-fcm-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
      ),
      body := '{}'::jsonb
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Yeni notification eklendiğinde Edge Function çağır
DROP TRIGGER IF EXISTS trigger_call_fcm_edge_function ON notifications;
CREATE TRIGGER trigger_call_fcm_edge_function
  AFTER INSERT ON notifications
  FOR EACH ROW
  WHEN (NEW.notification_status = 'pending')
  EXECUTE FUNCTION trigger_fcm_edge_function();

-- ========================================================
-- MANUEL TEST
-- ========================================================
-- Edge Function'ı manuel çağırmak için:
/*
SELECT
  net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-fcm-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := '{}'::jsonb
  ) as request_id;
*/

-- Cron job'ları görmek için:
-- SELECT * FROM cron.job;

-- Cron job loglarını görmek için:
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;

COMMENT ON FUNCTION trigger_fcm_edge_function IS 'Yeni bildirim eklendiğinde Edge Function çağırır';
