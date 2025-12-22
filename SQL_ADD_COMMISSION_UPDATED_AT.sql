-- ============================================
-- KOMİSYON GÜNCELLİME TARİHİ KOLONU EKLE
-- ============================================
-- ⚠️ ÇOK ÖNEMLİ: Eski siparişler eski komisyonla hesaplanmalı!

-- 1️⃣ users tablosuna commission_updated_at ekle
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS commission_updated_at TIMESTAMPTZ;

-- 2️⃣ Mevcut kayıtlar için şu anki tarihi ata
UPDATE public.users
SET commission_updated_at = created_at
WHERE role = 'merchant' AND commission_updated_at IS NULL;

-- 3️⃣ Kontrol et
SELECT 
  business_name,
  email,
  commission_settings->>'type' as komisyon_turu,
  CASE 
    WHEN commission_settings->>'type' = 'percentage' 
    THEN '%' || (commission_settings->>'commission_rate')
    WHEN commission_settings->>'type' = 'perOrder'
    THEN (commission_settings->>'per_order_fee') || '₺/sipariş'
    ELSE '❓ Belirsiz'
  END as komisyon,
  commission_updated_at,
  TO_CHAR(commission_updated_at, 'DD.MM.YYYY HH24:MI') as son_guncelleme
FROM public.users
WHERE role = 'merchant'
ORDER BY business_name;

-- 4️⃣ ÖNEMLİ NOT:
-- Sipariş oluşturulurken, o anki komisyon oranını orders tablosuna kaydet!
-- Örnek: orders.commission_rate, orders.commission_type
-- Böylece komisyon değişse bile eski siparişler etkilenmez!

COMMENT ON COLUMN public.users.commission_updated_at IS 
'Komisyon ayarlarının en son güncellendiği tarih. Sipariş oluştururken bu tarihi kontrol ederek doğru komisyon oranını uygula.';
