-- ======================================================================
-- MERCHANT OTOMATİK KAYIT SİSTEMİ - KOLONLAR
-- ======================================================================
-- Yemek App'ten gelen restoranlar için otomatik merchant kaydı
-- ======================================================================

-- 1. users tablosuna source ve is_auto_registered kolonları ekle
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS is_auto_registered BOOLEAN DEFAULT FALSE;

-- 2. Source için yorum ekle
COMMENT ON COLUMN users.source IS 'Kullanıcının kaynağı: manual, yemek_app, trendyol, getir';
COMMENT ON COLUMN users.is_auto_registered IS 'Otomatik kayıt mı yoksa manuel kayıt mı';

-- 3. Source için index (performans)
CREATE INDEX IF NOT EXISTS idx_users_source ON users(source);

-- 4. Otomatik kayıtlı merchantlar için index
CREATE INDEX IF NOT EXISTS idx_users_auto_registered ON users(is_auto_registered) WHERE is_auto_registered = TRUE;

-- 5. Doğrulama
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'users' 
  AND column_name IN ('source', 'is_auto_registered');

-- ✅ Kolonlar eklendi
-- ✅ Index'ler oluşturuldu
-- ✅ Otomatik merchant kaydı için hazır
