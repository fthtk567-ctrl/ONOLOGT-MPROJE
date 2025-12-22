-- ============================================
-- ADIM 2: Storage Bucket İzinleri (RLS Policies)
-- ============================================

-- 1. Courier'lar fotoğraf yükleyebilir
CREATE POLICY "Couriers can upload delivery photos"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'delivery-photos' AND
  auth.uid() IN (
    SELECT id FROM public.users WHERE role = 'courier'
  )
);

-- 2. Herkes fotoğrafları görebilir (public bucket)
CREATE POLICY "Anyone can view delivery photos"
ON storage.objects
FOR SELECT
USING (bucket_id = 'delivery-photos');

-- 3. Sistem ve adminler eski fotoğrafları silebilir
CREATE POLICY "System can delete old photos"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'delivery-photos' AND
  (
    auth.uid() IN (
      SELECT id FROM public.users WHERE role = 'admin'
    )
    OR
    created_at < NOW() - INTERVAL '10 days'
  )
);

-- ✅ Başarıyla çalıştırılırsa "Success. No rows returned" göreceksin
