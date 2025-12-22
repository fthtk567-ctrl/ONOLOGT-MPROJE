-- ================================================================
-- SQL SCRIPT: Update users table with missing fields
-- ================================================================
-- Purpose: Add missing fields for complete Admin Panel functionality
-- Database: Supabase PostgreSQL
-- ================================================================

-- 1. Add full_name column (EN ÖNEMLİ!)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS full_name TEXT;

-- 2. Add commission_rate column for merchants
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 15.00;

-- 2. Add business fields for merchants
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS business_phone TEXT,
ADD COLUMN IF NOT EXISTS business_address TEXT;

-- 3. Add owner_name for couriers
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS owner_name TEXT;

-- 4. Add vehicle_type for couriers
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS vehicle_type TEXT;

-- 5. Add current_location for real-time tracking
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS current_location JSONB;

-- 6. Add is_available for courier availability
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT false;

-- 7. Update existing users to have default owner_name (from full_name)
UPDATE users 
SET owner_name = full_name 
WHERE role = 'courier' AND owner_name IS NULL;

-- 8. Add comments
COMMENT ON COLUMN users.commission_rate IS 'İşletme komisyon oranı (%)';
COMMENT ON COLUMN users.business_phone IS 'İşletme telefonu';
COMMENT ON COLUMN users.business_address IS 'İşletme adresi';
COMMENT ON COLUMN users.owner_name IS 'Kurye adı soyadı';
COMMENT ON COLUMN users.vehicle_type IS 'Araç tipi (motorbike, car, bicycle)';
COMMENT ON COLUMN users.current_location IS 'Anlık konum {lat, lng}';
COMMENT ON COLUMN users.is_available IS 'Kurye müsaitlik durumu';

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Check new columns exist
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name IN (
    'commission_rate', 
    'business_phone', 
    'business_address', 
    'owner_name', 
    'vehicle_type', 
    'current_location', 
    'is_available'
  );

-- Show sample merchant data
SELECT id, business_name, email, commission_rate, business_phone, business_address
FROM users 
WHERE role = 'merchant' 
LIMIT 5;

-- Show sample courier data
SELECT id, owner_name, email, vehicle_type, is_available, average_rating
FROM users 
WHERE role = 'courier' 
LIMIT 5;
