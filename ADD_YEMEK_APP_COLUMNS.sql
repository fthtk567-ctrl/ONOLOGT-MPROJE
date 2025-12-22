-- ============================================
-- EKSİK KOLONLARI EKLE
-- ============================================

ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS recipient_name TEXT,
ADD COLUMN IF NOT EXISTS recipient_phone TEXT,
ADD COLUMN IF NOT EXISTS merchant_phone TEXT,
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'online',
ADD COLUMN IF NOT EXISTS estimated_delivery_time TIMESTAMPTZ;

-- ============================================
-- KONTROL: Kolonlar eklendi mi?
-- ============================================

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'delivery_requests'
  AND column_name IN (
    'recipient_name',
    'recipient_phone',
    'merchant_phone',
    'payment_method',
    'estimated_delivery_time'
  )
ORDER BY column_name;

-- ============================================
-- EN SON SİPARİŞİ TEKRAR KONTROL ET
-- ============================================

SELECT 
  id,
  external_order_id,
  created_at,
  declared_amount,
  recipient_name,
  recipient_phone,
  merchant_name,
  merchant_phone,
  package_count,
  payment_method,
  courier_type,
  status
FROM delivery_requests
WHERE source = 'yemek_app'
ORDER BY created_at DESC
LIMIT 1;
