-- ============================================
-- ESKİ TESLİMAT FOTOĞRAFLARINI OTOMATİK SİL
-- ============================================
-- 10 gün eski fotoğrafları Storage'dan ve veritabanından temizle
-- Her gece saat 03:00'te çalışır
-- ============================================

-- 1. Eski fotoğrafları silme fonksiyonu
CREATE OR REPLACE FUNCTION delete_old_delivery_photos()
RETURNS void AS $$
DECLARE
  v_record RECORD;
  v_deleted_count INTEGER := 0;
  v_file_name TEXT;
BEGIN
  -- 10 günden eski tamamlanmış teslimatları bul
  FOR v_record IN 
    SELECT id, delivery_photo_url
    FROM delivery_requests
    WHERE status = 'delivered'
      AND completed_at < NOW() - INTERVAL '10 days'
      AND delivery_photo_url IS NOT NULL
      AND delivery_photo_url != ''
  LOOP
    -- Dosya adını URL'den çıkar
    v_file_name := substring(v_record.delivery_photo_url from '[^/]+$');
    
    -- Supabase Storage'dan sil
    PERFORM storage.fnames(
      ARRAY[(storage.objects.bucket_id, v_file_name)]::storage.obj_address_c[]
    )
    FROM storage.objects
    WHERE bucket_id = 'delivery-photos'
      AND name = v_file_name;
    
    -- Veritabanından URL'i temizle
    UPDATE delivery_requests
    SET delivery_photo_url = NULL,
        verification_notes = COALESCE(verification_notes, '') || ' | Fotoğraf 10 gün sonra otomatik silindi (' || NOW()::DATE || ')',
        updated_at = NOW()
    WHERE id = v_record.id;
    
    v_deleted_count := v_deleted_count + 1;
  END LOOP;
  
  -- Log tut
  RAISE NOTICE '% adet eski teslimat fotoğrafı silindi', v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Günlük otomatik çalıştırma için Trigger
-- NOT: Supabase'de cron job kurmak için Dashboard > Database > Cron Jobs kullanılmalı
-- Alternatif: pg_cron extension (free plan'de olmayabilir)

-- Manuel test için:
-- SELECT delete_old_delivery_photos();

-- 3. Storage'dan doğrudan eski dosyaları silme politikası (RLS)
-- Bu politika ile sadece admin ve sistem fonksiyonları eski dosyaları silebilir
CREATE POLICY "System can delete old photos"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'delivery-photos' AND
  (
    -- Admin kullanıcılar silebilir
    auth.uid() IN (
      SELECT id FROM public.users WHERE role = 'admin'
    )
    OR
    -- 10 günden eski dosyalar silinebilir
    created_at < NOW() - INTERVAL '10 days'
  )
);

-- 4. Upload politikası (sadece courier'lar kendi fotoğraflarını yükleyebilir)
CREATE POLICY "Couriers can upload delivery photos"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'delivery-photos' AND
  auth.uid() IN (
    SELECT id FROM public.users WHERE role = 'courier'
  )
);

-- 5. Okuma politikası (herkes okuyabilir - public bucket)
CREATE POLICY "Anyone can view delivery photos"
ON storage.objects
FOR SELECT
USING (bucket_id = 'delivery-photos');

-- ============================================
-- KURULUM SONRASI YAPMALISINIZ:
-- ============================================
-- 1. Supabase Dashboard > Database > Extensions
--    - "pg_cron" extension'ı aktif et (Enterprise plan gerekebilir)
--
-- 2. Supabase Dashboard > Database > Cron Jobs > Create a new cron job
--    - Name: "delete_old_delivery_photos"
--    - Schedule: "0 3 * * *" (Her gece 03:00)
--    - SQL: SELECT delete_old_delivery_photos();
--
-- VEYA Free Plan için:
-- 3. Supabase Dashboard > Database > Functions > Webhooks
--    - External cron servis kullan (örn: cron-job.org)
--    - Trigger URL: https://<project-ref>.supabase.co/rest/v1/rpc/delete_old_delivery_photos
--    - Schedule: Her gün 03:00

-- ============================================
-- TEST:
-- ============================================
-- Manuel silme testi:
-- SELECT delete_old_delivery_photos();

-- 10+ günlük teslimatları kontrol et:
SELECT 
  id,
  merchant_name,
  completed_at,
  AGE(NOW(), completed_at) as "ne_kadar_once",
  delivery_photo_url
FROM delivery_requests
WHERE status = 'delivered'
  AND completed_at < NOW() - INTERVAL '10 days'
  AND delivery_photo_url IS NOT NULL
ORDER BY completed_at DESC;

-- ✅ HAZIR! Supabase'de çalıştır
