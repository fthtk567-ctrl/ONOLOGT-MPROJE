-- 🔍 TÜM ATAMA FONKSİYONLARINI VE TRİGGERLARI KONTROL ET
-- Sorun: is_active kontrolü ekledik ama hala false olan kuryeye atıyor

-- 1. auto_reassign fonksiyonunun güncel kodunu göster
SELECT 
  proname as "Fonksiyon",
  prosrc as "Kod"
FROM pg_proc
WHERE proname = 'auto_reassign_rejected_delivery';

-- 2. İlgili tüm triggerleri listele
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE event_object_table = 'delivery_requests'
ORDER BY trigger_name;

-- 3. Tüm fonksiyonları kontrol et (kurye atama yapan)
SELECT 
  proname as "Fonksiyon Adı",
  CASE 
    WHEN prosrc LIKE '%is_active%' THEN '✅ is_active kontrolü VAR'
    ELSE '❌ is_active kontrolü YOK'
  END as "is_active Check",
  CASE 
    WHEN prosrc LIKE '%courier_id%' THEN '🎯 Kurye atama yapıyor'
    ELSE '➖ Kurye ataması yok'
  END as "Atama Yapıyor mu?"
FROM pg_proc
WHERE prosrc LIKE '%courier%'
  AND prosrc LIKE '%SELECT%'
  AND proname LIKE '%assign%' OR proname LIKE '%delivery%' OR proname LIKE '%courier%'
ORDER BY proname;

-- 4. Son oluşturulan teslimat isteği
SELECT 
  dr.id,
  dr.order_number,
  dr.status,
  dr.courier_id,
  u.full_name as "Atanan Kurye",
  u.is_active as "Kurye is_active ❌",
  u.is_available as "Kurye is_available",
  dr.created_at,
  dr.updated_at
FROM delivery_requests dr
LEFT JOIN users u ON u.id = dr.courier_id
WHERE dr.order_number = 'ONL2025110246'
ORDER BY dr.created_at DESC;
