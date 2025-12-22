-- 🔍 TRİGGER NEDEN ÇALIŞMADI KONTROL

-- 1. Trigger koşulu - status pending mi olmalı?
SELECT 
  'Trigger Koşulu Kontrol' as "Test",
  id,
  status,
  courier_id,
  rejected_by,
  CASE 
    WHEN status = 'pending' AND courier_id IS NULL AND rejected_by IS NOT NULL 
      THEN '✅ Trigger koşulu SAĞLANIYOR'
    WHEN status = 'rejected' AND rejected_by IS NOT NULL
      THEN '❌ Status REJECTED - Trigger çalışmaz!'
    ELSE '❓ Diğer durum'
  END as "Trigger Çalışır mı?"
FROM delivery_requests
WHERE id = 'ONL2025110247';

-- 2. Manuel olarak pending'e alalım (trigger tetiklenir)
-- ⚠️ Bu SQL'i çalıştırmadan önce yukarıdakini kontrol et!

UPDATE delivery_requests 
SET 
  status = 'pending',
  updated_at = NOW()
WHERE id = 'ONL2025110247';

-- 3. Trigger çalıştıktan sonra tekrar kontrol
SELECT 
  'Trigger Sonrası' as "Test",
  id,
  status,
  courier_id,
  rejected_by,
  (SELECT full_name FROM users WHERE id = courier_id) as "Yeni Atanan",
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden",
  updated_at
FROM delivery_requests
WHERE id = 'ONL2025110247';

-- 4. Yeni bildirim oluştu mu?
SELECT 
  n.title,
  n.message,
  n.created_at,
  u.full_name as "Bildirim Alan"
FROM notifications n
LEFT JOIN users u ON u.id = n.user_id
WHERE n.created_at > NOW() - INTERVAL '30 seconds'
ORDER BY n.created_at DESC;