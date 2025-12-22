-- ============================================
-- AKTİF TESLİMATA QR KOD EKLE
-- ============================================
-- Status = 'delivered' OLMAYAN bir sipariş bul ve QR ekle
-- ============================================

-- 1. Aktif teslimatları listele (teslim edilmemiş)
SELECT 
  id,
  merchant_name,
  declared_amount,
  status,
  courier_id,
  created_at
FROM delivery_requests
WHERE status != 'delivered' 
  AND status != 'cancelled'
  AND courier_id = '250f4abe-858a-457b-b972-9a76340b07c2' -- Senin courier ID
ORDER BY created_at DESC
LIMIT 5;

-- 2. İlk aktif siparişin QR hash'ini oluştur
-- (Yukarıdaki sonuçtan bir ID seç ve aşağıya yaz)

-- ÖRNEK: Eğer ID = 'BURAYA_ID_GELECEK' ve amount = 1500.00 ise:
SELECT 
  id,
  declared_amount,
  generate_qr_hash(id::UUID, declared_amount) as qr_hash
FROM delivery_requests
WHERE status != 'delivered' 
  AND status != 'cancelled'
  AND courier_id = '250f4abe-858a-457b-b972-9a76340b07c2'
ORDER BY created_at DESC
LIMIT 1;

-- 3. QR hash'i ve merchant lokasyonunu kaydet
-- (İlk sorgudan çıkan ID'yi kullan)
UPDATE delivery_requests
SET 
  qr_code_hash = (SELECT generate_qr_hash(id::UUID, declared_amount) FROM delivery_requests WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079'),
  merchant_location = jsonb_build_object(
    'latitude', 37.5671,
    'longitude', 32.7883,
    'address', 'Konya Çumra Test Merchant'
  )
WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079'; -- ID'yi değiştir!

-- 4. Kontrol et
SELECT 
  id,
  merchant_name,
  declared_amount,
  status,
  qr_code_hash,
  merchant_location
FROM delivery_requests
WHERE id = '72ffaa29-aa7a-42f7-9d6a-debe86238079'; -- ID'yi değiştir!

-- ============================================
-- QR KOD İÇİN STRING FORMAT:
-- ============================================
-- order_id|amount|hash
-- Örnek: 72ffaa29-aa7a-42f7-9d6a-debe86238079|1500.00|9247f7a72666e8260de614bd2bae9d38267f2cd6d955d5a3857e438775c35f880b
