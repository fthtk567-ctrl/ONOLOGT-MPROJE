-- ===================================================================
-- ONLOG PAYMENT SYSTEM - SUPABASE DATABASE SETUP
-- ===================================================================
-- Bu SQL script'i Supabase SQL Editor'de çalıştırın
-- Merchant Panel ödeme sistemi için gerekli tablolar ve fonksiyonlar
-- ===================================================================

-- ===================================================================
-- 1. PAYMENT TRANSACTIONS TABLOSU
-- ===================================================================
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- İlişkiler
  order_id TEXT NOT NULL,
  merchant_id UUID REFERENCES auth.users(id),
  courier_id UUID REFERENCES auth.users(id),
  customer_id UUID REFERENCES auth.users(id),
  
  -- Para bilgileri
  amount DECIMAL(10, 2) NOT NULL,
  original_amount DECIMAL(10, 2) NOT NULL,
  commission_amount DECIMAL(10, 2) DEFAULT 0,
  vat_amount DECIMAL(10, 2) DEFAULT 0,
  currency VARCHAR(3) DEFAULT 'TRY',
  
  -- Ödeme detayları
  payment_method VARCHAR(50) NOT NULL,  -- creditCard, cash, wallet, vb.
  status VARCHAR(50) NOT NULL,          -- pending, completed, failed, vb.
  type VARCHAR(50) NOT NULL,            -- orderPayment, deliveryFee, withdrawal, vb.
  
  -- Tarihler
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  settled_at TIMESTAMPTZ,
  
  -- Gateway bilgileri
  gateway_reference TEXT,
  gateway_provider VARCHAR(50),         -- iyzico, paytr, param, vb.
  gateway_response JSONB DEFAULT '{}',
  
  -- Ek bilgiler
  description TEXT,
  metadata JSONB DEFAULT '{}'
);

