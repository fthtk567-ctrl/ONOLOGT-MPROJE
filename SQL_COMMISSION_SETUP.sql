-- ============================================
-- KOMİSYON SİSTEMİ - DOĞRU YÜZDELER
-- ============================================
-- Merchant: %20 öder (toplam tutar üzerinden)
-- Esnaf Kurye: %18 kazanır (toplam tutar üzerinden)
-- Sistem: %2 komisyon farkı (20 - 18 = 2%)
-- SGK Kurye: Prim kazanır (TL değil, bonus sistemi)
-- ============================================

-- 1. Commission Configs Tablosu (Yüzde ayarları)
CREATE TABLE IF NOT EXISTS commission_configs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  config_type TEXT NOT NULL, -- 'merchant', 'courier_esnaf', 'courier_sgk'
  commission_rate DECIMAL(5,2) NOT NULL, -- %20.00, %18.00, %0.00
  is_active BOOLEAN DEFAULT true,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Delivery Requests Tablosu (Kurye çağrıları)
CREATE TABLE IF NOT EXISTS delivery_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  
  -- Merchant bilgileri
  merchant_id UUID NOT NULL REFERENCES users(id),
  merchant_name TEXT,
  merchant_location JSONB, -- {lat, lng, address}
  
  -- Paket detayları
  package_count INTEGER DEFAULT 1,
  declared_amount DECIMAL(10,2) NOT NULL, -- Toplam tutar (100 TL gibi)
  notes TEXT,
  
  -- Komisyon hesaplamaları
  merchant_commission_rate DECIMAL(5,2) DEFAULT 20.00, -- %20
  merchant_payment_due DECIMAL(10,2), -- Satıcının ödeyeceği (20 TL)
  
  courier_commission_rate DECIMAL(5,2) DEFAULT 18.00, -- %18 (esnaf için)
  courier_payment_due DECIMAL(10,2), -- Kuryenin alacağı (18 TL)
  
  system_commission DECIMAL(10,2), -- Sistemin kazancı (2 TL = 20-18)
  
  -- Kurye bilgileri
  courier_id UUID REFERENCES users(id),
  courier_type TEXT, -- 'esnaf' veya 'sgk'
  courier_earnings_type TEXT DEFAULT 'percentage', -- 'percentage' (esnaf) veya 'bonus' (sgk)
  
  -- Durum takibi
  status TEXT DEFAULT 'pending', -- pending, assigned, picked_up, delivering, completed, cancelled
  priority INTEGER DEFAULT 0,
  
  -- Zaman damgaları
  created_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_at TIMESTAMPTZ,
  picked_up_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  
  -- Metadata
  metadata JSONB, -- Ekstra bilgiler için
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'assigned', 'picked_up', 'delivering', 'completed', 'cancelled')),
  CONSTRAINT valid_courier_type CHECK (courier_type IS NULL OR courier_type IN ('esnaf', 'sgk')),
  CONSTRAINT valid_earnings_type CHECK (courier_earnings_type IN ('percentage', 'bonus'))
);

-- 3. Courier Bonuses Tablosu (SGK kuriyeleri için prim sistemi)
CREATE TABLE IF NOT EXISTS courier_bonuses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  courier_id UUID NOT NULL REFERENCES users(id),
  delivery_request_id UUID REFERENCES delivery_requests(id),
  
  -- Hedef ve başarı
  daily_target INTEGER, -- Günlük hedef (örn: 10 paket)
  packages_delivered INTEGER, -- Gerçekleşen (örn: 20 paket)
  bonus_points INTEGER, -- Kazanılan prim puanı
  bonus_amount DECIMAL(10,2), -- TL karşılığı (opsiyonel)
  
  -- Açıklama
  description TEXT,
  bonus_type TEXT DEFAULT 'delivery', -- 'delivery', 'target_exceeded', 'perfect_rating'
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Default Commission Ayarları
INSERT INTO commission_configs (config_type, commission_rate, description) VALUES
  ('merchant', 20.00, 'Satıcının ödeyeceği komisyon oranı - toplam tutarın %20si'),
  ('courier_esnaf', 18.00, 'Esnaf kuryenin alacağı komisyon oranı - toplam tutarın %18i'),
  ('courier_sgk', 0.00, 'SGK kuryeleri prim sistemi kullanır - yüzde yok')
ON CONFLICT DO NOTHING;

-- 5. Indices (Performans için)
CREATE INDEX IF NOT EXISTS idx_delivery_requests_merchant ON delivery_requests(merchant_id);
CREATE INDEX IF NOT EXISTS idx_delivery_requests_courier ON delivery_requests(courier_id);
CREATE INDEX IF NOT EXISTS idx_delivery_requests_status ON delivery_requests(status);
CREATE INDEX IF NOT EXISTS idx_delivery_requests_created ON delivery_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_courier_bonuses_courier ON courier_bonuses(courier_id);

