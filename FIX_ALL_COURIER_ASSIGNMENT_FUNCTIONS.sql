-- 🔧 TÜM KURYE ATAMA FONKSİYONLARINA is_active KONTROLÜ EKLE
-- Tarih: 3 Kasım 2025
-- 
-- ⚠️ SORUN: Birçok fonksiyon kurye seçerken is_active=true kontrolü yapmıyor!
-- ✅ ÇÖZÜM: Tüm kurye seçim sorgularına is_active=true kriteri ekleniyor
--
-- DEĞİŞTİRİLEN FONKSİYONLAR:
-- 1. find_nearest_couriers() - Konum bazlı kurye bulma
-- 2. auto_reassign_rejected_delivery() - Red edilen teslimatları yeniden atama
-- 3. (Diğer fonksiyonlar sadece bildirim gönderiyor, atama yapmıyor)

-- =====================================================
-- 1. FIND_NEAREST_COURIERS - Konum Bazlı Kurye Bulma
-- =====================================================

CREATE OR REPLACE FUNCTION find_nearest_couriers(
    p_merchant_lat FLOAT,
    p_merchant_lng FLOAT,
    p_max_distance_km FLOAT DEFAULT 5.0,
    p_limit INTEGER DEFAULT 3
) RETURNS TABLE (
    courier_ids UUID[],
    found_count INTEGER,
    max_distance_found FLOAT
) AS $$
DECLARE
    v_courier_list UUID[];
    v_found_count INTEGER;
    v_max_distance FLOAT;
BEGIN
    -- En yakın kuryeleri bul (PostGIS ST_Distance kullanarak)
    WITH courier_distances AS (
        SELECT 
            id,
            ST_Distance(
                ST_SetSRID(ST_MakePoint(current_location->>'longitude', current_location->>'latitude')::geometry, 4326),
                ST_SetSRID(ST_MakePoint(p_merchant_lng, p_merchant_lat)::geometry, 4326)
            ) * 111.32 as distance_km
        FROM users
        WHERE 
            role = 'courier'
            AND status = 'approved'      -- ✅ 'approved' olmalı, 'active' değil!
            AND is_active = true         -- ✅ YENİ EKLENEN!
            AND is_available = true      -- ✅ Mesaide olmalı
            AND current_location IS NOT NULL
            AND current_location->>'latitude' IS NOT NULL
            AND current_location->>'longitude' IS NOT NULL
    )
    SELECT 
        ARRAY_AGG(id),
        COUNT(*)::INTEGER,
        MAX(distance_km)
    INTO v_courier_list, v_found_count, v_max_distance
    FROM (
        SELECT id, distance_km
        FROM courier_distances
        WHERE distance_km <= p_max_distance_km
        ORDER BY distance_km ASC
        LIMIT p_limit
    ) nearest;

    RETURN QUERY SELECT 
        COALESCE(v_courier_list, ARRAY[]::UUID[]),
        COALESCE(v_found_count, 0),
        COALESCE(v_max_distance, 0.0);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. AUTO_REASSIGN_REJECTED_DELIVERY - Yeniden Atama
-- =====================================================

