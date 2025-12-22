-- SUPABASE DATABASE TRIGGER: Teslimat oluşunca notification_queue'ya ekle
-- Sonra başka bir servis bu queue'dan okuyup FCM gönderir

-- 1. Notification Queue Tablosu Oluştur
CREATE TABLE IF NOT EXISTS notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  notification_type TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- pending, sent, failed
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ
);

-- Index
CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_notification_queue_user ON notification_queue(user_id);

-- 2. Teslimat atandığında queue'ya ekleyen fonksiyon
CREATE OR REPLACE FUNCTION queue_courier_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_merchant_name TEXT;
  v_delivery_address TEXT;
  v_customer_name TEXT;
BEGIN
  -- Sadece courier_id atandığında çalış
  IF (TG_OP = 'UPDATE' AND NEW.courier_id IS NOT NULL AND 
      (OLD.courier_id IS NULL OR OLD.courier_id != NEW.courier_id)) THEN
    
    -- Merchant bilgisi
    SELECT COALESCE(business_name, owner_name, 'Merchant')
    INTO v_merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Teslimat bilgileri
    v_delivery_address := COALESCE(NEW.delivery_location->>'address', 'Adres bilgisi yok');
    v_customer_name := COALESCE(NEW.customer_name, 'Müşteri');
    
    -- Queue'ya ekle
    INSERT INTO notification_queue (
      user_id,
      title,
      body,
      data,
      notification_type,
      status
    ) VALUES (
      NEW.courier_id,
      '🚀 Yeni Teslimat İsteği!',
      v_merchant_name || ' - ' || v_delivery_address || ' - ' || v_customer_name,
      jsonb_build_object(
        'type', 'new_delivery_request',
        'delivery_request_id', NEW.id::TEXT,
        'order_id', COALESCE(NEW.order_id, NEW.id::TEXT),
        'merchant_name', v_merchant_name,
        'delivery_address', v_delivery_address,
        'customer_name', v_customer_name
      ),
      'new_order',
      'pending'
    );
    
    RAISE NOTICE '✅ Notification queue''ya eklendi: %', NEW.courier_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger oluştur
DROP TRIGGER IF EXISTS trigger_queue_courier_notification ON delivery_requests;

CREATE TRIGGER trigger_queue_courier_notification
  AFTER UPDATE OF courier_id ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION queue_courier_notification();

-- 4. RLS Policies
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see own notifications"
  ON notification_queue FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON notification_queue FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update notifications"
  ON notification_queue FOR UPDATE
  USING (true);

-- TEST: Şimdi merchant panel'den teslimat oluştur, bu tabloya kayıt düşecek!
-- SELECT * FROM notification_queue ORDER BY created_at DESC LIMIT 10;