-- İndexler
CREATE INDEX IF NOT EXISTS idx_payment_transactions_merchant ON payment_transactions(merchant_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_courier ON payment_transactions(courier_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created ON payment_transactions(created_at);

-- RLS (Row Level Security) - Sadece kendi kayıtlarını görebilir
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions" ON payment_transactions
  FOR SELECT
  USING (
    auth.uid() = merchant_id OR 
    auth.uid() = courier_id OR 
    auth.uid() = customer_id
  );

CREATE POLICY "Admin can view all transactions" ON payment_transactions
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===================================================================
-- 2. MERCHANT WALLETS TABLOSU
-- ===================================================================
CREATE TABLE IF NOT EXISTS merchant_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Bakiye bilgileri
  balance DECIMAL(10, 2) DEFAULT 0 CHECK (balance >= 0),
  pending_balance DECIMAL(10, 2) DEFAULT 0 CHECK (pending_balance >= 0),
  frozen_balance DECIMAL(10, 2) DEFAULT 0 CHECK (frozen_balance >= 0),
  
  -- Toplam istatistikler
  total_earnings DECIMAL(10, 2) DEFAULT 0,
  total_withdrawals DECIMAL(10, 2) DEFAULT 0,
  total_commissions DECIMAL(10, 2) DEFAULT 0,
  
  -- Para birimi
  currency VARCHAR(3) DEFAULT 'TRY',
  
  -- Limitler
  limits JSONB DEFAULT '{
    "daily_withdrawal": 10000.0,
    "monthly_withdrawal": 100000.0,
    "minimum_withdrawal": 50.0
  }',
  
  -- Tarihler
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- İndexler
CREATE INDEX IF NOT EXISTS idx_merchant_wallets_merchant ON merchant_wallets(merchant_id);

-- RLS
ALTER TABLE merchant_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Merchants can view own wallet" ON merchant_wallets
  FOR SELECT
  USING (auth.uid() = merchant_id);

CREATE POLICY "Admin can view all wallets" ON merchant_wallets
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===================================================================
-- 3. COMMISSION CONFIGS TABLOSU
-- ===================================================================
CREATE TABLE IF NOT EXISTS commission_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Merchant özel veya genel (null = genel)
  merchant_id UUID REFERENCES auth.users(id),
  
  -- Komisyon oranları
  commission_rate DECIMAL(5, 2) NOT NULL DEFAULT 15.0,  -- %15
  fixed_fee DECIMAL(10, 2) DEFAULT 2.0,
  minimum_commission DECIMAL(10, 2) DEFAULT 2.0,
  maximum_commission DECIMAL(10, 2) DEFAULT 50.0,
  
  -- Geçerlilik
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Özel koşullar
  conditions JSONB DEFAULT '{}',
  
  -- Tarihler
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- İndexler
CREATE INDEX IF NOT EXISTS idx_commission_configs_merchant ON commission_configs(merchant_id);
CREATE INDEX IF NOT EXISTS idx_commission_configs_active ON commission_configs(is_active);

-- RLS
ALTER TABLE commission_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read commission configs" ON commission_configs
  FOR SELECT
  USING (TRUE);

CREATE POLICY "Admin can manage commission configs" ON commission_configs
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===================================================================
-- 4. RPC FONKSIYONLAR
-- ===================================================================

-- 4.1 Merchant Wallet Güncelleme Fonksiyonu
CREATE OR REPLACE FUNCTION update_merchant_wallet(
  p_merchant_id UUID,
  p_balance_change DECIMAL DEFAULT 0,
  p_pending_amount DECIMAL DEFAULT 0,
  p_frozen_amount DECIMAL DEFAULT 0,
  p_commission_amount DECIMAL DEFAULT 0
)
RETURNS VOID AS $$
BEGIN
  -- Wallet yoksa oluştur
  INSERT INTO merchant_wallets (merchant_id, balance, pending_balance, frozen_balance, total_commissions)
  VALUES (p_merchant_id, 0, 0, 0, 0)
  ON CONFLICT (merchant_id) DO NOTHING;
  
  -- Wallet'ı güncelle
  UPDATE merchant_wallets
  SET 
    balance = balance + p_balance_change,
    pending_balance = pending_balance + p_pending_amount,
    frozen_balance = frozen_balance + p_frozen_amount,
    total_earnings = total_earnings + p_balance_change,
    total_commissions = total_commissions + p_commission_amount,
    last_updated = NOW()
  WHERE merchant_id = p_merchant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.2 Ödeme Sonrası Wallet Güncelleme Fonksiyonu
CREATE OR REPLACE FUNCTION update_merchant_wallet_after_payment(
  p_merchant_id UUID,
  p_amount DECIMAL,
  p_commission_amount DECIMAL,
  p_transaction_id UUID
)
RETURNS VOID AS $$
BEGIN
  -- Wallet yoksa oluştur
  INSERT INTO merchant_wallets (merchant_id, balance, pending_balance, frozen_balance, total_commissions)
  VALUES (p_merchant_id, 0, 0, 0, 0)
  ON CONFLICT (merchant_id) DO NOTHING;
  
  -- Wallet'ı güncelle
  UPDATE merchant_wallets
  SET 
    balance = balance + p_amount,
    total_earnings = total_earnings + p_amount,
    total_commissions = total_commissions + p_commission_amount,
    last_updated = NOW()
  WHERE merchant_id = p_merchant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.3 Default Komisyon Konfigürasyonu Oluştur
INSERT INTO commission_configs (
  merchant_id,
  commission_rate,
  fixed_fee,
  minimum_commission,
  maximum_commission,
  is_active
) VALUES (
  NULL,  -- Genel konfigürasyon
  15.0,  -- %15 komisyon
  2.0,   -- 2 TL sabit ücret
  2.0,   -- Minimum 2 TL
  50.0,  -- Maximum 50 TL
  TRUE
) ON CONFLICT DO NOTHING;

-- ===================================================================
-- 5. TRİGGERLAR
-- ===================================================================

-- 5.1 Wallet son güncelleme tarihini otomatik güncelle
CREATE OR REPLACE FUNCTION update_wallet_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_wallet_timestamp
  BEFORE UPDATE ON merchant_wallets
  FOR EACH ROW
  EXECUTE FUNCTION update_wallet_timestamp();

-- 5.2 Commission config güncelleme tarihini otomatik güncelle
CREATE OR REPLACE FUNCTION update_commission_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_commission_timestamp
  BEFORE UPDATE ON commission_configs
  FOR EACH ROW
  EXECUTE FUNCTION update_commission_timestamp();

-- ===================================================================
-- 6. VİEWS (Raporlama için)
-- ===================================================================

-- 6.1 Merchant Gelir Özeti View
CREATE OR REPLACE VIEW merchant_earnings_summary AS
SELECT 
  merchant_id,
  COUNT(*) as total_transactions,
  SUM(amount) as total_earnings,
  SUM(commission_amount) as total_commissions,
  SUM(original_amount) as total_revenue,
  AVG(amount) as average_transaction,
  DATE_TRUNC('day', created_at) as transaction_date
FROM payment_transactions
WHERE status = 'completed' AND type = 'orderPayment'
GROUP BY merchant_id, DATE_TRUNC('day', created_at);

-- ===================================================================
-- 7. COURIER WALLETS TABLOSU (Kurye Bakiye Sistemi)
-- ===================================================================
CREATE TABLE IF NOT EXISTS courier_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Bakiye bilgileri
  balance DECIMAL(10, 2) DEFAULT 0 CHECK (balance >= 0),
  pending_balance DECIMAL(10, 2) DEFAULT 0 CHECK (pending_balance >= 0),
  frozen_balance DECIMAL(10, 2) DEFAULT 0 CHECK (frozen_balance >= 0),
  
  -- Toplam istatistikler
  total_earnings DECIMAL(10, 2) DEFAULT 0,
  total_withdrawals DECIMAL(10, 2) DEFAULT 0,
  total_deliveries INTEGER DEFAULT 0,
  
  -- Para birimi
  currency VARCHAR(3) DEFAULT 'TRY',
  
  -- Limitler
  limits JSONB DEFAULT '{
    "daily_withdrawal": 5000.0,
    "monthly_withdrawal": 50000.0,
    "minimum_withdrawal": 50.0
  }',
  
  -- Tarihler
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- İndexler
CREATE INDEX IF NOT EXISTS idx_courier_wallets_courier ON courier_wallets(courier_id);

