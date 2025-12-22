-- ================================================================
-- SQL SCRIPT: Add current_location column to users table
-- ================================================================
-- Purpose: Store courier's real-time GPS location (lat, lng)
-- Date: 2025-01-XX
-- Database: Supabase PostgreSQL
-- ================================================================

-- 1. Add current_location column with JSONB type
-- Format: {"latitude": 40.123, "longitude": 29.456, "timestamp": "ISO8601"}
ALTER TABLE users 
ADD COLUMN current_location JSONB DEFAULT NULL;

-- 2. Add index for faster queries (important for location-based searches)
CREATE INDEX idx_users_current_location 
ON users USING GIN (current_location);

-- 3. Add comment for documentation
COMMENT ON COLUMN users.current_location IS 
'Kurye''nin anlık GPS konumu (latitude, longitude, timestamp)';

-- 4. Initialize location for active couriers (optional - can be null initially)
-- This sets a default Istanbul location for testing purposes
UPDATE users 
SET current_location = '{"latitude": 41.0082, "longitude": 28.9784, "timestamp": null}'::jsonb
WHERE role = 'courier' 
  AND is_active = true 
  AND current_location IS NULL;

-- ================================================================
-- VERIFICATION QUERIES (Run these after execution)
-- ================================================================

-- Check column exists
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name = 'current_location';

-- Check data for couriers
SELECT id, email, role, current_location, is_available
FROM users 
WHERE role = 'courier';

-- ================================================================
-- NOTES
-- ================================================================
-- - JSONB format: {"latitude": 40.123, "longitude": 29.456, "timestamp": "2025-01-15T10:30:00Z"}
-- - GIN index enables fast JSONB queries
-- - Can be null when courier is offline
-- - Updated automatically by Flutter app via location service
-- - Used for delivery assignment algorithm (distance calculations)
-- ================================================================
