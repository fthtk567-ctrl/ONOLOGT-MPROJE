-- ============================================
-- QR KOD + GPS DOĞRULAMA SİSTEMİ
-- ============================================
-- Teslimat doğrulama için QR kod ve GPS kontrolü ekle
-- ============================================

-- 1. delivery_requests tablosuna yeni kolonlar ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS qr_code_hash TEXT,
ADD COLUMN IF NOT EXISTS qr_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS delivery_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS delivery_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS gps_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS gps_distance_meters NUMERIC,
ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'suspicious', 'rejected')),
ADD COLUMN IF NOT EXISTS verification_notes TEXT,
ADD COLUMN IF NOT EXISTS delivery_photo_url TEXT,
ADD COLUMN IF NOT EXISTS customer_signature_url TEXT;

-- 2. QR Kod oluşturma fonksiyonu (Merchant sipariş oluştururken)
CREATE OR REPLACE FUNCTION generate_qr_hash(
  p_order_id UUID,
  p_declared_amount DECIMAL
) RETURNS TEXT AS $$
DECLARE
  v_secret TEXT := 'ONLOG_SECRET_KEY_2025'; -- Supabase Vault'ta saklanmalı!
  v_hash TEXT;
BEGIN
  -- SHA256 hash oluştur: order_id + amount + secret
  v_hash := encode(
    digest(p_order_id::TEXT || p_declared_amount::TEXT || v_secret, 'sha256'),
    'hex'
  );
  
  RETURN v_hash;
END;
$$ LANGUAGE plpgsql;

-- 3. QR Kod doğrulama fonksiyonu (Kurye QR taratınca)
CREATE OR REPLACE FUNCTION verify_qr_code(
  p_order_id UUID,
  p_scanned_hash TEXT
) RETURNS TABLE(
  is_valid BOOLEAN,
  message TEXT,
  declared_amount DECIMAL
) AS $$
DECLARE
  v_order RECORD;
  v_expected_hash TEXT;
BEGIN
  -- Siparişi al
  SELECT * INTO v_order
  FROM delivery_requests
  WHERE id = p_order_id;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Sipariş bulunamadı'::TEXT, 0.00::DECIMAL;
    RETURN;
  END IF;
  
  -- Beklenen hash'i hesapla
  v_expected_hash := generate_qr_hash(p_order_id, v_order.declared_amount);
  
  -- Hash eşleşiyor mu?
  IF v_expected_hash = p_scanned_hash THEN
    -- QR doğrulandı olarak işaretle
    UPDATE delivery_requests
    SET qr_verified = true,
        updated_at = NOW()
    WHERE id = p_order_id;
    
    RETURN QUERY SELECT true, 'QR kod doğrulandı ✓'::TEXT, v_order.declared_amount;
  ELSE
    -- Şüpheli işaretle
    UPDATE delivery_requests
    SET verification_status = 'suspicious',
        verification_notes = 'QR kod hash eşleşmiyor - olası dolandırıcılık',
        updated_at = NOW()
    WHERE id = p_order_id;
    
    RETURN QUERY SELECT false, 'GEÇERSİZ QR KOD! Admin bilgilendirildi.'::TEXT, 0.00::DECIMAL;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. GPS lokasyon doğrulama fonksiyonu
CREATE OR REPLACE FUNCTION verify_gps_location(
  p_order_id UUID,
  p_delivery_lat DOUBLE PRECISION,
  p_delivery_lng DOUBLE PRECISION
) RETURNS TABLE(
  is_valid BOOLEAN,
  distance_meters NUMERIC,
  message TEXT
) AS $$
DECLARE
  v_merchant_location JSONB;
  v_merchant_lat DOUBLE PRECISION;
  v_merchant_lng DOUBLE PRECISION;
  v_distance NUMERIC;
  v_max_distance NUMERIC := 100; -- 100 metre tolerans
