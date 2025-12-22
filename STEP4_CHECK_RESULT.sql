-- 🎯 ADIM 4: SONUÇ KONTROL
SELECT 
  status,
  (SELECT full_name FROM users WHERE id = courier_id) as "Atanan Kurye",
  (SELECT full_name FROM users WHERE id = rejected_by) as "Red Eden"
FROM delivery_requests
WHERE id = 'b2be4262-96a1-43c9-8de9-04603bf5485a';