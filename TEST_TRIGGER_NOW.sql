-- TEST: Reddedilmiş bir teslimatı pending'e al, trigger merchant'a bildirim göndersin

-- ADIM 1: Bir reddedilmiş teslimatı seç
SELECT 
  id,
  order_number,
  status,
  merchant_id,
  rejected_by,
  rejection_reason,
  declared_amount
FROM delivery_requests
WHERE rejected_by IS NOT NULL
  AND status = 'rejected'
ORDER BY created_at DESC
LIMIT 1;

-- ADIM 2: Bu teslimatı pending'e al (yukarıdaki id'yi buraya yapıştır)
-- Trigger otomatik çalışacak ve müsait kurye bulamayınca cancelled yapıp merchant'a bildirim gönderecek

UPDATE delivery_requests
SET 
  status = 'pending',
  courier_id = NULL,
  updated_at = NOW()
WHERE id = '67ddd83f-2167-488f-9e16-95371497e0ae'; -- İlk reddedilmiş teslimat

-- ADIM 3: Merchant'a bildirim gitti mi kontrol et
SELECT 
  id,
  user_id,
  title,
  message,
  type,
  is_read,
  created_at
FROM notifications
WHERE user_id = '4445ceef-e70e-4ba6-a6cf-d13c21717bfe' -- Merchant ID
  AND type = 'delivery_cancelled'
ORDER BY created_at DESC
LIMIT 3;

-- ADIM 4: Teslimat cancelled oldu mu?
SELECT 
  id,
  order_number,
  status,
  rejection_reason,
  updated_at
FROM delivery_requests
WHERE id = '67ddd83f-2167-488f-9e16-95371497e0ae';
