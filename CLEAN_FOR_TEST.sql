-- TEMİZ TEST İÇİN ESKİ BİLDİRİMLERİ SİL

-- 1. Tüm eski bildirimleri sil
DELETE FROM notifications;

-- 2. Kontrol
SELECT COUNT(*) as bildirim_sayisi FROM notifications;

-- Şimdi Merchant Panel'dan yeni teslimat isteği oluştur!
-- Sadece 1 bildirim gelmeli
