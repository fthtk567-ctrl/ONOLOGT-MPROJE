-- ============================================
-- TEST MERCHANT İÇİN VERİ OLUŞTUR
-- Raporlar sayfasını test etmek için
-- ============================================

-- Önce mevcut bir merchant ID'sini kullan
-- MERCHANT_PANEL_DURUM_KONTROLU.sql çalıştırıp bir merchant ID bul
-- Sonra aşağıdaki MERCHANT_ID değerini değiştir

DO $$
DECLARE
  test_merchant_id UUID := '4445ceef-0786-4ba6-a6cf-d13c21717bfe'; -- SATICI TEST
  test_courier_id UUID;
  test_delivery_id UUID;
BEGIN
  -- 1. Kurye bul veya oluştur
  SELECT id INTO test_courier_id 
  FROM users 
  WHERE role = 'courier' AND is_approved = true 
  LIMIT 1;

  IF test_courier_id IS NULL THEN
    RAISE NOTICE 'Uyarı: Hiç aktif kurye yok!';
    RETURN;
  END IF;

  -- 2. Son 7 gün için test delivery_requests oluştur
  FOR i IN 0..6 LOOP
    INSERT INTO delivery_requests (
      merchant_id,
      courier_id,
      status,
      source,
      declared_amount,
      pickup_address,
      delivery_address,
      recipient_name,
      recipient_phone,
      created_at
    ) VALUES (
      test_merchant_id,
      test_courier_id,
      CASE 
        WHEN random() < 0.7 THEN 'DELIVERED'
        WHEN random() < 0.85 THEN 'CANCELLED'
        ELSE 'WAITING_COURIER'
      END,
      'manual',
      (random() * 300 + 50)::numeric(10,2), -- 50-350 TL arası
      'Test Pickup Address ' || i,
      'Test Delivery Address ' || i,
      'Test Müşteri ' || i,
      '05' || lpad((random() * 1000000000)::bigint::text, 9, '0'),
      NOW() - (i || ' days')::interval - (random() * 24 || ' hours')::interval
    );
  END LOOP;

  -- 3. Yemek App test siparişi ekle
  FOR i IN 1..3 LOOP
    INSERT INTO delivery_requests (
      merchant_id,
      courier_id,
      status,
      source,
      external_order_id,
      declared_amount,
      pickup_address,
      delivery_address,
      recipient_name,
      recipient_phone,
      created_at
    ) VALUES (
      test_merchant_id,
      test_courier_id,
      'DELIVERED',
      'yemek_app',
      'YO-' || lpad((random() * 1000000)::bigint::text, 6, '0'),
      (random() * 200 + 100)::numeric(10,2),
      'Yemek App Restaurant',
      'Yemek App Müşteri Adresi ' || i,
      'Yemek Müşteri ' || i,
      '05' || lpad((random() * 1000000000)::bigint::text, 9, '0'),
      NOW() - (i || ' days')::interval
    );
  END LOOP;

  RAISE NOTICE 'Test verileri oluşturuldu!';
  RAISE NOTICE 'Merchant ID: %', test_merchant_id;
  RAISE NOTICE 'Oluşturulan delivery sayısı: 10';
END $$;

-- Kontrol et
SELECT 
  status,
  COUNT(*) as adet,
  SUM(declared_amount) as toplam_tutar
FROM delivery_requests
WHERE merchant_id = '4445ceef-0786-4ba6-a6cf-d13c21717bfe'
GROUP BY status
ORDER BY status;
