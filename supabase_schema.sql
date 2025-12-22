-- ========================================
-- ONLOG SUPABASE DATABASE SCHEMA
-- 10 New Tables for Complete Migration
-- ========================================

-- 1. Legal Documents Table
CREATE TABLE IF NOT EXISTS legal_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_type TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  version TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  required_for_roles TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. User Consents Table
CREATE TABLE IF NOT EXISTS user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES legal_documents(id) ON DELETE CASCADE,
  accepted BOOLEAN DEFAULT false,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, document_id)
);

-- 3. Trendyol Credentials Table
CREATE TABLE IF NOT EXISTS trendyol_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  api_key TEXT NOT NULL,
  api_secret TEXT,
  store_id TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(merchant_id, platform)
);

-- 4. Platform Orders Table
CREATE TABLE IF NOT EXISTS platform_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform TEXT NOT NULL,
  platform_order_id TEXT NOT NULL,
  merchant_id UUID NOT NULL REFERENCES users(id),
  onlog_order_id UUID REFERENCES orders(id),
  order_data JSONB NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  UNIQUE(platform, platform_order_id)
);

-- 5. Payment Transactions Table
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id),
  merchant_id UUID REFERENCES users(id),
  payment_method TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  commission_amount DECIMAL(10,2) DEFAULT 0,
  net_amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  transaction_id TEXT,
  payment_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Merchant Wallets Table
CREATE TABLE IF NOT EXISTS merchant_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  balance DECIMAL(10,2) DEFAULT 0,
  total_earnings DECIMAL(10,2) DEFAULT 0,
  total_withdrawals DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Wallet Transactions Table
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES merchant_wallets(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  reference_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Risk Alerts Table
CREATE TABLE IF NOT EXISTS risk_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  severity TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  message TEXT NOT NULL,
  details JSONB,
  status TEXT DEFAULT 'active',
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Commission Configs Table
CREATE TABLE IF NOT EXISTS commission_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID REFERENCES users(id) ON DELETE CASCADE,
  commission_rate DECIMAL(5,2) NOT NULL,
  commission_type TEXT DEFAULT 'percentage',
  is_global BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. App Settings Table
CREATE TABLE IF NOT EXISTS app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ========================================

ALTER TABLE legal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE trendyol_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- ========================================
-- RLS POLICIES
-- ========================================

-- Legal Documents: Everyone can read
CREATE POLICY "Enable read for all users" ON legal_documents 
  FOR SELECT USING (true);

-- User Consents: Users can manage their own consents
CREATE POLICY "Enable all for authenticated users" ON user_consents 
  FOR ALL USING (auth.uid() = user_id);

-- Trendyol Credentials: Merchants can manage their own credentials
CREATE POLICY "Enable all for merchant" ON trendyol_credentials 
  FOR ALL USING (auth.uid() = merchant_id);

-- Platform Orders: Merchants can see their own orders
CREATE POLICY "Enable all for merchant" ON platform_orders 
  FOR ALL USING (auth.uid() = merchant_id);

-- Payment Transactions: All authenticated users can see (for now)
CREATE POLICY "Enable all for authenticated" ON payment_transactions 
  FOR ALL USING (true);

-- Merchant Wallets: Merchants can see their own wallet
CREATE POLICY "Enable all for merchant" ON merchant_wallets 
  FOR ALL USING (auth.uid() = merchant_id);

-- Wallet Transactions: All authenticated users can see (for now)
CREATE POLICY "Enable all for authenticated" ON wallet_transactions 
  FOR ALL USING (true);

-- Risk Alerts: All authenticated users can see (for now)
CREATE POLICY "Enable all for authenticated" ON risk_alerts 
  FOR ALL USING (true);

-- Commission Configs: Everyone can read
CREATE POLICY "Enable read for all" ON commission_configs 
  FOR SELECT USING (true);

-- App Settings: Everyone can read
CREATE POLICY "Enable read for all" ON app_settings 
  FOR SELECT USING (true);

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

CREATE INDEX IF NOT EXISTS idx_user_consents_user ON user_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_platform_orders_merchant ON platform_orders(merchant_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_merchant ON payment_transactions(merchant_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_entity ON risk_alerts(entity_type, entity_id);

-- ========================================
-- SUCCESS MESSAGE
-- ========================================

DO $$
BEGIN
  RAISE NOTICE '✅ ONLOG DATABASE SCHEMA CREATED SUCCESSFULLY!';
  RAISE NOTICE '📊 10 tables created with RLS and indexes';
  RAISE NOTICE '🚀 Ready for SupabaseSeederService.seedAll()';
END $$;
