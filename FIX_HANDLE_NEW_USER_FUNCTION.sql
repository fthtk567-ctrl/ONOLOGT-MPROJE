-- ═══════════════════════════════════════════════════
-- ALTERNATİF ÇÖZÜM: handle_new_user FONKSİYONUNU DÜZELTELİM
-- Metadata'dan 'role' okusun, yoksa NULL bıraksın (trigger otomatik eklemesin)
-- ═══════════════════════════════════════════════════

-- Eski fonksiyonu değiştir
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  -- Sadece metadata'da 'role' varsa users tablosuna ekle
  IF (NEW.raw_user_meta_data->>'role') IS NOT NULL THEN
    INSERT INTO public.users (
      id,
      email,
      role,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'role', 'courier'), -- metadata'dan oku
      NOW(),
      NOW()
    );
  END IF;
  
  RETURN NEW;
END;
$function$;

-- ═══════════════════════════════════════════════════
-- AÇIKLAMA:
-- Artık Auth'a kayıt olurken metadata göndermezsen, 
-- users tablosuna otomatik EKLENMEYECEK!
-- Sen merchant_registration_screen.dart'ta zaten manuel INSERT yapıyorsun,
-- bu yüzden sorun çözülecek.
-- ═══════════════════════════════════════════════════

-- Test et - son kayıtlar
SELECT id, email, role, created_at FROM users ORDER BY created_at DESC LIMIT 5;
