-- ESKİ BİLDİRİMLERİ OTOMATİK TEMİZLEYEN FONKSİYON

-- 1. Temizleme fonksiyonu oluştur
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    -- 24 saatten eski ve 'sent' olan bildirimleri sil
    DELETE FROM notifications 
    WHERE notification_status = 'sent' 
    AND sent_at < NOW() - INTERVAL '24 hours';
    
    -- 7 günden eski tüm bildirimleri sil (failed dahil)
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '7 days';
    
    RAISE NOTICE 'Eski bildirimler temizlendi';
END;
$$ LANGUAGE plpgsql;

-- 2. Manuel temizlik yap
SELECT cleanup_old_notifications();

-- 3. Şimdilik manuel kullan, ileriye cron job ekleyebiliriz
-- Her gün saat 03:00'te otomatik çalıştırmak için Supabase'de cron job ayarlanabilir
