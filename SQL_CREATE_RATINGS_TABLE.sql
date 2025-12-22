-- ================================================================
-- SQL SCRIPT: Create ratings table
-- ================================================================
-- Purpose: Store courier ratings and reviews from merchants
-- Date: 2025-01-XX
-- Database: Supabase PostgreSQL
-- ================================================================

-- 1. Create ratings table
CREATE TABLE IF NOT EXISTS ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
    courier_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ratings_courier_id ON ratings(courier_id);
CREATE INDEX IF NOT EXISTS idx_ratings_merchant_id ON ratings(merchant_id);
CREATE INDEX IF NOT EXISTS idx_ratings_order_id ON ratings(order_id);
CREATE INDEX IF NOT EXISTS idx_ratings_created_at ON ratings(created_at DESC);

-- 3. Add average_rating and total_ratings columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0;

-- 4. Add index for filtering by rating
CREATE INDEX IF NOT EXISTS idx_users_average_rating ON users(average_rating DESC);

-- 5. Add comments for documentation
COMMENT ON TABLE ratings IS 'Kurye değerlendirme ve yorumları';
COMMENT ON COLUMN ratings.rating IS 'Yıldız sayısı (1-5)';
COMMENT ON COLUMN ratings.comment IS 'Müşteri yorumu (isteğe bağlı)';
COMMENT ON COLUMN users.average_rating IS 'Kurye ortalama değerlendirmesi';
COMMENT ON COLUMN users.total_ratings IS 'Toplam değerlendirme sayısı';

-- 6. Enable Row Level Security (RLS)
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies
-- Herkes kendi oluşturduğu rating'leri görebilir
CREATE POLICY "Users can view their own ratings"
    ON ratings FOR SELECT
    USING (auth.uid() = merchant_id OR auth.uid() = courier_id);

-- Sadece merchant'lar rating oluşturabilir (order'ı onlara ait olan)
CREATE POLICY "Merchants can create ratings for their orders"
    ON ratings FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM delivery_requests
            WHERE id = order_id
            AND merchant_id = auth.uid()
        )
    );

-- Herkes kendi rating'ini güncelleyebilir
CREATE POLICY "Users can update their own ratings"
    ON ratings FOR UPDATE
    USING (auth.uid() = merchant_id);

-- Herkes kendi rating'ini silebilir
CREATE POLICY "Users can delete their own ratings"
    ON ratings FOR DELETE
    USING (auth.uid() = merchant_id);

-- 8. Trigger: Update updated_at on rating change
CREATE OR REPLACE FUNCTION update_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ratings_updated_at_trigger
    BEFORE UPDATE ON ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_ratings_updated_at();

-- ================================================================
-- VERIFICATION QUERIES (Run these after execution)
-- ================================================================

-- Check table exists
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ratings'
ORDER BY ordinal_position;

-- Check users columns
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name IN ('average_rating', 'total_ratings');

-- ================================================================
-- TEST DATA (Optional - for testing purposes)
-- ================================================================

-- Insert sample rating (requires existing order and users)
-- Replace UUIDs with real IDs from your database
/*
INSERT INTO ratings (order_id, courier_id, merchant_id, rating, comment)
VALUES (
    'order-uuid-here',
    'courier-uuid-here',
    'merchant-uuid-here',
    5,
    'Çok hızlı ve güvenli teslimat, teşekkürler!'
);
*/

-- ================================================================
-- NOTES
-- ================================================================
-- - Rating 1-5 arası integer değer
-- - Comment opsiyonel (NULL olabilir)
-- - Her order için birden fazla rating olabilir (aynı merchant tekrar değerlendirirse)
-- - average_rating otomatik hesaplanır (uygulama tarafından)
-- - RLS policies merchant'ların sadece kendi siparişlerine rating vermesini sağlar
-- ================================================================
