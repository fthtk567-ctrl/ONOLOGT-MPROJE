-- 🔍 DOĞRU UUID'Yİ BUL VE TESLİMAT TESTİ YAP

-- 1. ONL2025110247 siparişinin gerçek UUID'sini bul
SELECT 
  id,
  status,
  courier_id,
  rejected_by,
  created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 10;

-- 2. Yukarıdan ONL2025110247'nin UUID'sini kopyala ve aşağıya yapıştır
-- Örnek UUID: 12345678-1234-1234-1234-123456789012

-- 3. UUID ile kontrol (UUID'yi yukarıdan kopyala!)
SELECT 
  id,
  status,
  courier_id,
  rejected_by
FROM delivery_requests
WHERE id = '12345678-1234-1234-1234-123456789012';  -- ← Buraya gerçek UUID'yi yapıştır

-- 4. UUID ile UPDATE (UUID'yi yukarıdan kopyala!)
UPDATE delivery_requests 
SET status = 'pending'
WHERE id = '12345678-1234-1234-1234-123456789012';  -- ← Buraya gerçek UUID'yi yapıştır

-- 5. Sonuç kontrol (UUID'yi yukarıdan kopyala!)
SELECT 
  id,
  status,
  courier_id,
  rejected_by,
  (SELECT full_name FROM users WHERE id = courier_id) as "Atanan",
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden"
FROM delivery_requests
WHERE id = '12345678-1234-1234-1234-123456789012';  -- ← Buraya gerçek UUID'yi yapıştır