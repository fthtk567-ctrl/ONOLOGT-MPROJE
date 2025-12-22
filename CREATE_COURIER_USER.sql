-- ============================================
-- KURYE KULLANICISINI MÜSAİT YAP
-- Supabase Dashboard > SQL Editor'de çalıştır
-- ============================================

-- Kurye zaten var, sadece is_available = TRUE yap
UPDATE public.users
SET 
  is_available = true,
  is_active = true,
  status = 'active',  -- 'approved' değil 'active' olmalı!
  updated_at = NOW()
WHERE email = 'courier@onlog.com'
  AND role = 'courier';

-- Kontrol et
SELECT
  id,
  email,
  role,
  owner_name,
  is_available,
  is_active,
  status
FROM public.users
WHERE email = 'courier@onlog.com';

-- ✅ BAŞARILI! Şimdi merchant panel'den kurye çağır!
