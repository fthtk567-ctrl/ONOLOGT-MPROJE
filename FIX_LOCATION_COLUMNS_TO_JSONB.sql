-- delivery_requests tablosundaki location kolonlarını JSONB'ye çevir
-- ÇOK BASIT YÖNTEM: Sadece kolonları sil ve yeniden oluştur

-- ADIM 1: Eski kolonları tamamen sil (geometry tipi ile birlikte tüm constraint'ler gider)
ALTER TABLE delivery_requests DROP COLUMN IF EXISTS pickup_location CASCADE;
ALTER TABLE delivery_requests DROP COLUMN IF EXISTS delivery_location CASCADE;

-- ADIM 2: Yeni JSONB kolonları oluştur
ALTER TABLE delivery_requests ADD COLUMN pickup_location jsonb;
ALTER TABLE delivery_requests ADD COLUMN delivery_location jsonb;

-- BAŞARILI! Artık Flutter'dan {"latitude": 37.8667, "longitude": 32.4833} gönderebilirsin!
