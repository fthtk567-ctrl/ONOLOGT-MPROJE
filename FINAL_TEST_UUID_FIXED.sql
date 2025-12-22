-- ✅ ARTIK UUID - SON TEST

-- 1. Red eden = Atanan mı? (Direkt UUID karşılaştırma)
SELECT 
  order_number as "Sipariş",
  courier_id,
  rejected_by,
  CASE 
    WHEN courier_id = rejected_by THEN '❌ AYNI KİŞİ - HATA!'
    WHEN rejected_by IS NOT NULL AND courier_id != rejected_by THEN '✅ FARKLI KİŞİ - DOĞRU'
    WHEN rejected_by IS NULL THEN '➖ Henüz red edilmedi'
    WHEN courier_id IS NULL THEN '⏳ Atama bekleniyor'
    ELSE '❓ Belirsiz'
  END as "Kontrol"
FROM delivery_requests
WHERE rejected_by IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 2. Kurye isimleriyle detaylı kontrol
SELECT 
  dr.order_number as "Sipariş",
  c.full_name as "Atanan Kurye",
  r.full_name as "Red Eden Kurye",
  CASE 
    WHEN dr.courier_id = dr.rejected_by THEN '❌ AYNI!'
    WHEN dr.courier_id != dr.rejected_by THEN '✅ FARKLI!'
    ELSE '❓'
  END as "UUID Kontrolü",
  CASE 
    WHEN c.full_name = r.full_name THEN '❌ AYNI İSİM!'
    WHEN c.full_name != r.full_name THEN '✅ FARKLI İSİM!'
    ELSE '❓'
  END as "İsim Kontrolü"
FROM delivery_requests dr
LEFT JOIN users c ON c.id = dr.courier_id
LEFT JOIN users r ON r.id = dr.rejected_by
WHERE dr.rejected_by IS NOT NULL
ORDER BY dr.created_at DESC
LIMIT 10;

-- 3. Özet rapor
SELECT 
  COUNT(*) as "Toplam Red Edilen",
  SUM(CASE WHEN courier_id = rejected_by THEN 1 ELSE 0 END) as "❌ Aynı Kişi (HATA)",
  SUM(CASE WHEN courier_id != rejected_by THEN 1 ELSE 0 END) as "✅ Farklı Kişi (DOĞRU)",
  SUM(CASE WHEN courier_id IS NULL THEN 1 ELSE 0 END) as "⏳ Henüz Atama Yok"
FROM delivery_requests
WHERE rejected_by IS NOT NULL;

-- 4. ONL2025110246 spesifik kontrol
SELECT 
  order_number,
  (SELECT full_name FROM users WHERE id = courier_id) as "Atanan",
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden",
  CASE 
    WHEN courier_id = rejected_by THEN '❌ AYNI - HATA VAR!'
    WHEN courier_id != rejected_by THEN '✅ FARKLI - DOĞRU!'
    ELSE '❓'
  END as "Sonuç"
FROM delivery_requests
WHERE order_number = 'ONL2025110246';

-- 5. Trigger fonksiyonu hala doğru mu?
SELECT 
  routine_name as "Fonksiyon",
  CASE 
    WHEN routine_definition LIKE '%id != NEW.rejected_by%' THEN '✅ Kontrol VAR'
    ELSE '❌ Kontrol YOK'
  END as "Red Eden Hariç mi?"
FROM information_schema.routines
WHERE routine_name = 'auto_reassign_rejected_delivery';
