-- 🔍 RED EDEN KURYE TEKRAR ATANIR MI? KONTROL SORGUSU

-- 1. Belirli bir teslimat isteğinin red geçmişi
SELECT 
  dr.id,
  dr.order_number,
  dr.status,
  dr.courier_id,
  dr.rejected_by,
  dr.rejection_count,
  dr.rejection_reason,
  
  -- Şu anki kurye
  current_courier.full_name as "Şu Anki Kurye",
  
  -- Red eden kurye
  rejected_courier.full_name as "Red Eden Kurye",
  
  -- Aynı mı?
  CASE 
    WHEN dr.courier_id::TEXT = dr.rejected_by::TEXT THEN '❌ HATA! Red eden kurye tekrar atandı!'
    WHEN dr.rejected_by IS NOT NULL AND dr.courier_id::TEXT != dr.rejected_by::TEXT THEN '✅ DOĞRU! Başka kurye atandı'
    WHEN dr.rejected_by IS NULL THEN '➖ Henüz red edilmedi'
    ELSE '❓ Belirsiz'
  END as "Durum Kontrolü"
  
FROM delivery_requests dr
LEFT JOIN users current_courier ON current_courier.id = dr.courier_id
LEFT JOIN users rejected_courier ON rejected_courier.id = dr.rejected_by
WHERE dr.rejected_by IS NOT NULL  -- Sadece red edilmiş teslimatlar
ORDER BY dr.created_at DESC
LIMIT 20;

-- 2. Trigger fonksiyonunun red etme kontrolünü göster
SELECT 
  routine_name as "Fonksiyon",
  routine_definition as "Kod"
FROM information_schema.routines
WHERE routine_name = 'auto_reassign_rejected_delivery'
  AND routine_schema = 'public';

-- 3. Specific bir teslimat için kontrol
-- (order_number'ı değiştir)
SELECT 
  order_number,
  status,
  courier_id,
  rejected_by,
  CASE 
    WHEN courier_id::TEXT = rejected_by::TEXT THEN '❌ SORUN VAR!'
    WHEN rejected_by IS NOT NULL AND courier_id::TEXT != rejected_by::TEXT THEN '✅ DOĞRU'
    ELSE '➖ Red edilmedi'
  END as "Red Eden = Atanan?"
FROM delivery_requests
WHERE order_number = 'ONL2025110246';  -- ← Buraya sipariş numarasını yaz

-- 4. Tüm kuryelerin red ettikleri teslimatlar
SELECT 
  u.full_name as "Kurye",
  COUNT(DISTINCT dr.id) as "Red Ettiği Teslimat Sayısı",
  ARRAY_AGG(DISTINCT dr.order_number) as "Red Ettiği Siparişler"
FROM users u
LEFT JOIN delivery_requests dr ON dr.rejected_by = u.id
WHERE u.role = 'courier'
GROUP BY u.id, u.full_name
ORDER BY COUNT(DISTINCT dr.id) DESC;

-- =====================================================
-- ✅ SONUÇ:
-- =====================================================
-- 
-- Trigger fonksiyonunda şu satır VAR:
-- AND id != NEW.rejected_by
-- 
-- Bu satır sayesinde:
-- - Kurye A sipariş #123'ü reddetti
-- - Sipariş #123 tekrar atanırken Kurye A HARİÇ tutulur
-- - Başka bir kurye (B, C, D...) atanır
-- - Kurye A o siparişe BİR DAHA ATANAMAZ
-- 
-- AMA:
-- - Kurye A başka siparişlere (farklı teslimatlar) atanabilir
-- - Sadece red ettiği spesifik teslimat için engellenmiştir
