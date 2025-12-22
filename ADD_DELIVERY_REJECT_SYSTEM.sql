-- ═══════════════════════════════════════════════════
-- ONLOG - TESLİMAT RED/CEZA SİSTEMİ
-- Kuryeler teslimatı reddedebilir + Ceza sistemi
-- ═══════════════════════════════════════════════════

-- 1️⃣ delivery_requests tablosuna RED/İPTAL kolonları ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancelled_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;

-- 2️⃣ users tablosuna CEZA kolonları ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS penalty_until TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejection_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS cancellation_count INT DEFAULT 0;

-- 3️⃣ Index'ler (performans için)
CREATE INDEX IF NOT EXISTS idx_delivery_rejected_by ON delivery_requests(rejected_by);
CREATE INDEX IF NOT EXISTS idx_delivery_cancelled_by ON delivery_requests(cancelled_by);
CREATE INDEX IF NOT EXISTS idx_users_penalty ON users(penalty_until) WHERE penalty_until > NOW();

-- 4️⃣ RLS Policies (Kurye kendi red/iptallerini görebilsin)
CREATE POLICY "Couriers can see own rejections" ON delivery_requests
  FOR SELECT USING (auth.uid() = rejected_by);

CREATE POLICY "Couriers can see own cancellations" ON delivery_requests
  FOR SELECT USING (auth.uid() = cancelled_by);

-- 5️⃣ Trigger: Red eden kurye sayacını artır
CREATE OR REPLACE FUNCTION increment_rejection_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rejected_by IS NOT NULL AND (OLD.rejected_by IS NULL OR OLD.rejected_by != NEW.rejected_by) THEN
    UPDATE users 
    SET rejection_count = rejection_count + 1
    WHERE id = NEW.rejected_by;
    
    RAISE NOTICE '📊 Kurye % red sayısı artırıldı', NEW.rejected_by;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_rejection ON delivery_requests;
CREATE TRIGGER trigger_increment_rejection
  AFTER UPDATE OF rejected_by ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION increment_rejection_count();

-- 6️⃣ Trigger: İptal eden kurye sayacını artır
CREATE OR REPLACE FUNCTION increment_cancellation_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.cancelled_by IS NOT NULL AND (OLD.cancelled_by IS NULL OR OLD.cancelled_by != NEW.cancelled_by) THEN
    UPDATE users 
    SET cancellation_count = cancellation_count + 1
    WHERE id = NEW.cancelled_by;
    
    RAISE NOTICE '⛔ Kurye % iptal sayısı artırıldı', NEW.cancelled_by;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_increment_cancellation ON delivery_requests;
CREATE TRIGGER trigger_increment_cancellation
  AFTER UPDATE OF cancelled_by ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION increment_cancellation_count();

-- 7️⃣ Otomatik ceza kaldırma fonksiyonu (Her 1 dakikada bir kontrol et)
CREATE OR REPLACE FUNCTION remove_expired_penalties()
RETURNS void AS $$
BEGIN
  -- Cezası biten kuryeleri otomatik aktif et
  UPDATE users
  SET 
    penalty_until = NULL,
    is_available = true,
    updated_at = NOW()
  WHERE 
    penalty_until IS NOT NULL 
    AND penalty_until <= NOW()
    AND role = 'courier';
    
  RAISE NOTICE '✅ % kurye cezası kaldırıldı', FOUND;
END;
$$ LANGUAGE plpgsql;

-- 8️⃣ Cron job (Supabase Dashboard'dan pg_cron extension'ı aktif edip çalıştır)
-- SELECT cron.schedule('remove-penalties', '* * * * *', 'SELECT remove_expired_penalties()');

-- 9️⃣ Merchant'a otomatik re-assign (RED edilen teslimat başka kuryeye)
CREATE OR REPLACE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_next_courier_id UUID;
BEGIN
  -- Sadece RED edilen teslimatlar için (status=pending, courier_id=NULL)
  IF NEW.status = 'pending' AND NEW.courier_id IS NULL AND NEW.rejected_by IS NOT NULL THEN
    
    RAISE NOTICE '🔄 Red edilen teslimat yeniden atanıyor: %', NEW.id;
    
    -- En yakın başka kuryeyi bul (red eden hariç)
    SELECT id INTO v_next_courier_id
    FROM users
    WHERE 
      role = 'courier'
      AND is_available = true
      AND (penalty_until IS NULL OR penalty_until <= NOW())
      AND id != NEW.rejected_by
      AND current_location IS NOT NULL
    ORDER BY 
      ST_Distance(
        current_location,
        (SELECT current_location FROM users WHERE id = NEW.merchant_id)
      )
    LIMIT 1;
    
    IF v_next_courier_id IS NOT NULL THEN
      -- Yeni kuryeye ata
      UPDATE delivery_requests
      SET 
        courier_id = v_next_courier_id,
        status = 'assigned',
        updated_at = NOW()
      WHERE id = NEW.id;
      
      RAISE NOTICE '✅ Yeni kurye atandı: %', v_next_courier_id;
      
      -- Bildirimi ekle
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      ) VALUES (
        v_next_courier_id,
        '🚀 Yeni Teslimat İsteği!',
        'Başka kurye reddetti, size atandı - Tutar: ' || NEW.declared_amount || ' TL',
        'delivery',
        false,
        NOW()
      );
    ELSE
      RAISE NOTICE '⚠️ Başka müsait kurye bulunamadı!';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_reassign ON delivery_requests;
CREATE TRIGGER trigger_auto_reassign
  AFTER UPDATE OF rejected_by ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION auto_reassign_rejected_delivery();

-- 🎯 TEST SORGUSU
SELECT 
  id,
  status,
  courier_id,
  rejected_by,
  rejected_at,
  cancelled_by,
  cancelled_at,
  cancellation_reason,
  accepted_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 5;

-- Kurye ceza durumu kontrol
SELECT 
  id,
  full_name,
  rejection_count,
  cancellation_count,
  penalty_until,
  is_available,
  CASE 
    WHEN penalty_until > NOW() THEN 'Cezalı ⛔'
    ELSE 'Aktif ✅'
  END as status
FROM users
WHERE role = 'courier'
ORDER BY rejection_count DESC, cancellation_count DESC
LIMIT 10;
