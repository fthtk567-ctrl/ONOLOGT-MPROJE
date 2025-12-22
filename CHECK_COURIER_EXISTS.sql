-- ============================================
-- COURIER PUBLIC.USERS'DA VAR MI? KONTROL ET
-- ============================================

SELECT 
  id,
  email,
  full_name,
  role,
  is_available,
  created_at
FROM public.users
WHERE id = '250f4abe-858a-457b-b972-9a76348a07c2';

-- Eğer sonuç BOŞ ise → Courier EKLENMEDİ!
-- Eğer sonuç VAR ise → Courier VAR ama yine de foreign key hatası veriyor! (BU ÇOK GARIP!)
