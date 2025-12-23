-- MIGRATE_BUDGET_LEDGER_MODEL.sql
-- Amaç: Yüzdeye dayalı komisyonu kaldırıp budget_try + ledger tabanlı kurye ödemesine geçiş.
-- Bu script üretim öncesi test/stage ortamında uygulanmalıdır.

BEGIN;

-- 1) Eski yüzde tabanlı hesaplama fonksiyon/trigger'larını kapat
DROP TRIGGER IF EXISTS trigger_calculate_commissions ON delivery_requests;
DROP FUNCTION IF EXISTS calculate_commissions();

-- 2) Yeni kolonlar (varsa NO-OP olur)
ALTER TABLE delivery_requests
  ADD COLUMN IF NOT EXISTS budget_try DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS calculated_offer_try DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS courier_payment_due DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending';

-- 3) Ledger tablo-su
CREATE TABLE IF NOT EXISTS courier_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID NOT NULL REFERENCES users(id),
  delivery_request_id UUID REFERENCES delivery_requests(id),
  job_budget_try DECIMAL(10,2),
  calculated_offer_try DECIMAL(10,2),
  payout_try DECIMAL(10,2),
  currency TEXT DEFAULT 'TRY',
  entry_type TEXT NOT NULL, -- earning | adjustment | penalty | bonus
  reason TEXT,
  status TEXT DEFAULT 'posted', -- posted | pending | void
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_courier_ledger_courier ON courier_ledger(courier_id);
CREATE INDEX IF NOT EXISTS idx_courier_ledger_delivery ON courier_ledger(delivery_request_id);
CREATE INDEX IF NOT EXISTS idx_courier_ledger_status ON courier_ledger(status);

-- 4) DELIVERED olunca ödemeyi kilitleyen fonksiyon/trigger
CREATE OR REPLACE FUNCTION log_job_earnings_on_delivery()
RETURNS TRIGGER AS $$
DECLARE
  v_payout DECIMAL(10,2);
BEGIN
  IF NEW.status = 'delivered' THEN
    -- calculated_offer_try uygulama/servis tarafından set edilmiş olmalı
    v_payout := LEAST(COALESCE(NEW.calculated_offer_try, 0), COALESCE(NEW.budget_try, 0));
    NEW.courier_payment_due := v_payout;

    -- Ledger satırı ekle (idempotent: aynı delivery için varsa ekleme)
    INSERT INTO courier_ledger (courier_id, delivery_request_id, job_budget_try, calculated_offer_try, payout_try, entry_type, reason)
    SELECT NEW.courier_id, NEW.id, NEW.budget_try, NEW.calculated_offer_try, v_payout, 'earning', 'DELIVERED'
    WHERE NOT EXISTS (
      SELECT 1 FROM courier_ledger WHERE delivery_request_id = NEW.id AND entry_type = 'earning'
    );

    -- payment_status pending'e çek
    NEW.payment_status := 'pending';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_job_earnings_on_delivery ON delivery_requests;
CREATE TRIGGER trg_log_job_earnings_on_delivery
  BEFORE UPDATE OF status ON delivery_requests
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION log_job_earnings_on_delivery();

-- 5) Wallet için materialized view (ledger toplamından)
DROP MATERIALIZED VIEW IF EXISTS courier_wallets_view;
CREATE MATERIALIZED VIEW courier_wallets_view AS
SELECT
  courier_id,
  SUM(CASE WHEN entry_type IN ('earning','bonus') THEN payout_try ELSE 0 END
      + CASE WHEN entry_type IN ('penalty','adjustment') THEN payout_try ELSE 0 END) AS balance,
  SUM(CASE WHEN status = 'posted' THEN payout_try ELSE 0 END) AS pending_balance,
  COUNT(*) FILTER (WHERE entry_type = 'earning') AS total_deliveries
FROM courier_ledger
GROUP BY courier_id;

-- 6) payment_status yardımcı CHECK
ALTER TABLE delivery_requests
  ADD CONSTRAINT payment_status_valid CHECK (payment_status IN ('pending','completed','failed'));

-- 7) Eski commission_configs artık kullanılmıyor (trigger silindi, tablo kalabilir ama pasif)
-- Eğer tabloyu silmek isterseniz: DROP TABLE IF EXISTS commission_configs;

COMMIT;

-- Cron örneği (Supabase cron ile ayrı ekleyin):
-- SELECT cron.schedule('sync-wallet-from-ledger', '*/5 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY courier_wallets_view');
