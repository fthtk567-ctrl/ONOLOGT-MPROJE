-- TÜM ESKİ BİLDİRİMLERİ TEMİZLE
DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '1 hour';

-- Sadece bugünkü sent olanları da sil
DELETE FROM notifications WHERE notification_status = 'sent';

-- Pending olanları da sil
DELETE FROM notifications WHERE notification_status = 'pending';

SELECT COUNT(*) as kalan_bildirim FROM notifications;