-- RLS
ALTER TABLE courier_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couriers can view own wallet" ON courier_wallets
  FOR SELECT
  USING (auth.uid() = courier_id);

CREATE POLICY "Admin can view all courier wallets" ON courier_wallets
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===================================================================
-- 8. OTOMATİK FİNANSAL İŞLEM FONKSİYONLARI
-- ===================================================================

-- 8.1 Sipariş Teslim Edilince Otomatik Ödeme İşle
CREATE OR REPLACE FUNCTION process_order_payment_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_commission_config RECORD;
  v_commission_amount DECIMAL;
  v_vat_amount DECIMAL;
  v_merchant_earning DECIMAL;
  v_delivery_fee DECIMAL;
  v_transaction_id UUID;
BEGIN
  -- Sadece 'DELIVERED' durumuna geçişlerde çalış
  IF NEW.status = 'DELIVERED' AND OLD.status != 'DELIVERED' THEN
    
    -- Komisyon konfigürasyonunu al
    SELECT * INTO v_commission_config
    FROM commission_configs
    WHERE (merchant_id = NEW.merchant_id OR merchant_id IS NULL)
      AND is_active = TRUE
    ORDER BY merchant_id DESC NULLS LAST
    LIMIT 1;
    
    -- Varsayılan değerler
    IF v_commission_config IS NULL THEN
      v_commission_config.commission_rate := 15.0;
      v_commission_config.fixed_fee := 2.0;
    END IF;
    
    -- Komisyon hesapla
    v_commission_amount := (NEW.total_amount * v_commission_config.commission_rate / 100) + v_commission_config.fixed_fee;
    v_vat_amount := v_commission_amount * 0.18;  -- %18 KDV
    v_merchant_earning := NEW.total_amount - v_commission_amount - v_vat_amount;
    v_delivery_fee := COALESCE((NEW.metadata->>'delivery_fee')::DECIMAL, 0);
    
    -- Merchant için payment transaction oluştur
    INSERT INTO payment_transactions (
      order_id,
      merchant_id,
      courier_id,
      customer_id,
      amount,
      original_amount,
      commission_amount,
      vat_amount,
      currency,
      payment_method,
      status,
      type,
      created_at,
      processed_at,
      settled_at,
      gateway_reference,
      gateway_provider,
      gateway_response,
      description,
      metadata
    ) VALUES (
      NEW.id::TEXT,
      NEW.merchant_id,
      NEW.courier_id,
      NEW.customer_id,
      v_merchant_earning,
      NEW.total_amount,
      v_commission_amount,
      v_vat_amount,
      'TRY',
      COALESCE(NEW.payment_method, 'cash'),
      'completed',
      'orderPayment',
      NOW(),
      NOW(),
      NOW(),
      'AUTO_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
      'ONLOG_AUTO',
      '{}',
      'Sipariş #' || NEW.id || ' otomatik ödeme',
      jsonb_build_object(
        'auto_processed', TRUE,
        'commission_rate', v_commission_config.commission_rate,
        'vat_rate', 0.18,
        'order_status', NEW.status
      )
    ) RETURNING id INTO v_transaction_id;
    
    -- Merchant wallet'ını güncelle
    PERFORM update_merchant_wallet_after_payment(
      NEW.merchant_id,
      v_merchant_earning,
      v_commission_amount,
      v_transaction_id
    );
    
    -- Kurye varsa kurye ödemesini işle
    IF NEW.courier_id IS NOT NULL AND v_delivery_fee > 0 THEN
      -- Kurye için payment transaction oluştur
      INSERT INTO payment_transactions (
        order_id,
        merchant_id,
        courier_id,
        customer_id,
        amount,
        original_amount,
        commission_amount,
        vat_amount,
        currency,
        payment_method,
        status,
        type,
        created_at,
        processed_at,
        settled_at,
        gateway_reference,
        gateway_provider,
        gateway_response,
        description,
        metadata
      ) VALUES (
        NEW.id::TEXT,
        NULL,
        NEW.courier_id,
        NULL,
        v_delivery_fee,
        v_delivery_fee,
        0,
        0,
        'TRY',
        'wallet',
        'completed',
        'deliveryFee',
        NOW(),
        NOW(),
        NOW(),
        'DELIVERY_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
        'ONLOG_AUTO',
        '{}',
        'Teslimat ücreti - Sipariş #' || NEW.id,
        jsonb_build_object(
          'auto_processed', TRUE,
          'courier_payment', TRUE
        )
      );
      
      -- Kurye wallet'ını güncelle
      PERFORM update_courier_wallet(NEW.courier_id, v_delivery_fee, 0, 0);
    END IF;
    
    RAISE NOTICE 'Otomatik ödeme işlendi: Sipariş %, Merchant: % TL, Kurye: % TL', 
      NEW.id, v_merchant_earning, v_delivery_fee;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.2 Orders Tablosuna Trigger Ekle
