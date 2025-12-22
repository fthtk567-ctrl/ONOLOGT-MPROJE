-- ============================================
-- BİLDİRİM FONKSİYONLARINI KONTROL ET
-- ============================================

-- 1. notify_courier_simple fonksiyonunu göster
SELECT 
    proname as "fonksiyon_adi",
    prosrc as "fonksiyon_kodu"
FROM pg_proc
WHERE proname = 'notify_courier_simple';

-- 2. add_notification_to_queue fonksiyonunu göster
SELECT 
    proname as "fonksiyon_adi",
    prosrc as "fonksiyon_kodu"
FROM pg_proc
WHERE proname = 'add_notification_to_queue';

-- 3. Son oluşturulan delivery_requests kayıtlarını göster
SELECT 
    id,
    merchant_id,
    courier_id,
    status,
    created_at,
    merchant_name,
    declared_amount
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;

-- ✅ Supabase SQL Editor'da çalıştır
