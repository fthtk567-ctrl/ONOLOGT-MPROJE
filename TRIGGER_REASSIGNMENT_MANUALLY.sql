-- Mevcut reddedilmiş siparişleri manuel tetikle

-- ONL2025110243 için kurye atama tetikle
UPDATE delivery_requests
SET updated_at = NOW()
WHERE order_number = 'ONL2025110243'
  AND courier_id IS NULL
  AND rejected_by IS NOT NULL;

-- ONL2025110242 için kurye atama tetikle  
UPDATE delivery_requests
SET updated_at = NOW()
WHERE order_number = 'ONL2025110242'
  AND courier_id IS NULL
  AND rejected_by IS NOT NULL;

SELECT 'Tetikleme tamamlandı - şimdi tekrar durumu kontrol et!' as status;
