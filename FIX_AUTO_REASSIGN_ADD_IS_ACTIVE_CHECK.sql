-- 🔧 AUTO REASSIGN TRİGGER'A is_active KONTROLÜ EKLE
-- Sorun: is_active=false olan kuryeler yeniden atamada seçilebiliyordu
-- Çözüm: Kurye seçim kriterlerine is_active=true ekle

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

-- ✅ Fonksiyon güncellendi, trigger zaten mevcut (yeniden oluşturmaya gerek yok)
-- Trigger: AFTER UPDATE ON delivery_requests
-- When: status = 'pending' AND courier_id IS NULL AND rejected_by IS NOT NULL

-- TEST İÇİN: Aktif kuryeler kimler?
SELECT 
  id,
  full_name,
  is_active,
  is_available,
  status,
  CASE 
    WHEN is_active = true AND is_available = true AND status = 'approved' THEN '✅ SEÇİLEBİLİR'
    WHEN is_active = false THEN '❌ HESAP PASİF (is_active=false)'
    WHEN is_available = false THEN '🔴 OFFLINE (mesaide değil)'
    WHEN status != 'approved' THEN '⚠️ ONAYSIZ (status != approved)'
    ELSE '❓ DİĞER'
  END as "Durum"
FROM users
WHERE role = 'courier'
ORDER BY is_active DESC, is_available DESC, status;