CREATE OR REPLACE FUNCTION auto_reassign_rejected_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_next_courier_id UUID;
BEGIN
  -- Sadece RED edilen teslimatlar için (status=pending, courier_id=NULL)
  IF NEW.status = 'pending' AND NEW.courier_id IS NULL AND NEW.rejected_by IS NOT NULL THEN
    
    RAISE NOTICE '🔄 Red edilen teslimat yeniden atanıyor: %', NEW.id;
    
    -- Müsait kuryeyi bul (red eden hariç + is_active kontrolü eklendi!)
    SELECT id INTO v_next_courier_id
    FROM users
    WHERE 
      role = 'courier'
      AND status = 'approved'           -- ✅ Onaylı olmalı
      AND is_active = true              -- ✅ AKTİF OLMALI (YENİ EKLENEN!)
      AND is_available = true           -- ✅ Müsait olmalı (mesaide)
      AND (penalty_until IS NULL OR penalty_until <= NOW())  -- ✅ Cezalı değil
      AND id != NEW.rejected_by         -- ✅ Red eden hariç
    ORDER BY RANDOM()
    LIMIT 1;
    
    IF v_next_courier_id IS NOT NULL THEN
      -- ✅ Yeni kuryeye ata
      UPDATE delivery_requests
      SET 
        courier_id = v_next_courier_id,
        status = 'assigned',
        updated_at = NOW()
      WHERE id = NEW.id;
      
      RAISE NOTICE '✅ Yeni kurye atandı: %', v_next_courier_id;
      
      -- Kuryeye bildirim gönder
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
      -- ❌ Müsait kurye bulunamadı - İsteği iptal et ve merchant'a bildir
      RAISE NOTICE '⚠️ Müsait kurye bulunamadı - İstek iptal ediliyor!';
      
      UPDATE delivery_requests
      SET 
        status = 'cancelled',
        rejection_reason = 'Müsait kurye bulunamadı',
        updated_at = NOW()
      WHERE id = NEW.id;
      
      -- Merchant'a bildirim gönder
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
      ) VALUES (
        NEW.merchant_id,
        '❌ Teslimat İptal Edildi',
        'Sipariş #' || COALESCE(NEW.order_number, NEW.id::TEXT) || ' - Müsait kurye bulunamadı. Lütfen daha sonra tekrar deneyin.',
        'delivery',
        false,
        NOW()
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. DİĞER FONKSİYONLAR HAKKINDA NOT
-- =====================================================

-- Aşağıdaki fonksiyonlar SADECE BİLDİRİM/HESAPLAMA yapıyor, kurye ataması yapmıyor:
-- - add_notification_on_courier_assign() → Zaten atanmış kuryeye bildirim gönderir
-- - complete_delivery_with_verification() → Teslimat tamamlandığında çalışır
-- - create_courier_notification() → Bildirim oluşturur
-- - notify_courier_* fonksiyonları → Bildirim gönderir
-- - process_order_payment_on_delivery() → Ödeme işlemleri
-- - update_courier_delivery_count() → İstatistik günceller
-- 
-- Bu fonksiyonlara is_active kontrolü EKLENMEMELİ çünkü:
-- 1. Kurye zaten atanmış, sadece bildirim gönderiyorlar
-- 2. Pasif bir kurye aktif teslimatını tamamlayabilmeli
-- 3. Ödeme işlemleri kurye aktif/pasif olsa da çalışmalı

-- =====================================================
-- 4. KONTROL SORGUSU
-- =====================================================

-- Hangi kuryeler atama alabilir?
SELECT 
  id,
  full_name,
  email,
  is_active,
  is_available,
  status,
  penalty_until,
  CASE 
    WHEN is_active = true AND is_available = true AND status = 'approved' AND (penalty_until IS NULL OR penalty_until <= NOW())
      THEN '✅ ATAMA ALABİLİR'
    WHEN is_active = false 
      THEN '❌ HESAP PASİF (is_active=false)'
    WHEN is_available = false 
      THEN '🔴 OFFLINE (mesaide değil)'
    WHEN status != 'approved' 
      THEN '⚠️ ONAYSIZ (status != approved)'
    WHEN penalty_until > NOW()
      THEN '🚫 CEZALI (' || penalty_until || ' kadar)'
    ELSE '❓ DİĞER'
  END as "Atama Durumu"
FROM users
WHERE role = 'courier'
ORDER BY 
  is_active DESC, 
  is_available DESC, 
  status,
  penalty_until NULLS FIRST;

-- =====================================================
-- 5. TEST SENARYOSU
-- =====================================================

-- Test 1: find_nearest_couriers fonksiyonunu test et
-- SELECT * FROM find_nearest_couriers(41.0082, 28.9784, 10.0, 5);
-- Sonuç: Sadece is_active=true olan kuryeleri dönmeli!

-- Test 2: Pasif kurye teslimat alabilir mi?
-- UPDATE users SET is_active = false WHERE email = 'test@test.com';
-- Şimdi yeni teslimat oluştur veya teslimat reddet
-- Pasif kurye ATAMA ALMAMALI!

-- Test 3: Kurye aktifleştir
-- UPDATE users SET is_active = true WHERE email = 'test@test.com';

-- =====================================================
-- ✅ ÖZET
-- =====================================================
-- 
-- GÜNCELLENEN FONKSİYONLAR:
-- 1. ✅ find_nearest_couriers() - is_active ve status='approved' eklendi
-- 2. ✅ auto_reassign_rejected_delivery() - is_active eklendi
--
-- GÜNCELLENMEYENLER (çünkü atama yapmıyorlar):
-- - add_notification_on_courier_assign
-- - complete_delivery_with_verification
-- - create_courier_notification
-- - notify_courier_* fonksiyonları
-- - process_order_payment_on_delivery
-- - update_courier_delivery_count
-- 
-- FLUTTER TARAFINDA DA YAPILDI:
-- - CourierAssignmentService.findBestCourier() metoduna is_active eklendi
--
-- SONUÇ: Artık is_active=false olan kuryeler hiçbir şekilde yeni atama ALAMAZ!
