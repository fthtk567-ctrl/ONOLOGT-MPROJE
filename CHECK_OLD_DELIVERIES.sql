-- TEST SANAYI TOPTAN merchant'ın ESKİ TESLİMATLARINI bul
-- delivery_requests tablosundan komisyon bilgileriyle

SELECT 
  id,
  status,
  package_count,
  declared_amount,
  merchant_commission_rate,
  merchant_payment_due,
  system_commission,
  created_at,
  completed_at,
  delivered_at
FROM delivery_requests
WHERE merchant_id = (
  SELECT id FROM users WHERE email = 'onlogprojects@gmail.com'
)
ORDER BY created_at DESC
LIMIT 20;

-- Kaç tane tamamlanmış teslimat var?
SELECT 
  status,
  COUNT(*) as count,
  SUM(merchant_payment_due) as total_commission
FROM delivery_requests
WHERE merchant_id = (
  SELECT id FROM users WHERE email = 'onlogprojects@gmail.com'
)
GROUP BY status;
