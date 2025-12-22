-- ========================================================
-- COURIER AUTO NOTIFICATION - Kuryelere Otomatik Bildirim
-- ========================================================
-- Yeni teslimat atandığında veya durum değiştiğinde
-- kuryeye otomatik push notification gönderir
-- ========================================================

-- 1. Edge Function URL'ini kaydet (Supabase Functions kullanacağız)
-- Not: Supabase Edge Function create ettikten sonra URL'yi buraya yazın

-- 2. HTTP Extension'ı etkinleştir (Supabase Dashboard'dan yapılmalı)
-- Dashboard → Database → Extensions → http → Enable

-- 3. Bildirim gönderme fonksiyonu
CREATE OR REPLACE FUNCTION send_courier_notification(
  p_courier_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
  v_fcm_token TEXT;
  v_response TEXT;
BEGIN
  -- Kuryenin FCM token'ını al
  SELECT fcm_token INTO v_fcm_token
  FROM users
  WHERE id = p_courier_id AND role = 'courier';
  
  IF v_fcm_token IS NULL THEN
    RAISE NOTICE 'Kurye FCM token bulunamadı: %', p_courier_id;
    RETURN FALSE;
  END IF;
  
  -- FCM API'ye istek gönder
  BEGIN
    -- NOT: Supabase Edge Function kullanmalısınız
    -- Bu örnek direkt FCM API çağrısı (production'da Edge Function kullanın)
    
    RAISE NOTICE 'Bildirim gönderiliyor: % -> %', p_title, v_fcm_token;
    
    -- Alternatif: notifications tablosuna kaydet, başka bir servis göndersin
    INSERT INTO notifications (
      user_id,
      title,
      body,
      data,
      fcm_token,
      notification_status
    ) VALUES (
      p_courier_id,
      p_title,
      p_body,
      p_data,
      v_fcm_token,
      'pending'
    );
    
    RETURN TRUE;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Bildirim gönderme hatası: %', SQLERRM;
    RETURN FALSE;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Yeni teslimat atandığında bildirim gönder
CREATE OR REPLACE FUNCTION notify_courier_new_delivery()
RETURNS TRIGGER AS $$
BEGIN
  -- Sadece teslimat atandığında çalış
  IF (TG_OP = 'UPDATE' AND OLD.courier_id IS NULL AND NEW.courier_id IS NOT NULL)
     OR (TG_OP = 'INSERT' AND NEW.courier_id IS NOT NULL) THEN
    
    PERFORM send_courier_notification(
      NEW.courier_id,
      '🚚 Yeni Teslimat Ataması',
      COALESCE(NEW.declared_amount::TEXT, '0') || ' TL değerinde yeni bir teslimat atandı!',
      jsonb_build_object(
        'type', 'new_delivery',
        'delivery_id', NEW.id,
        'merchant_id', NEW.merchant_id,
        'package_count', NEW.package_count,
        'declared_amount', COALESCE(NEW.declared_amount, 0),
        'status', NEW.status
      )
    );
    
    RAISE NOTICE 'Kurye bildirim gönderildi: %', NEW.courier_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger oluştur
DROP TRIGGER IF EXISTS trigger_notify_courier_new_delivery ON delivery_requests;
CREATE TRIGGER trigger_notify_courier_new_delivery
  AFTER INSERT OR UPDATE OF courier_id ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_courier_new_delivery();

-- 6. Teslimat durumu değiştiğinde bildirim
CREATE OR REPLACE FUNCTION notify_courier_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Status değişti ve courier atanmış
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status AND NEW.courier_id IS NOT NULL THEN
    
    -- Duruma göre mesaj
    CASE NEW.status
      WHEN 'accepted' THEN
        PERFORM send_courier_notification(
          NEW.courier_id,
          '✅ Teslimat Kabul Edildi',
          'Teslimatı başarıyla kabul ettiniz. Ürünü almaya gidebilirsiniz.',
          jsonb_build_object('type', 'status_change', 'delivery_id', NEW.id, 'status', NEW.status)
        );
      WHEN 'picked_up' THEN
        PERFORM send_courier_notification(
          NEW.courier_id,
          '📦 Ürün Alındı',
          'Ürünü aldınız. Şimdi müşteriye teslim edebilirsiniz.',
          jsonb_build_object('type', 'status_change', 'delivery_id', NEW.id, 'status', NEW.status)
        );
      WHEN 'completed' THEN
        PERFORM send_courier_notification(
          NEW.courier_id,
          '🎉 Teslimat Tamamlandı',
          COALESCE(NEW.courier_payment_due::TEXT, '0') || ' TL kazandınız!',
          jsonb_build_object('type', 'status_change', 'delivery_id', NEW.id, 'status', NEW.status, 'earning', COALESCE(NEW.courier_payment_due, 0))
        );
      ELSE
        -- Diğer durum değişiklikleri
        NULL;
    END CASE;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Status trigger
DROP TRIGGER IF EXISTS trigger_notify_courier_status_change ON delivery_requests;
CREATE TRIGGER trigger_notify_courier_status_change
  AFTER UPDATE OF status ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_courier_status_change();

-- 8. Notifications tablosu (henüz yoksa)
-- Önce var mı kontrol et
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN
        CREATE TABLE notifications (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id),
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          data JSONB DEFAULT '{}'::jsonb,
          fcm_token TEXT,
          notification_status TEXT DEFAULT 'pending' CHECK (notification_status IN ('pending', 'sent', 'failed')),
          sent_at TIMESTAMPTZ,
          error_message TEXT,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
    ELSE
        -- Tablo varsa, notification_status kolonunu ekle (yoksa)
        IF NOT EXISTS (SELECT FROM information_schema.columns 
                       WHERE table_name = 'notifications' AND column_name = 'notification_status') THEN
            ALTER TABLE notifications ADD COLUMN notification_status TEXT DEFAULT 'pending' CHECK (notification_status IN ('pending', 'sent', 'failed'));
        END IF;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(notification_status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

-- ========================================================
-- TEST
-- ========================================================
-- Test bildirim gönder:
-- SELECT send_courier_notification(
--   'KURYE_USER_ID'::UUID,
--   'Test Bildirim',
--   'Bu bir test bildirimidir',
--   '{"test": true}'::jsonb
-- );

COMMENT ON FUNCTION send_courier_notification IS 'Kuryeye push notification gönderir';
COMMENT ON FUNCTION notify_courier_new_delivery IS 'Yeni teslimat atandığında kurye bildirilir';
COMMENT ON FUNCTION notify_courier_status_change IS 'Teslimat durumu değiştiğinde kurye bildirilir';
COMMENT ON TABLE notifications IS 'Gönderilen bildirimler logu';
