-- FCM Edge Function Trigger - Otomatik Bildirim Gönderimi
-- notifications tablosuna yeni 'pending' kayıt eklendiğinde Edge Function'ı çağırır

-- Edge Function'ı çağıran trigger function
CREATE OR REPLACE FUNCTION trigger_fcm_edge_function()
RETURNS TRIGGER AS $$
DECLARE
  request_id bigint;
BEGIN
  -- Sadece 'pending' status ile eklenen kayıtlar için çalış
  IF NEW.notification_status = 'pending' THEN
    
    -- pg_net kullanarak Edge Function'ı asenkron çağır
    SELECT net.http_post(
      'https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/send-fcm-notification'::text,
      json_build_object(
        'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY3MjgyOSwiZXhwIjoyMDc2MjQ4ODI5fQ.-_kJYS1oba6vsC4OuTccK9gAVLySigjCI_pHOuvtHt0',
        'Content-Type', 'application/json'
      )::json,
      (json_build_object(
        'notification_id', NEW.id
      ))::json::text
    ) INTO request_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger'ı notifications tablosuna bağla
DROP TRIGGER IF EXISTS on_notification_insert_trigger ON notifications;

CREATE TRIGGER on_notification_insert_trigger
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION trigger_fcm_edge_function();

-- Test için bilgi
SELECT 'FCM Edge Function Trigger başarıyla kuruldu!' as status;
