-- TÜM GEREKSIZ TRIGGER'LARI SIL
-- SADECE trigger_single_notification KALACAK!

-- NOT: trigger_calculate_commissions ve update_wallet triggers GEREKLİ (ödeme sistemi için)
-- SADECE BİLDİRİM GÖNDEREN GEREKSIZ TRİGGER'LARI SİLECEĞİZ

-- 1. set_accept_deadline
DROP TRIGGER IF EXISTS set_accept_deadline ON delivery_requests;

-- 2. set_smart_delivery_deadlines  
DROP TRIGGER IF EXISTS set_smart_delivery_deadlines ON delivery_requests;

-- 3. trigger_notify_courier_status_change
DROP TRIGGER IF EXISTS trigger_notify_courier_status_change ON delivery_requests;

-- 4. update_delivery_requests_updated_at (bu sadece timestamp günceller, sorun değil)
-- DROP TRIGGER IF EXISTS update_delivery_requests_updated_at ON delivery_requests;

-- Kontrol et - sadece trigger_single_notification kalmalı
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;
