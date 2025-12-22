-- REJECTED teslimatları bul ve yeniden atama yap
-- Bu teslimatlar trolloji.ai tarafından reddedildi ama sisteme trigger yoktu

-- 1. Önce rejected teslimatları görelim
SELECT 
    dr.id,
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    dr.rejected_by as "Red Eden Kurye ID",
    rejected_courier.full_name as "Red Eden",
    dr.created_at as "Oluşturulma"
FROM delivery_requests dr
LEFT JOIN users rejected_courier ON dr.rejected_by = rejected_courier.id
WHERE dr.status = 'rejected'
ORDER BY dr.created_at DESC;

-- 2. Rejected teslimatları PENDING yapıp yeniden atama tetikle
-- ONL2025110247 ve ONL202511031 için

UPDATE delivery_requests
SET 
    status = 'pending',
    rejected_by = NULL,
    courier_id = NULL,
    updated_at = NOW()
WHERE status = 'rejected'
  AND order_number IN ('ONL2025110247', 'ONL202511031');

-- 3. Şimdi otomatik atama yapacak SQL (Manuel trigger)
-- Ama önce trigger'ı oluşturmalıyız!

-- Kontrol: Yeniden pending oldu mu?
SELECT 
    dr.order_number as "Sipariş No",
    dr.status as "Durum",
    dr.courier_id as "Kurye ID",
    dr.rejected_by as "Red Eden",
    dr.updated_at as "Güncellenme"
FROM delivery_requests
WHERE order_number IN ('ONL2025110247', 'ONL202511031')
ORDER BY dr.created_at DESC;
