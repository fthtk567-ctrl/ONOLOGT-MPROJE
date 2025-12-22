-- ONLOG SİPARİŞ NUMARASI SİSTEMİ (GLOBAL SAYAÇ)
-- Format: ONL + YYYYMMDD + GLOBAL SIRA
-- Örnek: ONL202511021 (2 Kasım 2025, sistem geneli 1. sipariş)
-- NOT: TÜM merchantlar aynı sayaç havuzunu kullanır

-- 1. Otomatik sipariş numarası oluşturan fonksiyon
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
  v_date_part TEXT;
  v_daily_count INTEGER;
  v_order_number TEXT;
BEGIN
  -- Eğer order_number zaten doluysa, dokunma
  IF NEW.order_number IS NOT NULL AND NEW.order_number != '' THEN
    RETURN NEW;
  END IF;
  
  -- Tarih kısmını oluştur: YYYYMMDD formatında
  v_date_part := TO_CHAR(NOW(), 'YYYYMMDD');
  
  -- Bugünkü TÜM siparişlerin sayısını bul (sistem geneli - tüm merchantlar)
  SELECT COUNT(*) + 1 INTO v_daily_count
  FROM delivery_requests
  WHERE order_number LIKE 'ONL' || v_date_part || '%';
  
  -- Sipariş numarasını oluştur: ONL + TARİH + GLOBAL_GÜNLÜK_SIRA
  v_order_number := 'ONL' || v_date_part || v_daily_count::TEXT;
  
  -- Yeni kaydın order_number'ını set et
  NEW.order_number := v_order_number;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Trigger'ı oluştur (her INSERT'te çalışır)
DROP TRIGGER IF EXISTS trigger_generate_order_number ON delivery_requests;
CREATE TRIGGER trigger_generate_order_number
  BEFORE INSERT ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION generate_order_number();

-- 3. Mevcut kayıtları güncelle (eski UUID'leri yeni formata çevir - GLOBAL SAYAÇ)
DO $$
DECLARE
  v_record RECORD;
  v_date_part TEXT;
  v_daily_count INTEGER := 0;
  v_current_date DATE := NULL;
  v_order_number TEXT;
BEGIN
  -- TÜM kayıtları tarihe göre sırala (sistem geneli - tüm merchantlar)
  FOR v_record IN 
    SELECT id, created_at, merchant_id
    FROM delivery_requests 
    ORDER BY created_at ASC
  LOOP
    -- Tarih kısmını al
    v_date_part := TO_CHAR(v_record.created_at, 'YYYYMMDD');
    
    -- Yeni bir gün başladıysa sayacı sıfırla (global - tüm merchantlar için)
    IF v_current_date IS NULL OR v_current_date != v_record.created_at::DATE THEN
      v_current_date := v_record.created_at::DATE;
      v_daily_count := 1;
    ELSE
      v_daily_count := v_daily_count + 1;
    END IF;
    
    -- Sipariş numarasını oluştur (global sayaç)
    v_order_number := 'ONL' || v_date_part || v_daily_count::TEXT;
    
    -- Güncelle
    UPDATE delivery_requests
    SET order_number = v_order_number
    WHERE id = v_record.id;
  END LOOP;
  
  RAISE NOTICE '✅ Tüm siparişler yeni numara formatına güncellendi (Global Sayaç)!';
END $$;

-- 4. Kontrol et
SELECT 
  order_number,
  status,
  created_at,
  TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as tarih
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 10;

-- 5. Test et (yeni sipariş oluştur)
-- INSERT INTO delivery_requests (merchant_id, ...) VALUES (...);
-- SELECT order_number FROM delivery_requests ORDER BY created_at DESC LIMIT 1;

SELECT '🎉 Sipariş numarası sistemi başarıyla kuruldu!' as durum;