-- 6. Realtime Subscription (Courier App için)
-- Supabase Dashboard'da Realtime için enable et:
-- ALTER TABLE delivery_requests REPLICA IDENTITY FULL;
-- ALTER PUBLICATION supabase_realtime ADD TABLE delivery_requests;

-- 7. RLS Policies (Row Level Security)
ALTER TABLE delivery_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE courier_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_configs ENABLE ROW LEVEL SECURITY;

-- Merchant: Sadece kendi requestlerini görsün
CREATE POLICY "Merchants see own requests" ON delivery_requests
  FOR SELECT USING (auth.uid() = merchant_id);

CREATE POLICY "Merchants create own requests" ON delivery_requests
  FOR INSERT WITH CHECK (auth.uid() = merchant_id);

-- Courier: Pending requestleri ve kendi atananları görsün
CREATE POLICY "Couriers see pending and assigned" ON delivery_requests
  FOR SELECT USING (
    status = 'pending' OR 
    courier_id = auth.uid()
  );

CREATE POLICY "Couriers update assigned" ON delivery_requests
  FOR UPDATE USING (courier_id = auth.uid());

-- Admin: Her şeyi görsün
CREATE POLICY "Admins see all requests" ON delivery_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Commission Configs: Herkes okusun, sadece admin değiştirsin
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

-- Courier Bonuses: Kurye kendi primlerini görsün
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
  -- Satıcının ödeyeceği komisyon (%20)
  NEW.merchant_payment_due := NEW.declared_amount * (NEW.merchant_commission_rate / 100);
  
  -- Kuryenin alacağı komisyon (%18 esnaf için, 0 sgk için)
  IF NEW.courier_type = 'esnaf' THEN
    NEW.courier_payment_due := NEW.declared_amount * (NEW.courier_commission_rate / 100);
  ELSIF NEW.courier_type = 'sgk' THEN
    NEW.courier_payment_due := 0; -- SGK primleri ayrı hesaplanır
  ELSE
    -- Henüz kurye atanmamış, default esnaf olarak hesapla
    NEW.courier_payment_due := NEW.declared_amount * (NEW.courier_commission_rate / 100);
  END IF;
  
  -- Sistemin kazancı (fark)
  NEW.system_commission := NEW.merchant_payment_due - COALESCE(NEW.courier_payment_due, 0);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calculate_commissions ON delivery_requests;
CREATE TRIGGER trigger_calculate_commissions
  BEFORE INSERT OR UPDATE OF declared_amount, courier_type, merchant_commission_rate, courier_commission_rate
  ON delivery_requests
  FOR EACH ROW
  EXECUTE FUNCTION calculate_commissions();

-- 9. Helper Function: Aktif commission rates al
CREATE OR REPLACE FUNCTION get_active_commission_rates()
RETURNS TABLE (
  merchant_rate DECIMAL,
  esnaf_rate DECIMAL,
  sgk_rate DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    MAX(CASE WHEN config_type = 'merchant' THEN commission_rate END) as merchant_rate,
    MAX(CASE WHEN config_type = 'courier_esnaf' THEN commission_rate END) as esnaf_rate,
    MAX(CASE WHEN config_type = 'courier_sgk' THEN commission_rate END) as sgk_rate
  FROM commission_configs
  WHERE is_active = true;
END;
$$ LANGUAGE plpgsql;

-- 10. Test Data (İsteğe bağlı)
-- Test için örnek komisyon ayarlarını görmek için:
-- SELECT * FROM commission_configs WHERE is_active = true;
-- SELECT * FROM get_active_commission_rates();

COMMENT ON TABLE delivery_requests IS 'Manuel kurye çağrıları - Merchant Panel den oluşturulan teslimat istekleri';
COMMENT ON TABLE courier_bonuses IS 'SGK kuriyeleri için prim sistemi - TL değil, bonus puanı';
COMMENT ON TABLE commission_configs IS 'Komisyon yüzdeleri - Admin panelden düzenlenebilir';

COMMENT ON COLUMN delivery_requests.merchant_payment_due IS 'Satıcının ödeyeceği tutar (declared_amount x %20)';
COMMENT ON COLUMN delivery_requests.courier_payment_due IS 'Kuryenin alacağı tutar (esnaf: declared_amount x %18, sgk: 0)';
COMMENT ON COLUMN delivery_requests.system_commission IS 'Sistemin kazancı (merchant_payment - courier_payment = %2)';
COMMENT ON COLUMN delivery_requests.courier_type IS 'esnaf: Kendi motorcu + mali müşavir, sgk: Şirket elemanı';
COMMENT ON COLUMN delivery_requests.courier_earnings_type IS 'percentage: TL kazanç (esnaf), bonus: Prim puanı (sgk)';
