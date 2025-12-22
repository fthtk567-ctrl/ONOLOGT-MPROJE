-- Realtime filter sorununu kontrol et
-- Her kurye sadece KENDİ teslimatlarını görmeli!

-- 1. ONL2025110247 siparişi kime atanmış?
SELECT 
    dr.order_number as "Sipariş No",
    dr.courier_id as "Kurye ID",
    courier.email as "Kurye Email",
    courier.full_name as "Kurye Adı"
FROM delivery_requests dr
LEFT JOIN users courier ON dr.courier_id = courier.id
WHERE dr.order_number = 'ONL2025110247';

-- 2. trolloji.ai'nin ID'sini bul
SELECT id, email, full_name 
FROM users 
WHERE email = 'trolloji.ai@gmail.com';

-- 3. kadirhan'ın ID'sini bul
SELECT id, email, full_name 
FROM users 
WHERE email = 'kadirhancekirdek42@gmail.com';
