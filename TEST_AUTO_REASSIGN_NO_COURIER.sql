-- TESTİ BAŞLAT: Bir reddedilmiş teslimatı pending'e al ve trigger'ın müsait kurye yoksa cancel edip merchant'a bildirim göndermesini izle

-- 1. Önce bir reddedilmiş teslimatı seç
SELECT 
  id,
  order_number,
  status,
  merchant_id,
  rejected_by,
  rejection_reason
FROM delivery_requests
WHERE rejected_by IS NOT NULL
LIMIT 1;

-- 2. Bu teslimatı pending'e al (trigger tetiklenecek)
-- NOT: İlk önce yukarıdaki SELECT'i çalıştır, id'yi kopyala, aşağıya yapıştır

-- UPDATE delivery_requests
-- SET 
--   status = 'pending',
--   courier_id = NULL,
--   updated_at = NOW()
-- WHERE id = 'BURAYA_ID_YAPIŞTIR';

-- 3. Merchant'a giden bildirimleri kontrol et
SELECT 
  id,
  user_id,
  title,
  message,
  type,
  is_read,
  created_at
FROM notifications
WHERE type = 'delivery_cancelled'
  AND created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC;

-- 4. İstek iptal edildi mi kontrol et
SELECT 
  id,
  order_number,
  status,
  rejection_reason,
  updated_at
FROM delivery_requests
WHERE status = 'cancelled'
  AND rejection_reason = 'Müsait kurye bulunamadı'
ORDER BY updated_at DESC
LIMIT 5;
