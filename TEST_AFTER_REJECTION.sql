-- 🧪 RED ETME TESTİ SONRASI KONTROL

-- 1. ONL2025110247 siparişi red edildikten sonra
SELECT 
  order_number,
  status,
  courier_id,
  rejected_by,
  rejection_count,
  rejection_reason,
  updated_at,
  
  -- Yeni atanan kurye
  (SELECT full_name FROM users WHERE id = courier_id) as "Yeni Atanan Kurye",
  
  -- Red eden kurye  
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden Kurye",
  
  -- Kontrol
  CASE 
    WHEN courier_id = rejected_by THEN '❌ HATA! Aynı kurye atandı!'
    WHEN courier_id IS NOT NULL AND rejected_by IS NOT NULL AND courier_id != rejected_by 
      THEN '✅ DOĞRU! Farklı kurye atandı'
    WHEN courier_id IS NULL AND rejected_by IS NOT NULL
      THEN '⏳ Henüz yeniden atama yapılmadı'
    ELSE '❓ Belirsiz durum'
  END as "Test Sonucu"
  
FROM delivery_requests
WHERE order_number = 'ONL2025110247';

-- 2. Son 2 dakikadaki bildirimler (yeni atama var mı?)
SELECT 
  n.title,
  n.message,
  n.created_at,
  u.full_name as "Bildirim Alan Kurye",
  u.email
FROM notifications n
LEFT JOIN users u ON u.id = n.user_id  
WHERE n.created_at > NOW() - INTERVAL '2 minutes'
  AND n.type = 'delivery'
ORDER BY n.created_at DESC;

-- 3. Aktif kuryeler (kim atama alabilir?)
SELECT 
  full_name,
  email,
  is_active,
  is_available,
  status
FROM users
WHERE role = 'courier'
  AND is_active = true
  AND is_available = true
  AND status = 'approved'
ORDER BY full_name;