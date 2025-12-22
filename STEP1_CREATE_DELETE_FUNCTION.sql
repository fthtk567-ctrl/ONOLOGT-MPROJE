-- ============================================
-- ADIM 1: Eski Fotoğrafları Silme Fonksiyonu
-- ============================================

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
    
    -- Supabase Storage'dan sil (storage.fnames yerine direkt DELETE)
    DELETE FROM storage.objects
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

-- Test için:
-- SELECT delete_old_delivery_photos();
