-- 🔍 BASİT RED KONTROLÜ - UUID Sorunsuz Versiyon

-- 1. Red edilmiş teslimatlar ve durum kontrolü
SELECT 
  order_number as "Sipariş No",
  status as "Durum",
  rejection_count as "Red Sayısı",
  rejection_reason as "Red Nedeni",
  
  -- Kurye isimleri (ID yerine)
  (SELECT full_name FROM users WHERE id = dr.courier_id) as "Şu Anki Kurye",
  (SELECT full_name FROM users WHERE id = dr.rejected_by) as "Red Eden Kurye",
  
  -- Kontrol
  CASE 
    WHEN courier_id IS NOT NULL AND rejected_by IS NOT NULL THEN
      CASE 
        WHEN (SELECT full_name FROM users WHERE id = dr.courier_id) = 
             (SELECT full_name FROM users WHERE id = dr.rejected_by) 
        THEN '❌ AYNI KİŞİ! (Hata var)'
        ELSE '✅ FARKLI KİŞİ (Doğru)'
      END
    WHEN rejected_by IS NULL THEN '➖ Henüz red edilmedi'
    WHEN courier_id IS NULL THEN '⏳ Atama bekleniyor'
    ELSE '❓ Belirsiz'
  END as "Kontrol"
  
FROM delivery_requests dr
WHERE rejected_by IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 2. Spesifik sipariş kontrolü (daha basit)
SELECT 
  order_number,
  
  -- Mevcut kurye
  (SELECT full_name FROM users WHERE id = courier_id) as "Atanan Kurye",
  (SELECT email FROM users WHERE id = courier_id) as "Atanan Email",
  
  -- Red eden kurye
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden Kurye",
  (SELECT email FROM users WHERE id = rejected_by) as "Red Eden Email",
  
  -- Sonuç
  CASE 
    WHEN (SELECT email FROM users WHERE id = courier_id) = 
         (SELECT email FROM users WHERE id = rejected_by)
    THEN '❌ AYNI KİŞİ - SORUN VAR!'
    ELSE '✅ FARKLI KİŞİLER - DOĞRU'
  END as "Test Sonucu"
  
FROM delivery_requests
WHERE order_number = 'ONL2025110246';

-- 3. Tüm red edilen teslimatlar - özet
SELECT 
  COUNT(*) as "Toplam Red Edilen",
  COUNT(DISTINCT rejected_by) as "Kaç Farklı Kurye Red Etti",
  COUNT(CASE WHEN status = 'assigned' THEN 1 END) as "Yeniden Atanan",
  COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as "İptal Edilen"
FROM delivery_requests
WHERE rejected_by IS NOT NULL;

-- 4. Red eden kuryeler listesi
SELECT 
  u.full_name as "Kurye",
  u.email,
  u.is_active as "Aktif mi?",
  u.is_available as "Mesaide mi?",
  COUNT(dr.id) as "Red Ettiği Teslimat Sayısı"
FROM users u
LEFT JOIN delivery_requests dr ON dr.rejected_by = u.id
WHERE u.role = 'courier'
GROUP BY u.id, u.full_name, u.email, u.is_active, u.is_available
HAVING COUNT(dr.id) > 0
ORDER BY COUNT(dr.id) DESC;
