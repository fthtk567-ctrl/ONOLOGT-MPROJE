-- ===================================================================
-- ONLOG PUSH NOTIFICATION - FCM TOKEN MANAGEMENT
-- ===================================================================
-- Bu SQL script'i Supabase SQL Editor'de çalıştırın
-- FCM token'ları Supabase'de saklamak için
-- ===================================================================

-- ===================================================================
-- 1. USER_FCM_TOKENS TABLOSU
-- ===================================================================
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- User ilişkisi
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- FCM Token bilgileri
  fcm_token TEXT NOT NULL,
  device_type TEXT NOT NULL,  -- 'android', 'ios', 'web'
  device_id TEXT,              -- Cihaz unique ID
  device_name TEXT,            -- Örn: "Samsung Galaxy S21"
  app_version TEXT,            -- Uygulama versiyonu
  
  -- Durum
  is_active BOOLEAN DEFAULT true,
  
  -- Tarihler
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Token her cihaz için unique olmalı
  UNIQUE(user_id, fcm_token)
);

-- İndexler
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_active ON user_fcm_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_device_type ON user_fcm_tokens(device_type);

-- ===================================================================
-- 2. NOTIFICATION_HISTORY TABLOSU (Bildirim geçmişi)
-- ===================================================================
CREATE TABLE IF NOT EXISTS notification_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Alıcı bilgisi
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Bildirim içeriği
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  notification_type TEXT NOT NULL,  -- 'new_order', 'order_delivered', 'payment', 'general'
  
  -- İlişkili veri
  order_id TEXT,
  reference_id UUID,
  
  -- Payload (ekstra data)
  data JSONB DEFAULT '{}',
  
  -- Durum
  status TEXT DEFAULT 'sent',  -- 'sent', 'delivered', 'failed', 'read'
  
  -- FCM response
  fcm_message_id TEXT,
  fcm_response JSONB DEFAULT '{}',
  error_message TEXT,
  
  -- Tarihler
  created_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ
);

-- İndexler
CREATE INDEX IF NOT EXISTS idx_notification_history_user ON notification_history(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_history_type ON notification_history(notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_history_status ON notification_history(status);
CREATE INDEX IF NOT EXISTS idx_notification_history_created ON notification_history(created_at DESC);

-- ===================================================================
-- 3. RLS (ROW LEVEL SECURITY) POLİCİES
-- ===================================================================

ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;

-- FCM Tokens: Kullanıcılar sadece kendi token'larını görebilir/yönetebilir
CREATE POLICY "Users can manage own FCM tokens" ON user_fcm_tokens
  FOR ALL
  USING (auth.uid() = user_id);

-- Admin tüm token'ları görebilir
CREATE POLICY "Admin can view all FCM tokens" ON user_fcm_tokens
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Notification History: Kullanıcılar sadece kendi bildirimlerini görebilir
CREATE POLICY "Users can view own notifications" ON notification_history
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admin tüm bildirimleri görebilir
CREATE POLICY "Admin can view all notifications" ON notification_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===================================================================
-- 4. UPDATED_AT TRIGGER (Otomatik timestamp güncelleme)
-- ===================================================================

CREATE OR REPLACE FUNCTION update_fcm_token_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fcm_token_timestamp
  BEFORE UPDATE ON user_fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_fcm_token_timestamp();

-- ===================================================================
-- 5. HELPER FUNCTIONS
-- ===================================================================

-- Token'ı güncelle veya yeni ekle (UPSERT)
CREATE OR REPLACE FUNCTION upsert_fcm_token(
  p_user_id UUID,
  p_fcm_token TEXT,
  p_device_type TEXT,
  p_device_id TEXT DEFAULT NULL,
  p_device_name TEXT DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_token_id UUID;
BEGIN
  -- Mevcut token'ı güncelle veya yeni ekle
  INSERT INTO user_fcm_tokens (
    user_id, fcm_token, device_type, device_id, device_name, app_version, 
    is_active, last_used_at
  )
  VALUES (
    p_user_id, p_fcm_token, p_device_type, p_device_id, p_device_name, p_app_version,
    true, NOW()
  )
  ON CONFLICT (user_id, fcm_token) 
  DO UPDATE SET
    is_active = true,
    last_used_at = NOW(),
    device_name = COALESCE(EXCLUDED.device_name, user_fcm_tokens.device_name),
    app_version = COALESCE(EXCLUDED.app_version, user_fcm_tokens.app_version),
    updated_at = NOW()
  RETURNING id INTO v_token_id;
  
  RETURN v_token_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Kullanıcının aktif token'larını getir
CREATE OR REPLACE FUNCTION get_user_fcm_tokens(p_user_id UUID)
RETURNS TABLE (
  fcm_token TEXT,
  device_type TEXT,
  device_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uft.fcm_token,
    uft.device_type,
    uft.device_name
  FROM user_fcm_tokens uft
  WHERE uft.user_id = p_user_id 
    AND uft.is_active = true
  ORDER BY uft.last_used_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Role göre kullanıcıların token'larını getir (admin kullanımı)
CREATE OR REPLACE FUNCTION get_tokens_by_role(p_role TEXT)
RETURNS TABLE (
  user_id UUID,
  fcm_token TEXT,
  device_type TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uft.user_id,
    uft.fcm_token,
    uft.device_type
  FROM user_fcm_tokens uft
  INNER JOIN public.users u ON u.id = uft.user_id
  WHERE u.role = p_role 
    AND uft.is_active = true
  ORDER BY uft.last_used_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- 6. DOĞRULAMA QUERY'LERİ
-- ===================================================================

-- Tabloları kontrol et
SELECT 
  tablename, 
  schemaname 
FROM pg_tables 
WHERE tablename IN ('user_fcm_tokens', 'notification_history');

-- RLS aktif mi kontrol et
SELECT 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE tablename IN ('user_fcm_tokens', 'notification_history');

-- Fonksiyonları kontrol et
SELECT 
  routine_name
FROM information_schema.routines
WHERE routine_name IN (
  'upsert_fcm_token',
  'get_user_fcm_tokens',
  'get_tokens_by_role'
);

COMMENT ON TABLE user_fcm_tokens IS 'FCM token storage for push notifications (Supabase + FCM only, no Firebase DB)';
COMMENT ON TABLE notification_history IS 'Push notification history and tracking';