CREATE TRIGGER trigger_process_payment_on_delivery
  AFTER UPDATE OF status ON orders
  FOR EACH ROW
  EXECUTE FUNCTION process_order_payment_on_delivery();

-- 8.3 Kurye Wallet Güncelleme Fonksiyonu
CREATE OR REPLACE FUNCTION update_courier_wallet(
  p_courier_id UUID,
  p_balance_change DECIMAL DEFAULT 0,
  p_pending_amount DECIMAL DEFAULT 0,
  p_frozen_amount DECIMAL DEFAULT 0
)
RETURNS VOID AS $$
BEGIN
  -- Wallet yoksa oluştur
  INSERT INTO courier_wallets (courier_id, balance, pending_balance, frozen_balance)
  VALUES (p_courier_id, 0, 0, 0)
  ON CONFLICT (courier_id) DO NOTHING;
  
  -- Wallet'ı güncelle
  UPDATE courier_wallets
  SET 
    balance = balance + p_balance_change,
    pending_balance = pending_balance + p_pending_amount,
    frozen_balance = frozen_balance + p_frozen_amount,
    total_earnings = total_earnings + p_balance_change,
    total_deliveries = CASE WHEN p_balance_change > 0 THEN total_deliveries + 1 ELSE total_deliveries END,
    last_updated = NOW()
  WHERE courier_id = p_courier_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- 9. GELİŞMİŞ RAPORLAMA VİEWS
-- ===================================================================

-- 9.1 Günlük Gelir Raporu (Merchant)
CREATE OR REPLACE VIEW daily_merchant_earnings AS
SELECT 
  merchant_id,
  DATE(created_at) as earning_date,
  COUNT(*) as total_orders,
  SUM(amount) as total_earnings,
  SUM(commission_amount) as total_commissions,
  SUM(original_amount) as total_revenue,
  AVG(amount) as average_earning
FROM payment_transactions
WHERE status = 'completed' AND type = 'orderPayment'
GROUP BY merchant_id, DATE(created_at)
ORDER BY earning_date DESC;

-- 9.2 Günlük Gelir Raporu (Courier)
CREATE OR REPLACE VIEW daily_courier_earnings AS
SELECT 
  courier_id,
  DATE(created_at) as earning_date,
  COUNT(*) as total_deliveries,
  SUM(amount) as total_earnings,
  AVG(amount) as average_delivery_fee
FROM payment_transactions
WHERE status = 'completed' AND type = 'deliveryFee'
GROUP BY courier_id, DATE(created_at)
ORDER BY earning_date DESC;

-- 9.3 Sistem Geneli Komisyon Raporu
CREATE OR REPLACE VIEW system_commission_report AS
SELECT 
  DATE(created_at) as report_date,
  COUNT(DISTINCT merchant_id) as active_merchants,
  COUNT(DISTINCT courier_id) as active_couriers,
  COUNT(*) as total_transactions,
  SUM(original_amount) as total_order_volume,
  SUM(commission_amount) as total_commission_earned,
  SUM(vat_amount) as total_vat_collected,
  AVG(commission_amount) as average_commission
