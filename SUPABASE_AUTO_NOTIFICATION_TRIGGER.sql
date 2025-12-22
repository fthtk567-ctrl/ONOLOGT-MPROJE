-- ============================================
-- ONLOG OTOMATIK BİLDİRİM SİSTEMİ
-- Merchant teslimat oluşturduğunda otomatik FCM gönderir
-- ============================================

-- 1. SUPABASE VAULT'A FCM SERVICE ACCOUNT EKLE
-- Supabase Dashboard > Project Settings > Vault > Secrets
-- Secret adı: FCM_SERVICE_ACCOUNT
-- Value: c:\Users\PC\Downloads\onlog-push-firebase-adminsdk-fbsvc-787041d780.json içeriğini yapıştır

-- 2. EDGE FUNCTION ÇAĞIRAN TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION notify_courier_on_delivery_assigned()
RETURNS TRIGGER AS $$
DECLARE
  v_courier_token TEXT;
  v_merchant_name TEXT;
  v_delivery_address TEXT;
  v_response TEXT;
BEGIN
  -- Sadece kurye atandığında çalış
  IF NEW.courier_id IS NOT NULL AND (OLD.courier_id IS NULL OR OLD.courier_id != NEW.courier_id) THEN
    
    -- Kurye FCM token'ını al
    SELECT fcm_token INTO v_courier_token
    FROM user_fcm_tokens
    WHERE user_id = NEW.courier_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Token yoksa çık
    IF v_courier_token IS NULL THEN
      RAISE NOTICE 'Kurye FCM token bulunamadı: %', NEW.courier_id;
      RETURN NEW;
    END IF;
    
    -- Merchant bilgisini al
    SELECT COALESCE(business_name, owner_name, 'Merchant') INTO v_merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Teslimat adresi (delivery_location kolonu yoksa basit mesaj)
    v_delivery_address := 'Yeni teslimat';
    
    -- Supabase Edge Function çağır (net.http extension gerekli)
    -- VEYA basit notification_queue tablosuna kaydet
    INSERT INTO notification_queue (
      user_id,
      fcm_token,
      title,
      body,
      data,
      status
    ) VALUES (
      NEW.courier_id,
      v_courier_token,
      '🚀 Yeni Teslimat İsteği!',
      v_merchant_name || ' - ' || v_delivery_address,
      json_build_object(
        'type', 'new_delivery_request',
        'delivery_request_id', NEW.id,
        'merchant_id', NEW.merchant_id,
        'merchant_name', v_merchant_name
      ),
      'pending'
    );
    
    RAISE NOTICE '✅ Bildirim kuyruğa eklendi: % -> %', v_merchant_name, NEW.courier_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. TRIGGER OLUŞTUR
DROP TRIGGER IF EXISTS trigger_notify_courier ON delivery_requests;
CREATE TRIGGER trigger_notify_courier
  AFTER INSERT OR UPDATE ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_courier_on_delivery_assigned();

-- 4. NOTIFICATION QUEUE TABLOSU (yoksa oluştur)
CREATE TABLE IF NOT EXISTS notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  fcm_token TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  processed_at TIMESTAMPTZ
);

-- Index
CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_notification_queue_created ON notification_queue(created_at);

-- RLS
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;

-- Admin all access
CREATE POLICY "Admin can manage notifications"
  ON notification_queue
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- 5. TEST
SELECT '✅ Otomatik bildirim sistemi kuruldu!' as message;
