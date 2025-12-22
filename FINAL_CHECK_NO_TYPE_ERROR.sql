-- ✅ EN KOLAY VE GÜVENLİ ÇÖZÜM
-- JOIN kullanarak tip hatası olmadan kontrol

-- 1. Red edilen teslimatlar - RED EDEN ≠ ATANAN mı?
SELECT 
  dr.order_number as "Sipariş",
  dr.status as "Durum",
  dr.rejection_count as "Red Sayısı",
  c.full_name as "Şu Anki Kurye",
  c.email as "Atanan Email",
  r.full_name as "Red Eden Kurye", 
  r.email as "Red Eden Email",
  
  -- Kontrol
  CASE 
    WHEN c.email = r.email THEN '❌ AYNI KİŞİ - HATA VAR!'
    WHEN c.email IS NOT NULL AND r.email IS NOT NULL AND c.email != r.email 
      THEN '✅ FARKLI KİŞİLER - DOĞRU'
    WHEN c.email IS NULL THEN '⏳ Henüz atama yapılmadı'
    ELSE '❓ Belirsiz'
  END as "Test Sonucu"
  
FROM delivery_requests dr
LEFT JOIN users c ON c.id = dr.courier_id
LEFT JOIN users r ON r.id = dr.rejected_by
WHERE dr.rejected_by IS NOT NULL
ORDER BY dr.created_at DESC;

-- 2. Özet rapor
SELECT 
  COUNT(*) as "Toplam Red Edilmiş Teslimat",
  SUM(CASE 
    WHEN c.email = r.email THEN 1 
    ELSE 0 
  END) as "❌ Aynı Kişiye Atananlar (HATA)",
  SUM(CASE 
    WHEN c.email != r.email THEN 1 
    ELSE 0 
  END) as "✅ Farklı Kişiye Atananlar (DOĞRU)",
  SUM(CASE 
    WHEN c.email IS NULL THEN 1 
    ELSE 0 
  END) as "⏳ Henüz Atama Yapılmayanlar"
FROM delivery_requests dr
LEFT JOIN users c ON c.id = dr.courier_id
LEFT JOIN users r ON r.id = dr.rejected_by
WHERE dr.rejected_by IS NOT NULL;

-- 3. ONL2025110246 özel kontrol
SELECT 
  'ONL2025110246 Siparişi' as "Başlık",
  c.full_name as "Atanan Kurye",
  r.full_name as "Red Eden Kurye",
  CASE 
    WHEN c.full_name = r.full_name THEN '❌ AYNI - SORUN VAR!'
    ELSE '✅ FARKLI - DOĞRU ÇALIŞIYOR'
  END as "Sonuç"
FROM delivery_requests dr
LEFT JOIN users c ON c.id = dr.courier_id
LEFT JOIN users r ON r.id = dr.rejected_by
WHERE dr.order_number = 'ONL2025110246';
