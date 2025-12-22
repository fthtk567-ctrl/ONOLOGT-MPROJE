-- EDGE FUNCTION TRIGGER'INI GERİ EKLE

-- notifications tablosuna yeni kayıt eklendiğinde Edge Function çağır
CREATE OR REPLACE FUNCTION trigger_fcm_edge_function()
RETURNS TRIGGER AS $$
BEGIN
  -- Edge Function'ı çağır - SADECE YENİ EKLENEN notification ID'sini gönder
  PERFORM net.http_post(
    url := 'https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/send-fcm-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY3MjgyOSwiZXhwIjoyMDc2MjQ4ODI5fQ.-_kJYS1oba6vsC4OuTccK9gAVLySigjCI_pHOuvtHt0'
    ),
    body := jsonb_build_object('notification_id', NEW.id)
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger ekle
DROP TRIGGER IF EXISTS on_notification_insert_trigger ON notifications;

CREATE TRIGGER on_notification_insert_trigger
AFTER INSERT ON notifications
FOR EACH ROW
WHEN (NEW.notification_status = 'pending')
EXECUTE FUNCTION trigger_fcm_edge_function();

-- Kontrol
SELECT 
    trigger_name,
    event_object_table,
    action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_notification_insert_trigger';
