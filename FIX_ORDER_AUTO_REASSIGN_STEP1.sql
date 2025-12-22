-- ADIM 1: Tabloyu hazırla

-- Eski trigger ve fonksiyonu sil
DROP TRIGGER IF EXISTS trigger_auto_reassign_delivery ON delivery_requests;
DROP FUNCTION IF EXISTS auto_reassign_rejected_delivery() CASCADE;

-- Foreign key constraint'i sil
ALTER TABLE delivery_requests 
DROP CONSTRAINT IF EXISTS delivery_requests_rejected_by_fkey;

-- rejected_by kolonunu JSONB array'e dönüştür
ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by TYPE JSONB USING 
  CASE 
    WHEN rejected_by IS NULL THEN '[]'::jsonb
    ELSE jsonb_build_array(rejected_by)
  END;

ALTER TABLE delivery_requests 
ALTER COLUMN rejected_by SET DEFAULT '[]'::jsonb;

-- rejection_count kolonunu ekle
ALTER TABLE delivery_requests
ADD COLUMN IF NOT EXISTS rejection_count INTEGER DEFAULT 0;

SELECT '✅ Adım 1 tamamlandı - Tablo hazır!' as status;
