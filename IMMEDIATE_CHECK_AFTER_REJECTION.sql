-- 🔥 ACİL! RED ETME SONRASI HEMEN KONTROL

-- 1. Sipariş durumu şu anda ne?
SELECT 
  order_number,
  status,
  courier_id,
  rejected_by,
  rejection_count,
  rejection_reason,
  updated_at,
  'Red edildi mi?' as "Durum"
FROM delivery_requests
WHERE order_number = 'ONL2025110247';

-- 2. Trigger çalıştı mı? Yeniden atama yapıldı mı?
SELECT 
  dr.order_number,
  dr.status,
  
  -- Şu anki atanan kurye
  current_courier.full_name as "Şu Anki Kurye",
  current_courier.email as "Atanan Email",
  
  -- Red eden kurye
  rejected_courier.full_name as "Red Eden Kurye", 
  rejected_courier.email as "Red Eden Email",
  
  -- Test sonucu
  CASE 
    WHEN dr.courier_id = dr.rejected_by THEN '❌ HATA! Aynı kurye!'
    WHEN dr.courier_id IS NOT NULL AND dr.rejected_by IS NOT NULL AND dr.courier_id != dr.rejected_by 
      THEN '✅ BAŞARILI! Farklı kurye atandı!'
    WHEN dr.courier_id IS NULL AND dr.rejected_by IS NOT NULL
      THEN '⏳ Henüz yeniden atama yapılmadı (normal olabilir)'
    ELSE '❓ Belirsiz'
  END as "Test Sonucu"
  
FROM delivery_requests dr
LEFT JOIN users current_courier ON current_courier.id = dr.courier_id
LEFT JOIN users rejected_courier ON rejected_courier.id = dr.rejected_by
WHERE dr.order_number = 'ONL2025110247';

-- 3. Son 1 dakikada bildirim gitti mi?
SELECT 
  'Son bildirimler:' as "Başlık",
  n.title,
  n.message,
  n.created_at,
  u.full_name as "Alan Kurye"
FROM notifications n
LEFT JOIN users u ON u.id = n.user_id
WHERE n.created_at > NOW() - INTERVAL '1 minute'
ORDER BY n.created_at DESC;