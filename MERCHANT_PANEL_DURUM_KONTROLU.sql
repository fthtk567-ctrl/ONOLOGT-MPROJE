-- ============================================
-- MERCHANT PANEL DURUM KONTROLÜ
-- Tarih: 20 Aralık 2025
-- ============================================

-- 1. Giriş yapan merchant ID'yi bulalım
SELECT 
  id,
  email,
  role,
  full_name,
  business_name,
  created_at
FROM users
WHERE role = 'merchant'
ORDER BY created_at DESC
LIMIT 5;

-- 2. Delivery Requests durumu (Raporlar sayfasının veri kaynağı)
SELECT 
  COUNT(*) as total_delivery_requests,
  COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END) as completed,
  COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled,
  COUNT(CASE WHEN status IN ('WAITING_COURIER', 'ASSIGNED', 'ACCEPTED', 'PICKED_UP') THEN 1 END) as pending,
  SUM(declared_amount) as total_amount
FROM delivery_requests;

-- 3. Merchant bazında delivery_requests
SELECT 
  u.business_name,
  u.email,
  COUNT(dr.id) as siparis_sayisi,
  SUM(dr.declared_amount) as toplam_tutar,
  COUNT(CASE WHEN dr.status = 'DELIVERED' THEN 1 END) as tamamlanan
FROM users u
LEFT JOIN delivery_requests dr ON u.id = dr.merchant_id
WHERE u.role = 'merchant'
GROUP BY u.id, u.business_name, u.email
ORDER BY siparis_sayisi DESC;

-- 4. Yemek App siparişleri (external_order_id olan)
SELECT 
  COUNT(*) as yemek_app_total,
  COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END) as delivered,
  COUNT(CASE WHEN status = 'WAITING_COURIER' THEN 1 END) as waiting,
  COUNT(CASE WHEN status = 'ASSIGNED' THEN 1 END) as assigned,
  MIN(created_at) as ilk_siparis,
  MAX(created_at) as son_siparis
FROM delivery_requests
WHERE source = 'yemek_app' OR external_order_id IS NOT NULL;

-- 5. Son 10 delivery_request
SELECT 
  id,
  merchant_id,
  status,
  source,
  external_order_id,
  declared_amount,
  created_at
FROM delivery_requests
ORDER BY created_at DESC
LIMIT 10;

-- 6. Merchant-Yemek App mapping kontrolü
SELECT 
  ym.yemek_app_restaurant_id,
  ym.onlog_merchant_id,
  u.business_name,
  u.email,
  ym.is_active,
  ym.created_at
FROM onlog_merchant_mapping ym
LEFT JOIN users u ON u.id = ym.onlog_merchant_id
ORDER BY ym.created_at DESC;

-- 7. Platform orders tablosu var mı? (Trendyol/Getir)
SELECT 
  COUNT(*) as total_platform_orders,
  platform,
  COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed
FROM platform_orders
GROUP BY platform;
