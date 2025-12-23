-- TEST TESLİMAT KAYDI OLUŞTUR

-- 1. Önce delivery_requests tablosu yapısını kontrol et
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'delivery_requests'
ORDER BY ordinal_position;

-- 2. Kurye için test teslimat kaydı ekle
INSERT INTO delivery_requests (
  merchant_id,
  courier_id,
  merchant_name,
  pickup_location,
  delivery_location,
  declared_amount,
  courier_payment_due,
  merchant_payment_due,
  system_commission,
  status,
  created_at,
  assigned_at,
  picked_up_at,
  completed_at
) VALUES (
  (SELECT id FROM users WHERE role = 'merchant' LIMIT 1), -- İlk merchant
  '250f4abe-858a-457b-b972-9a76340b07c2', -- Fatih'in courier ID'si
  'Test Restaurant - Pizza Palace',
  '{"address": "Test Restoran, Konya Merkez", "lat": 37.8715, "lng": 32.4846}'::jsonb,
  '{"address": "Test Müşteri, Meram", "lat": 37.8652, "lng": 32.4721}'::jsonb,
  100.00, -- Sipariş tutarı (100 TL)
  18.00, -- Kurye kazancı (%18 = 18 TL)
  20.00, -- Merchant ödemesi (%20 = 20 TL)
  2.00, -- Sistem komisyonu (20 - 18 = 2 TL)
  'completed', -- Tamamlandı
  NOW() - INTERVAL '3 hours', -- 3 saat önce oluşturuldu
  NOW() - INTERVAL '2 hours 50 minutes', -- 2 saat 50 dk önce atandı
  NOW() - INTERVAL '2 hours 30 minutes', -- 2 saat 30 dk önce toplandı
  NOW() - INTERVAL '2 hours' -- 2 saat önce teslim edildi
);

-- 3. Kayıt oluşturuldu mu kontrol et
SELECT 
  id,
  merchant_name,
  declared_amount,
  courier_payment_due,
  status,
  created_at,
  completed_at
FROM delivery_requests
WHERE courier_id = '250f4abe-858a-457b-b972-9a76340b07c2'
ORDER BY created_at DESC
LIMIT 5;