FROM payment_transactions
WHERE status = 'completed' AND type = 'orderPayment'
GROUP BY DATE(created_at)
ORDER BY report_date DESC;

-- ===================================================================
-- 10. WALLET BAKIYE KONTROL FONKSİYONLARI
-- ===================================================================

-- 10.1 Merchant Kullanılabilir Bakiye Hesapla
CREATE OR REPLACE FUNCTION get_merchant_available_balance(p_merchant_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_balance DECIMAL;
BEGIN
  SELECT (balance - frozen_balance) INTO v_balance
  FROM merchant_wallets
  WHERE merchant_id = p_merchant_id;
  
  RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10.2 Kurye Kullanılabilir Bakiye Hesapla
CREATE OR REPLACE FUNCTION get_courier_available_balance(p_courier_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_balance DECIMAL;
BEGIN
  SELECT (balance - frozen_balance) INTO v_balance
  FROM courier_wallets
  WHERE courier_id = p_courier_id;
  
  RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- 11. PARA ÇEKME İŞLEMLERİ
-- ===================================================================

-- 11.1 Merchant Para Çekme
CREATE OR REPLACE FUNCTION merchant_withdraw_money(
  p_merchant_id UUID,
  p_amount DECIMAL,
  p_bank_account TEXT,
  p_description TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_available_balance DECIMAL;
  v_transaction_id UUID;
BEGIN
  -- Kullanılabilir bakiyeyi kontrol et
  v_available_balance := get_merchant_available_balance(p_merchant_id);
  
  IF v_available_balance < p_amount THEN
    RAISE EXCEPTION 'Yetersiz bakiye. Kullanılabilir: % TL, İstenilen: % TL', 
      v_available_balance, p_amount;
  END IF;
  
  -- Para çekme transaction'ı oluştur
  INSERT INTO payment_transactions (
    order_id,
    merchant_id,
    amount,
    original_amount,
    commission_amount,
    vat_amount,
    currency,
    payment_method,
    status,
    type,
    created_at,
    gateway_reference,
    gateway_provider,
    gateway_response,
    description,
    metadata
  ) VALUES (
    'WITHDRAWAL_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    p_merchant_id,
    -p_amount,  -- Negatif miktar
    p_amount,
    0,
    0,
    'TRY',
    'bankTransfer',
    'pending',
    'withdrawal',
    NOW(),
    'WITHDRAW_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    'MANUAL',
    '{}',
    COALESCE(p_description, 'Para çekme'),
    jsonb_build_object(
      'bank_account', p_bank_account,
      'withdrawal_method', 'bank_transfer'
    )
  ) RETURNING id INTO v_transaction_id;
  
  -- Bakiyeden düş
  UPDATE merchant_wallets
  SET 
    balance = balance - p_amount,
    total_withdrawals = total_withdrawals + p_amount,
    last_updated = NOW()
  WHERE merchant_id = p_merchant_id;
  
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- KURULUM TAMAMLANDI
-- ===================================================================
-- 
-- ✅ payment_transactions tablosu oluşturuldu
-- ✅ merchant_wallets tablosu oluşturuldu
-- ✅ courier_wallets tablosu oluşturuldu (YENİ!)
-- ✅ commission_configs tablosu oluşturuldu
-- ✅ RLS politikaları eklendi
-- ✅ RPC fonksiyonları eklendi
-- ✅ OTOMATİK ödeme trigger'ı eklendi (YENİ!)
-- ✅ Kurye wallet sistemi eklendi (YENİ!)
-- ✅ Para çekme fonksiyonları eklendi (YENİ!)
-- ✅ Gelişmiş raporlama view'ları eklendi (YENİ!)
-- 
-- 🎯 ÖNEMLİ: orders TABLOSUNDA OLMASI GEREKEN KOLONLAR:
-- - id (UUID/TEXT)
-- - merchant_id (UUID)
-- - courier_id (UUID - nullable)
-- - customer_id (UUID - nullable)
-- - total_amount (DECIMAL)
-- - status (TEXT) - 'DELIVERED' değeri trigger'ı tetikler
-- - payment_method (TEXT - optional)
-- - metadata (JSONB) - delivery_fee bilgisi için
-- 
-- Sonraki Adımlar:
-- 1. Supabase Dashboard > SQL Editor'e bu script'i yapıştırın
-- 2. "Run" butonuna tıklayın
-- 3. Orders tablosunda status 'DELIVERED' olduğunda otomatik ödeme işlenecek!
-- 
-- ===================================================================
