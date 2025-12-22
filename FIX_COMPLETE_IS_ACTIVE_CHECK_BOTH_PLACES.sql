-- ✅ SORUN ÇÖZÜLDÜ: is_active=false olan kuryeler artık atama almayacak
-- 
-- YAPILAN DEĞİŞİKLİKLER:
-- 1. ✅ auto_reassign_rejected_delivery() fonksiyonuna is_active kontrolü eklendi (Supabase)
-- 2. ✅ CourierAssignmentService.findBestCourier() metoduna is_active kontrolü eklendi (Flutter)
--
-- NEDEN İKİ YER?
-- - Supabase fonksiyonu: Red edilen teslimatların yeniden atanmasında çalışır
-- - Flutter servisi: Yeni teslimat oluşturulurken ilk kurye atamasında çalışır
--
-- ⚠️ BU SQL'İ SUPABASE'DE ÇALIŞTIRIN (Flutter değişikliği zaten yapıldı)

-- =====================================================
-- 1. AUTO REASSIGN TRİGGER FONKSİYONU (Supabase)
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

-- ✅ Fonksiyon güncellendi!
-- Trigger zaten mevcut, yeniden oluşturmaya gerek yok:
-- CREATE TRIGGER trigger_auto_reassign_delivery
--   AFTER UPDATE ON delivery_requests
--   FOR EACH ROW
--   EXECUTE FUNCTION auto_reassign_rejected_delivery();

-- =====================================================
-- 2. KONTROL SORGUSU: Hangi kuryeler atama alabilir?
-- =====================================================

SELECT 
  id,
  full_name,
  is_active,
  is_available,
  status,
  CASE 
    WHEN is_active = true AND is_available = true AND status = 'approved' THEN '✅ ATAMA ALABİLİR'
    WHEN is_active = false THEN '❌ HESAP PASİF (is_active=false) - ATAMA ALAMAZ'
    WHEN is_available = false THEN '🔴 OFFLINE (mesaide değil) - ATAMA ALAMAZ'
    WHEN status != 'approved' THEN '⚠️ ONAYSIZ (status != approved) - ATAMA ALAMAZ'
    ELSE '❓ DİĞER'
  END as "Atama Durumu"
FROM users
WHERE role = 'courier'
ORDER BY 
  is_active DESC, 
  is_available DESC, 
  status;

-- =====================================================
-- 3. TEST: Pasif kurye atama alabilir mi?
-- =====================================================

-- Bir kuryeyi geçici olarak pasif yap
-- UPDATE users 
-- SET is_active = false 
-- WHERE email = 'test@test.com';

-- Şimdi yeni teslimat isteği oluştur veya reddedilmiş bir teslimatı pending'e al
-- Bu pasif kurye artık atama ALMAMALI!

-- Test sonrası kuryeyi tekrar aktifleştir:
-- UPDATE users 
-- SET is_active = true 
-- WHERE email = 'test@test.com';

-- =====================================================
-- 4. FLUTTER DEĞİŞİKLİĞİ (BU ZATEN YAPILDI)
-- =====================================================
-- 
-- Dosya: onlog_merchant_panel/lib/services/courier_assignment_service.dart
-- Satır 33'e eklendi:
--
-- .eq('is_active', true) // ✅ Hesabı aktif olanlar
-- .eq('is_available', true) // 🟢 Mesaide olanlar
-- .eq('status', 'approved') // ✅ Onaylı olanlar
--
-- =====================================================

-- ✅ SONUÇ: Artık is_active=false olan kuryeler:
-- - Yeni teslimat oluştururken atama ALAMAZ (Flutter kontrolü)
-- - Red edilen teslimatlarda yeniden atama ALAMAZ (Supabase trigger kontrolü)