BEGIN
  -- Merchant lokasyonunu al
  SELECT dr.merchant_location INTO v_merchant_location
  FROM delivery_requests dr
  WHERE dr.id = p_order_id;
  
  IF v_merchant_location IS NULL THEN
    RETURN QUERY SELECT false, 0::NUMERIC, 'Merchant lokasyonu bulunamadı'::TEXT;
    RETURN;
  END IF;
  
  -- JSONB'den latitude/longitude çıkar
  v_merchant_lat := (v_merchant_location->>'latitude')::DOUBLE PRECISION;
  v_merchant_lng := (v_merchant_location->>'longitude')::DOUBLE PRECISION;
  
  -- Haversine formülü ile mesafe hesapla (metre cinsinden)
  v_distance := 6371000 * acos(
    cos(radians(v_merchant_lat)) * 
    cos(radians(p_delivery_lat)) * 
    cos(radians(p_delivery_lng) - radians(v_merchant_lng)) + 
    sin(radians(v_merchant_lat)) * 
    sin(radians(p_delivery_lat))
  );
  
  -- GPS verilerini kaydet
  UPDATE delivery_requests
  SET delivery_latitude = p_delivery_lat,
      delivery_longitude = p_delivery_lng,
      gps_distance_meters = v_distance,
      gps_verified = (v_distance <= v_max_distance),
      updated_at = NOW()
  WHERE id = p_order_id;
  
  -- Sonuç döndür
  IF v_distance <= v_max_distance THEN
    RETURN QUERY SELECT true, v_distance, 'GPS konumu doğrulandı ✓'::TEXT;
  ELSE
    -- Şüpheli işaretle
    UPDATE delivery_requests
    SET verification_status = 'suspicious',
        verification_notes = COALESCE(verification_notes, '') || 
          ' | GPS mesafe uyuşmazlığı: ' || ROUND(v_distance, 2)::TEXT || 'm (max ' || v_max_distance || 'm)',
        updated_at = NOW()
    WHERE id = p_order_id;
    
    RETURN QUERY SELECT false, v_distance, 
      'GPS UYUŞMAZLIĞI! Merchant''dan ' || ROUND(v_distance, 2)::TEXT || 'm uzaktasınız (max ' || v_max_distance || 'm)'::TEXT;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 5. Teslimat onaylama fonksiyonu (QR + GPS + Fotoğraf kontrolü)
CREATE OR REPLACE FUNCTION complete_delivery_with_verification(
  p_order_id UUID,
  p_courier_id UUID,
  p_delivery_lat DOUBLE PRECISION,
  p_delivery_lng DOUBLE PRECISION,
  p_photo_url TEXT,
  p_signature_url TEXT DEFAULT NULL
) RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  requires_admin_approval BOOLEAN
) AS $$
DECLARE
  v_order RECORD;
  v_auto_approve BOOLEAN := true;
BEGIN
  -- Siparişi al
  SELECT * INTO v_order
  FROM delivery_requests
  WHERE id = p_order_id
    AND courier_id = p_courier_id;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Sipariş bulunamadı veya size ait değil'::TEXT, false;
    RETURN;
  END IF;
  
  -- Fotoğraf ve imza kaydet
  UPDATE delivery_requests
  SET delivery_photo_url = p_photo_url,
      customer_signature_url = p_signature_url,
      updated_at = NOW()
  WHERE id = p_order_id;
  
  -- QR doğrulandı mı?
  IF NOT v_order.qr_verified THEN
    v_auto_approve := false;
  END IF;
  
  -- GPS doğrulandı mı?
  IF NOT v_order.gps_verified THEN
    v_auto_approve := false;
  END IF;
  
  -- Fotoğraf var mı?
  IF p_photo_url IS NULL OR LENGTH(p_photo_url) = 0 THEN
    v_auto_approve := false;
  END IF;
  
  -- Otomatik onay mı, admin onayı mı?
  IF v_auto_approve THEN
    UPDATE delivery_requests
    SET status = 'delivered',
        verification_status = 'verified',
        completed_at = NOW(),
        updated_at = NOW()
    WHERE id = p_order_id;
    
    RETURN QUERY SELECT true, 'Teslimat başarıyla tamamlandı! ✓'::TEXT, false;
  ELSE
    UPDATE delivery_requests
    SET status = 'pending_review',
        verification_status = 'suspicious',
        verification_notes = COALESCE(verification_notes, '') || 
          ' | Doğrulama eksik - Admin onayı gerekli',
        updated_at = NOW()
    WHERE id = p_order_id;
    
    RETURN QUERY SELECT false, 'Teslimat ADMIN ONAYI BEKLİYOR. (QR/GPS/Fotoğraf eksik)'::TEXT, true;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 6. Test fonksiyonları
-- QR hash oluşturma testi:
SELECT generate_qr_hash(
  '123e4567-e89b-12d3-a456-426614174000'::UUID, 
  150.00
) as test_qr_hash;

-- GPS mesafe testi (Ankara Kızılay örnek):
SELECT * FROM verify_gps_location(
  '123e4567-e89b-12d3-a456-426614174000'::UUID,
  39.9208, -- Teslimat lat
  32.8541  -- Teslimat lng
);

-- Şüpheli teslimatları listele
SELECT 
  id,
  merchant_name,
  declared_amount,
  courier_payment_due,
  qr_verified,
  gps_verified,
  gps_distance_meters,
  verification_status,
  verification_notes
FROM delivery_requests
WHERE verification_status IN ('suspicious', 'pending_review')
ORDER BY created_at DESC;

-- ✅ SQL HAZIR! Supabase Dashboard > SQL Editor'da çalıştır
