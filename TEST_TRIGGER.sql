-- ============================================
-- TRİGGER TESTİ: Rejected teslimatı yeniden işle
-- ============================================

-- 1. Önce eski rejected teslimatları görelim
SELECT 
    id,
    order_number as "Sipariş No",
    status as "Durum",
    courier_id as "Kurye ID",
    rejected_by as "Red Eden ID",
    created_at as "Oluşturulma"
FROM delivery_requests
WHERE status = 'rejected'
ORDER BY created_at DESC;

-- 2. TEST: ONL2025110247 numaralı siparişi pending yap
UPDATE delivery_requests
SET 
    status = 'pending',
    courier_id = NULL,
    updated_at = NOW()
WHERE order_number = 'ONL2025110247';

-- 3. Şimdi rejected yap - TRİGGER tetiklenecek ve otomatik yeni kurye atayacak!
UPDATE delivery_requests
SET 
    status = 'rejected',
    rejected_by = '91945142-093c-4be2-873c-8dc8b4e84ba9'  -- PANEK TEST'in ID'si
WHERE order_number = 'ONL2025110247';

-- 4. KONTROL ET: kadirhan'a atanmış olmalı!
SELECT 
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    dr.courier_id as "Atanan Kurye ID",
    courier.full_name as "Kurye Adı",
    dr.rejected_by as "Red Eden ID",
    rejected.full_name as "Red Eden Adı"
FROM delivery_requests dr
LEFT JOIN users courier ON dr.courier_id = courier.id
LEFT JOIN users rejected ON dr.rejected_by = rejected.id
WHERE dr.order_number = 'ONL2025110247';
