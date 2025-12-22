-- 🔍 ONL2025110247 SİPARİŞİNİN GERÇEK ZAMANLI TAKİBİ

-- 1. Siparişin şu anki durumu
SELECT 
  order_number,
  status,
  courier_id,
  merchant_id,
  created_at,
  updated_at,
  CASE 
    WHEN courier_id IS NOT NULL THEN 'Atama yapıldı'
    WHEN status = 'pending' THEN 'Kurye aranıyor'
    ELSE 'Diğer'
  END as "Durum"
FROM delivery_requests
WHERE order_number = 'ONL2025110247';

-- 2. PANEK TEST kuryesinin durumu
SELECT 
  full_name,
  email,
  is_active,
  is_available, 
  status,
  current_location,
  CASE 
    WHEN is_active = true AND is_available = true AND status = 'approved' 
      THEN '✅ ATAMA ALABİLİR'
    WHEN is_active = false THEN '❌ HESAP PASİF'
    WHEN is_available = false THEN '🔴 OFFLINE'
    WHEN status != 'approved' THEN '⚠️ ONAYSIZ'
    ELSE '❓ DİĞER'
  END as "Atama Durumu"
FROM users
WHERE email = 'fatihteke@panek.com.tr';

-- 3. Tüm aktif kuryeler
SELECT 
  full_name,
  email,
  is_active,
  is_available,
  status,
  '✅ MÜSAİT' as durum
FROM users
WHERE role = 'courier'
  AND is_active = true
  AND is_available = true  
  AND status = 'approved'
ORDER BY full_name;

-- 4. Son 5 dakikadaki notifications
SELECT 
  n.title,
  n.message,
  n.type,
  n.created_at,
  u.full_name as "Alıcı"
FROM notifications n
LEFT JOIN users u ON u.id = n.user_id
WHERE n.created_at > NOW() - INTERVAL '5 minutes'
ORDER BY n.created_at DESC;