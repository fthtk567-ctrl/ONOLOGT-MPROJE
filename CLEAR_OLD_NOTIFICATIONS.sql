-- Eski bildirimleri temizle
DELETE FROM notification_queue 
WHERE processed = true;

-- Veya hepsini temizle
-- DELETE FROM notification_queue;

SELECT COUNT(*) as "Kalan Bildirim" FROM notification_queue WHERE processed = false;
