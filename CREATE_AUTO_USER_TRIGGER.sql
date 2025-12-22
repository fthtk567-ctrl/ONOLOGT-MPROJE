-- OTOMATIK USER KAYDI TRIGGER
-- Auth'a kullanıcı eklenince otomatik users tablosuna ekler
-- Email onayını etkilemez, sadece rate limit sorununu çözer

-- Önce trigger varsa sil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Trigger fonksiyonunu oluştur - RLS bypass için service_role kullan
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Auth'dan gelen user'ı users tablosuna ekle (RLS bypass)
  INSERT INTO public.users (
    id,
    email,
    full_name,
    phone,
    role,
    status,
    is_active,
    metadata,
    created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'courier'),
    'pending',
    false,
    COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING; -- Duplicate engellemek için
  
  RETURN NEW;
END;
$$;

-- Trigger'ı oluştur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ✅ BAŞARILI: 
-- Artık kullanıcı Auth'a kaydolunca otomatik users tablosuna eklenecek
-- Email onayı çalışmaya devam edecek
-- Rate limit sorunu olmayacak
