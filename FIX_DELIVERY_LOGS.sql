-- Delivery Logs tablosunu düzelt
DROP TABLE IF EXISTS delivery_logs;

CREATE TABLE delivery_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    delivery_id UUID, -- foreign key constraint'i kaldırıldı
    merchant_id UUID REFERENCES users(id),
    nearby_courier_count INTEGER,
    max_distance_km FLOAT,
    strategy_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policy'leri yeniden ekle
ALTER TABLE delivery_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read delivery logs" ON delivery_logs FOR SELECT USING (true);
CREATE POLICY "Only system can insert delivery logs" ON delivery_logs FOR INSERT WITH CHECK (true);

-- Index ekle
CREATE INDEX idx_delivery_logs_created ON delivery_logs(created_at DESC);