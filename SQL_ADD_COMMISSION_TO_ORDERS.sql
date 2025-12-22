-- ============================================
-- SİPARİŞ TABLOSUNA KOMİSYON BİLGİLERİ EKLE
-- ============================================
-- ⚠️ ÇOK ÖNEMLİ: Sipariş anındaki komisyon oranı kaydedilmeli!
-- Sonradan komisyon değişse bile eski siparişler eski oranla hesaplanır.

-- 1️⃣ orders tablosuna komisyon kolonları ekle
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS commission_type TEXT, -- 'percentage' veya 'perOrder'
ADD COLUMN IF NOT EXISTS commission_value NUMERIC, -- Oran (15.0) veya tutar (50.0)
ADD COLUMN IF NOT EXISTS commission_snapshot_date TIMESTAMPTZ; -- Komisyon bilgisinin alındığı tarih

-- 2️⃣ Mevcut siparişlere default değer ata
-- (Geçmiş siparişler için - tahmin edilen değerler)
UPDATE public.orders
SET 
  commission_type = 'percentage',
  commission_value = 15.0,
  commission_snapshot_date = created_at
WHERE commission_type IS NULL;

-- 3️⃣ Index ekle (performans için)
CREATE INDEX IF NOT EXISTS idx_orders_commission_date 
ON public.orders(commission_snapshot_date);

-- 4️⃣ Kontrol et
SELECT 
  id,
  merchant_id,
  total_amount,
  commission_type,
  commission_value,
  CASE 
    WHEN commission_type = 'percentage' 
    THEN '%' || commission_value || ' = ' || (total_amount * commission_value / 100)::numeric(10,2) || '₺'
    WHEN commission_type = 'perOrder'
    THEN commission_value || '₺ sabit'
    ELSE 'Belirsiz'
  END as hesaplanan_komisyon,
  TO_CHAR(commission_snapshot_date, 'DD.MM.YYYY HH24:MI') as komisyon_tarihi,
  status,
  TO_CHAR(created_at, 'DD.MM.YYYY HH24:MI') as siparis_tarihi
FROM public.orders
ORDER BY created_at DESC
LIMIT 10;

-- 5️⃣ Açıklama ekle
COMMENT ON COLUMN public.orders.commission_type IS 
'Siparişin verildiği andaki komisyon türü: percentage (yüzde) veya perOrder (sipariş başı sabit)';

COMMENT ON COLUMN public.orders.commission_value IS 
'Siparişin verildiği andaki komisyon değeri. percentage ise oran (15.0), perOrder ise tutar (50.0)';

COMMENT ON COLUMN public.orders.commission_snapshot_date IS 
'Bu komisyon bilgisinin alındığı tarih. Merchant komisyon geçmişini takip etmek için.';
