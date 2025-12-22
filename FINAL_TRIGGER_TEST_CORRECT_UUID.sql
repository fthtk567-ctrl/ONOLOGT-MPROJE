-- 🚀 TRİGGER TETİKLE - DOĞRU UUID İLE

-- 1. Mevcut durum
SELECT 
  id,
  status,
  courier_id,
  rejected_by
FROM delivery_requests
WHERE id = 'b2be4262-96a1-43c9-8de9-04603bf5485a';

-- 2. PENDING'E AL (Trigger tetiklenecek!)
UPDATE delivery_requests 
SET status = 'pending'
WHERE id = 'b2be4262-96a1-43c9-8de9-04603bf5485a';

-- 3. Hemen sonrası kontrol (Trigger çalıştı mı?)
SELECT 
  id,
  status,
  courier_id,
  rejected_by,
  (SELECT full_name FROM users WHERE id = courier_id) as "Yeni Atanan Kurye",
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden Kurye",
  CASE 
    WHEN courier_id IS NOT NULL AND rejected_by IS NOT NULL AND courier_id != rejected_by 
      THEN '✅ BAŞARILI! Farklı kurye atandı!'
    WHEN courier_id IS NULL 
      THEN '⏳ Henüz atama yapılmadı'
    WHEN courier_id = rejected_by 
      THEN '❌ HATA! Aynı kurye atandı!'
    ELSE '❓ Belirsiz'
  END as "Test Sonucu"
FROM delivery_requests
WHERE id = 'b2be4262-96a1-43c9-8de9-04603bf5485a';