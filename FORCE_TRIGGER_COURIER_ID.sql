-- Trigger'ı tetiklemek için courier_id'yi değiştir

-- Önce bir değer ata (dummy), sonra NULL yap
UPDATE delivery_requests
SET courier_id = '00000000-0000-0000-0000-000000000000'::uuid
WHERE order_number IN ('ONL2025110243', 'ONL2025110242')
  AND courier_id IS NULL;

-- Şimdi tekrar NULL yap - bu trigger'ı tetikleyecek
UPDATE delivery_requests
SET courier_id = NULL
WHERE order_number IN ('ONL2025110243', 'ONL2025110242')
  AND courier_id = '00000000-0000-0000-0000-000000000000'::uuid;

SELECT 'Trigger tetiklendi!' as status;
