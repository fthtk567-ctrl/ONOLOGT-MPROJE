-- ✅ EN BASİT RED KONTROLÜ - TİP SORUNU YOK

-- 1. Red edilen teslimatlar - isimlerle
SELECT 
  dr.order_number,
  dr.status,
  dr.rejection_count,
  
  -- Kurye isimleri
  c.full_name as "Şu Anki Kurye",
  r.full_name as "Red Eden Kurye",
  
  -- Aynı mı?
  CASE 
    WHEN c.full_name = r.full_name THEN '❌ AYNI KİŞİ!'
    WHEN c.full_name IS NOT NULL AND r.full_name IS NOT NULL THEN '✅ FARKLI KİŞİ'
    WHEN r.full_name IS NOT NULL AND c.full_name IS NULL THEN '⏳ Atama bekleniyor'
    ELSE '➖'
  END as "Kontrol"
  
FROM delivery_requests dr
LEFT JOIN users c ON c.id = dr.courier_id
LEFT JOIN users r ON r.id = dr.rejected_by
WHERE dr.rejected_by IS NOT NULL
ORDER BY dr.created_at DESC;

-- 2. ONL2025110246 siparişinin detayı
SELECT 
  dr.order_number,
  dr.status,
  c.full_name as "Atanan",
  c.email as "Atanan Email",
  r.full_name as "Red Eden",
  r.email as "Red Eden Email"
FROM delivery_requests dr
LEFT JOIN users c ON c.id = dr.courier_id
LEFT JOIN users r ON r.id = dr.rejected_by
WHERE dr.order_number = 'ONL2025110246';
