-- ============================================
-- BİLDİRİM FONKSİYONLARINI YENİDEN OLUŞTUR
-- ============================================

-- 1. Eski fonksiyonları sil
DROP FUNCTION IF EXISTS notify_courier_simple CASCADE;
DROP FUNCTION IF EXISTS add_notification_to_queue CASCADE;

-- 2. YENİ FONKSİYON: Kuryeye bildirim ekle
CREATE OR REPLACE FUNCTION add_notification_to_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- Sadece courier_id varsa bildirim ekle
  IF NEW.courier_id IS NOT NULL THEN
    INSERT INTO notifications (user_id, title, message, type)
    VALUES (
      NEW.courier_id,
      'Yeni Teslimat!',
      'Tutar: ' || NEW.declared_amount || ' TL - Kazanç: ' || NEW.courier_payment_due || ' TL',
      'delivery'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. YENİ FONKSİYON: FCM bildirimi gönder (basit versiyon)
CREATE OR REPLACE FUNCTION notify_courier_simple()
RETURNS TRIGGER AS $$
BEGIN
  -- Bu fonksiyon FCM için kullanılıyor
  -- Şimdilik sadece RETURN yapıyoruz
  -- FCM entegrasyonu Flutter tarafında realtime dinleme ile halloluyor
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ✅ Supabase'de çalıştır
