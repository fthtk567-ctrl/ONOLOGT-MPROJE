-- ============================================
-- NOTIFICATIONS TABLOSU İÇİN REALTIME AKTİFLEŞTİR
-- ============================================

-- 1. Realtime'ı aktif et (Supabase Dashboard'dan da yapabilirsiniz)
-- Dashboard > Database > Replication > notifications > Enable Realtime

-- 2. RLS politikalarını kontrol et
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Kullanıcı kendi bildirimlerini görebilir
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

-- Kullanıcı kendi bildirimlerini güncelleyebilir
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- Sistem bildirimleri ekleyebilir (trigger için)
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
CREATE POLICY "System can insert notifications"
ON notifications FOR INSERT
WITH CHECK (true);

-- 3. Test: Realtime aktif mi?
SELECT tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'notifications';