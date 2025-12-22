-- YAKINLIK FİLTRESİ AYARLARI
-- Merchant Panelde kurye ataması yaparken sadece yakındaki kuryeleri göster

-- Sistem ayarları tablosu (yoksa oluştur)
CREATE TABLE IF NOT EXISTS public.system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Yakınlık filtresi ayarı
INSERT INTO public.system_settings (setting_key, setting_value, description)
VALUES (
  'courier_proximity_filter',
  '{"max_distance_km": 50, "enabled": true}'::jsonb,
  'Kurye atamasında maksimum mesafe filtresi (km cinsinden)'
)
ON CONFLICT (setting_key) 
DO UPDATE SET 
  setting_value = EXCLUDED.setting_value,
  updated_at = NOW();

-- Ayarları kontrol et
SELECT * FROM public.system_settings WHERE setting_key = 'courier_proximity_filter';

-- 📝 KULLANIM:
-- Mesafeyi değiştirmek için:
-- UPDATE public.system_settings 
-- SET setting_value = '{"max_distance_km": 30, "enabled": true}'::jsonb
-- WHERE setting_key = 'courier_proximity_filter';

-- Filtreyi devre dışı bırakmak için:
-- UPDATE public.system_settings 
-- SET setting_value = '{"max_distance_km": 50, "enabled": false}'::jsonb
-- WHERE setting_key = 'courier_proximity_filter';
