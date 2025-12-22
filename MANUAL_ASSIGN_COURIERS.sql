-- Manuel olarak müsait kuryeye ata (trigger'ı bypass edip test edelim)

-- PANEK TEST kuryesine ata
UPDATE delivery_requests
SET 
  courier_id = '91945142-093c-4be2-873c-8dc8b4e84ba9'::uuid,
  status = 'assigned',
  assigned_at = NOW(),
  rejection_count = 1
WHERE order_number = 'ONL2025110243';

-- kadirhan çekirdek kuryesine ata
UPDATE delivery_requests
SET 
  courier_id = 'c15f320f-44d6-40b3-8849-7a155af35123'::uuid,
  status = 'assigned',
  assigned_at = NOW(),
  rejection_count = 1
WHERE order_number = 'ONL2025110242';

SELECT '✅ Manuel atama yapıldı - merchant panelinde kontrol et!' as status;
