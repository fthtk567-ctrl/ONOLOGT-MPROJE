-- Delivery Requests tablosuna gerekli kolonları ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS nearest_couriers UUID[] DEFAULT ARRAY[]::UUID[],
ADD COLUMN IF NOT EXISTS priority_deadline TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS limited_visibility_deadline TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS final_deadline TIMESTAMPTZ;

-- Indexler ekle
CREATE INDEX IF NOT EXISTS idx_delivery_requests_nearest_couriers ON delivery_requests USING GIN(nearest_couriers);
CREATE INDEX IF NOT EXISTS idx_delivery_requests_deadlines ON delivery_requests(priority_deadline, limited_visibility_deadline, final_deadline);

-- RLS Policy ekle
ALTER TABLE delivery_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read delivery logs" ON delivery_logs FOR SELECT USING (true);
CREATE POLICY "Only system can insert delivery logs" ON delivery_logs FOR INSERT WITH CHECK (true);