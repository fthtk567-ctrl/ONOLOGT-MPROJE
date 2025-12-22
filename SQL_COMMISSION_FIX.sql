-- ============================================
-- KOMİSYON SİSTEMİ FİX - TABLOYU DÜZELT
-- ============================================

-- 1. Önce eski tabloyu sil (varsa)
DROP TABLE IF EXISTS courier_bonuses CASCADE;
DROP TABLE IF EXISTS delivery_requests CASCADE;
DROP TABLE IF EXISTS commission_configs CASCADE;

-- 2. Commission Configs Tablosu - DOĞRU ŞEMA
CREATE TABLE commission_configs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  config_type TEXT NOT NULL UNIQUE,
  commission_rate DECIMAL(5,2) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Delivery Requests Tablosu
CREATE TABLE delivery_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  merchant_id UUID NOT NULL REFERENCES users(id),
  merchant_name TEXT,
  merchant_location JSONB,
  package_count INTEGER DEFAULT 1,
  declared_amount DECIMAL(10,2) NOT NULL,
  notes TEXT,
  merchant_commission_rate DECIMAL(5,2) DEFAULT 20.00,
  merchant_payment_due DECIMAL(10,2),
  courier_commission_rate DECIMAL(5,2) DEFAULT 18.00,
  courier_payment_due DECIMAL(10,2),
  system_commission DECIMAL(10,2),
  courier_id UUID REFERENCES users(id),
  courier_type TEXT,
  courier_earnings_type TEXT DEFAULT 'percentage',
  status TEXT DEFAULT 'pending',
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_at TIMESTAMPTZ,
  picked_up_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  metadata JSONB,
  CONSTRAINT valid_status CHECK (status IN ('pending', 'assigned', 'picked_up', 'delivering', 'completed', 'cancelled')),
  CONSTRAINT valid_courier_type CHECK (courier_type IS NULL OR courier_type IN ('esnaf', 'sgk')),
  CONSTRAINT valid_earnings_type CHECK (courier_earnings_type IN ('percentage', 'bonus'))
);

-- 4. Courier Bonuses Tablosu
CREATE TABLE courier_bonuses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  courier_id UUID NOT NULL REFERENCES users(id),
  delivery_request_id UUID REFERENCES delivery_requests(id),
  daily_target INTEGER,
  packages_delivered INTEGER,
  bonus_points INTEGER,
  bonus_amount DECIMAL(10,2),
  description TEXT,
  bonus_type TEXT DEFAULT 'delivery',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Default Commission Ayarları
INSERT INTO commission_configs (config_type, commission_rate, description) VALUES
  ('merchant', 20.00, 'Satıcının ödeyeceği komisyon oranı - toplam tutarın %20si'),
  ('courier_esnaf', 18.00, 'Esnaf kuryenin alacağı komisyon oranı - toplam tutarın %18i'),
  ('courier_sgk', 0.00, 'SGK kuryeleri prim sistemi kullanır - yüzde yok');

-- 6. Indices
CREATE INDEX idx_delivery_requests_merchant ON delivery_requests(merchant_id);
CREATE INDEX idx_delivery_requests_courier ON delivery_requests(courier_id);
CREATE INDEX idx_delivery_requests_status ON delivery_requests(status);
CREATE INDEX idx_delivery_requests_created ON delivery_requests(created_at DESC);
CREATE INDEX idx_courier_bonuses_courier ON courier_bonuses(courier_id);

-- 7. RLS Policies
ALTER TABLE delivery_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE courier_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Merchants see own requests" ON delivery_requests
  FOR SELECT USING (auth.uid() = merchant_id);

CREATE POLICY "Merchants create own requests" ON delivery_requests
  FOR INSERT WITH CHECK (auth.uid() = merchant_id);

CREATE POLICY "Couriers see pending and assigned" ON delivery_requests
  FOR SELECT USING (status = 'pending' OR courier_id = auth.uid());

CREATE POLICY "Couriers update assigned" ON delivery_requests
  FOR UPDATE USING (courier_id = auth.uid());

CREATE POLICY "Admins see all requests" ON delivery_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Everyone reads commission configs" ON commission_configs
  FOR SELECT USING (is_active = true);

CREATE POLICY "Only admins update commission configs" ON commission_configs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Couriers see own bonuses" ON courier_bonuses
  FOR SELECT USING (auth.uid() = courier_id);

CREATE POLICY "Admins manage all bonuses" ON courier_bonuses
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- 8. Trigger: Komisyon otomatik hesaplama
CREATE OR REPLACE FUNCTION calculate_commissions()
RETURNS TRIGGER AS $$
BEGIN
  NEW.merchant_payment_due := NEW.declared_amount * (NEW.merchant_commission_rate / 100);
  
  IF NEW.courier_type = 'esnaf' THEN
    NEW.courier_payment_due := NEW.declared_amount * (NEW.courier_commission_rate / 100);
  ELSIF NEW.courier_type = 'sgk' THEN
    NEW.courier_payment_due := 0;
  ELSE
    NEW.courier_payment_due := NEW.declared_amount * (NEW.courier_commission_rate / 100);
  END IF;
  
  NEW.system_commission := NEW.merchant_payment_due - COALESCE(NEW.courier_payment_due, 0);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_commissions
  BEFORE INSERT OR UPDATE OF declared_amount, courier_type, merchant_commission_rate, courier_commission_rate
  ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION calculate_commissions();

-- BAŞARILI! ✅
