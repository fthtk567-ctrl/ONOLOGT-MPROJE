-- RED EDİLMİŞ TESLİMATLARI VE YENİDEN ATAMA DURUMUNU KONTROL ET

-- 1. Reddedilmiş teslimatlar
SELECT 
  id,
  order_number,
  status,
  rejected_by,
  rejection_reason,
  courier_id as current_courier,
  merchant_id,
  declared_amount,
  created_at,
  updated_at
FROM delivery_requests
WHERE rejected_by IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 2. Yeniden atama durumu (rejected_by dolu AMA courier_id de dolu = başka kuryeye atandı)
SELECT 
  dr.id,
  dr.order_number,
  dr.status,
  dr.rejected_by,
  u1.full_name as rejected_by_name,
  dr.courier_id,
  u2.full_name as current_courier_name,
  dr.rejection_reason,
  dr.declared_amount,
  dr.created_at
FROM delivery_requests dr
LEFT JOIN users u1 ON dr.rejected_by = u1.id
LEFT JOIN users u2 ON dr.courier_id = u2.id
WHERE dr.rejected_by IS NOT NULL
ORDER BY dr.created_at DESC
LIMIT 10;

-- 3. Red edilip YENİ KURYEYE ATANAN teslimatlar
SELECT 
  dr.id,
  dr.order_number,
  dr.status,
  u1.full_name as "Red Eden Kurye",
  u2.full_name as "Yeni Atanan Kurye",
  dr.declared_amount,
  dr.created_at
FROM delivery_requests dr
LEFT JOIN users u1 ON dr.rejected_by = u1.id
LEFT JOIN users u2 ON dr.courier_id = u2.id
WHERE dr.rejected_by IS NOT NULL 
  AND dr.courier_id IS NOT NULL
  AND dr.rejected_by != dr.courier_id
ORDER BY dr.created_at DESC;

-- 4. Red edilip HENÜZ YENİ KURYE BULUNAMAYAN teslimatlar
SELECT 
  dr.id,
  dr.order_number,
  dr.status,
  u.full_name as "Red Eden Kurye",
  dr.rejection_reason,
  dr.declared_amount,
  dr.created_at
FROM delivery_requests dr
LEFT JOIN users u ON dr.rejected_by = u.id
WHERE dr.rejected_by IS NOT NULL 
  AND (dr.courier_id IS NULL OR dr.status = 'pending')
ORDER BY dr.created_at DESC;

-- 5. Müsait kurye sayısı
SELECT 
  COUNT(*) as musait_kurye_sayisi,
  STRING_AGG(full_name, ', ') as musait_kuryeler
FROM users
WHERE role = 'courier'
  AND is_available = true
  AND status = 'approved';
