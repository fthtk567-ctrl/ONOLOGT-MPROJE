-- 📊 SORUN TESPİTİ: is_active=false olan kuryeye neden atama yapıldı?

-- 1. Problematik teslimat isteğini incele
SELECT 
  dr.id,
  dr.order_number,
  dr.status,
  dr.courier_id,
  dr.merchant_id,
  dr.rejected_by,
  dr.rejection_count,
  dr.created_at,
  dr.updated_at,
  -- Atanan kurye bilgisi
  u.full_name as "Atanan Kurye",
  u.is_active as "Kurye is_active",
  u.is_available as "Kurye is_available",
  u.status as "Kurye status"
FROM delivery_requests dr
LEFT JOIN users u ON u.id = dr.courier_id
WHERE dr.order_number = 'ONL2025110244'
ORDER BY dr.created_at DESC;

-- 2. TEST KURYE'nin detaylarına bak
SELECT 
  id,
  full_name,
  email,
  role,
  status,
  is_active,
  is_available,
  penalty_until,
  created_at,
  updated_at,
  CASE 
    WHEN is_active = false THEN '❌ HESAP PASİF - ATAMA YAPILMAMALI!'
    WHEN is_available = false THEN '🔴 OFFLINE (mesaide değil)'
    WHEN status != 'approved' THEN '⚠️ ONAYSIZ'
    WHEN is_active = true AND is_available = true AND status = 'approved' THEN '✅ SEÇİLEBİLİR'
    ELSE '❓ DİĞER'
  END as "Atanabilir mi?"
FROM users
WHERE id = '4ff777e0-5bcc-4c21-8785-c650f5667d86';

-- 3. Şu anda SEÇİLEBİLİR olan kuryeler
SELECT 
  id,
  full_name,
  email,
  is_active,
  is_available,
  status,
  penalty_until,
  '✅ SEÇİLEBİLİR' as "Durum"
FROM users
WHERE role = 'courier'
  AND status = 'approved'
  AND is_active = true           -- ← BU KONTROL EKSİKTİ!
  AND is_available = true
  AND (penalty_until IS NULL OR penalty_until <= NOW())
ORDER BY full_name;

-- 4. Mevcut trigger fonksiyonunu kontrol et
SELECT 
  proname as "Fonksiyon Adı",
  prosrc as "Fonksiyon Kodu"
FROM pg_proc
WHERE proname = 'auto_reassign_rejected_delivery';
