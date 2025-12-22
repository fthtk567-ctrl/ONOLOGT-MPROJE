-- Notifications tablosu oluştur
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('delivery', 'payment', 'reminder', 'system')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index'ler ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- RLS (Row Level Security) politikaları
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi bildirimlerini görebilir
CREATE POLICY "Users can view their own notifications"
    ON notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- Kullanıcılar kendi bildirimlerini güncelleyebilir (okundu işareti için)
CREATE POLICY "Users can update their own notifications"
    ON notifications
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Kullanıcılar kendi bildirimlerini silebilir
CREATE POLICY "Users can delete their own notifications"
    ON notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- Sistem/admin tarafından bildirim oluşturma için (service role)
CREATE POLICY "Service role can insert notifications"
    ON notifications
    FOR INSERT
    WITH CHECK (true);

-- Test verileri ekle (opsiyonel)
INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
SELECT 
    id,
    'Hoş Geldiniz! 🎉',
    'OnLog Kurye uygulamasına hoş geldiniz. İyi kazançlar dileriz!',
    'system',
    false,
    NOW() - INTERVAL '1 hour'
FROM auth.users
WHERE email = 'courier@onlog.com'
ON CONFLICT DO NOTHING;

INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
SELECT 
    id,
    'Yeni Teslimat Fırsatı',
    'Bölgenizde 3 yeni teslimat görevi mevcut. Hemen inceleyin!',
    'delivery',
    false,
    NOW() - INTERVAL '30 minutes'
FROM auth.users
WHERE email = 'courier@onlog.com'
ON CONFLICT DO NOTHING;

INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
SELECT 
    id,
    'Ödeme Bildirimi',
    'Haftalık kazancınız olan 450₺ hesabınıza aktarılmıştır.',
    'payment',
    true,
    NOW() - INTERVAL '2 days'
FROM auth.users
WHERE email = 'courier@onlog.com'
ON CONFLICT DO NOTHING;

INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
SELECT 
    id,
    'Hatırlatma',
    'Bugün tamamlamanız gereken 2 teslimat bulunmaktadır.',
    'reminder',
    true,
    NOW() - INTERVAL '3 days'
FROM auth.users
WHERE email = 'courier@onlog.com'
ON CONFLICT DO NOTHING;

COMMENT ON TABLE notifications IS 'Kullanıcı bildirimleri tablosu';
COMMENT ON COLUMN notifications.type IS 'Bildirim tipi: delivery, payment, reminder, system';
COMMENT ON COLUMN notifications.is_read IS 'Bildirim okundu mu?';
