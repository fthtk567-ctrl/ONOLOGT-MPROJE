-- 🔧 SGK KURYE KAYIT VERİLERİ SORUNU DÜZELTİLİYOR (v2 - Telefon 0 ekleme + TCKN hatası düzeltildi)
-- Bu SQL Supabase Dashboard > SQL Editor'da çalıştırılacak

-- 1. ESKİ TRIGGER FONKSİYONUNU SİL
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. YENİ TRIGGER FONKSİYONU - VERİLERİ DOĞRU PARSE EDİYOR
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
  v_metadata jsonb;
  v_payment_settings jsonb;
  v_commission_settings jsonb;
  v_phone text;
BEGIN
  -- Metadata'yı al
  v_metadata := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
  
  -- Telefon numarasını düzenle (başında 0 yoksa ekle)
  v_phone := COALESCE(v_metadata->>'phone', '');
  IF v_phone ~ '^[1-9][0-9]{9}$' THEN
    -- 5551234567 formatında → 05551234567 yap
    v_phone := '0' || v_phone;
  END IF;
  
  -- Payment settings oluştur (IBAN bilgileri)
  v_payment_settings := jsonb_build_object(
    'iban', COALESCE(v_metadata->>'iban', ''),
    'bank_name', COALESCE(v_metadata->>'bank_name', ''),
    'account_holder', COALESCE(v_metadata->>'account_holder', '')
  );
  
  -- Commission settings oluştur (Araç bilgileri)
  v_commission_settings := jsonb_build_object(
    'vehicle_type', COALESCE(v_metadata->>'vehicle_type', ''),
    'vehicle_plate', COALESCE(v_metadata->>'vehicle_plate', ''),
    'vehicle_model', COALESCE(v_metadata->>'vehicle_model', '')
  );
  
  -- Users tablosuna ekle - TÜM BİLGİLERİ PARSE EDEREK
  INSERT INTO public.users (
    id,
    email,
    full_name,
    phone,
    role,
    courier_type,
    city,
    district,
    address,
    payment_settings,
    commission_settings,
    status,
    is_active,
    metadata,
    created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(v_metadata->>'full_name', ''),
    v_phone, -- Başında 0 ile
    COALESCE(v_metadata->>'role', 'courier'),
    COALESCE(v_metadata->>'courier_type', NULL),
    COALESCE(v_metadata->>'city', ''),
    COALESCE(v_metadata->>'district', ''),
    COALESCE(v_metadata->>'address', ''),
    v_payment_settings,
    v_commission_settings,
    'pending', -- Admin onayı bekliyor
    false,     -- Henüz aktif değil
    v_metadata, -- Ham metadata'yı da sakla
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    courier_type = EXCLUDED.courier_type,
    city = EXCLUDED.city,
    district = EXCLUDED.district,
    address = EXCLUDED.address,
    payment_settings = EXCLUDED.payment_settings,
    commission_settings = EXCLUDED.commission_settings,
    metadata = EXCLUDED.metadata;
  
  RETURN NEW;
END;
$$;

-- 3. TRIGGER'I YENİDEN OLUŞTUR
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 4. ESKİ KAYITLARI DÜZELTİR (metadata'dan parse et)
UPDATE users u
SET
  full_name = COALESCE(u.metadata->>'full_name', u.full_name),
  -- Telefon başına 0 ekle (5551234567 → 05551234567)
  phone = CASE 
    WHEN COALESCE(u.metadata->>'phone', '') ~ '^[1-9][0-9]{9}$' 
    THEN '0' || COALESCE(u.metadata->>'phone', '')
    ELSE COALESCE(u.metadata->>'phone', u.phone)
  END,
  courier_type = COALESCE(u.metadata->>'courier_type', u.courier_type),
  city = COALESCE(u.metadata->>'city', u.city),
  district = COALESCE(u.metadata->>'district', u.district),
  address = COALESCE(u.metadata->>'address', u.address),
  payment_settings = jsonb_build_object(
    'iban', COALESCE(u.metadata->>'iban', ''),
    'bank_name', COALESCE(u.metadata->>'bank_name', ''),
    'account_holder', COALESCE(u.metadata->>'account_holder', '')
  ),
  commission_settings = jsonb_build_object(
    'vehicle_type', COALESCE(u.metadata->>'vehicle_type', ''),
    'vehicle_plate', COALESCE(u.metadata->>'vehicle_plate', ''),
    'vehicle_model', COALESCE(u.metadata->>'vehicle_model', '')
  )
WHERE u.role = 'courier'
  AND u.metadata IS NOT NULL
  AND u.metadata != '{}'::jsonb;

-- ✅ TAMAM! Artık kayıt verileri doğru kaydolacak!

-- Test et:
SELECT 
  id,
  email,
  full_name,
  phone, -- Artık başında 0 ile gelecek
  city,
  district,
  courier_type,
  commission_settings->>'vehicle_type' as arac_tipi,
  commission_settings->>'vehicle_plate' as plaka,
  payment_settings->>'iban' as iban,
  status
FROM users
WHERE role = 'courier'
ORDER BY created_at DESC
LIMIT 5;
