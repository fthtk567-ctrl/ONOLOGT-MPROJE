-- ============================================
-- EN SON YEMEK APP SİPARİŞİNİ KONTROL ET
-- ============================================

-- Tüm kolonları göster (eksik alanları tespit etmek için)
SELECT 
  id,
  external_order_id,
  created_at,
  
  -- Tutar bilgileri
  declared_amount,
  merchant_payment_due,
  courier_payment_due,
  system_commission,
  
  -- Kurye bilgileri
  courier_id,
  courier_type,
  courier_earnings_type,
  
  -- Müşteri bilgileri (YENİ ALANLAR)
  recipient_name,
  recipient_phone,
  
  -- Merchant bilgileri
  merchant_id,
  merchant_name,
  merchant_phone,
  
  -- Paket bilgileri
  package_count,
  notes,
  
  -- Adres bilgileri
  pickup_location,
  delivery_location,
  
  -- Ödeme bilgileri (YENİ ALAN)
  payment_method,
  estimated_delivery_time,
  
  -- Durum
  status,
  source
  
FROM delivery_requests
WHERE source = 'yemek_app'
ORDER BY created_at DESC
LIMIT 1;

-- ============================================
-- EKSİK KOLONLARI KONTROL ET
-- ============================================

-- Bu kolonlar varsa ✅, yoksa ❌ eklemek gerekiyor
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
