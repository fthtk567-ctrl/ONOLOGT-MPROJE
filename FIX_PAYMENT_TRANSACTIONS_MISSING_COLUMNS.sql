-- payment_transactions tablosuna eksik kolonları ekle
ALTER TABLE payment_transactions
ADD COLUMN IF NOT EXISTS type TEXT CHECK (type IN ('orderPayment', 'deliveryFee', 'withdrawal', 'commission')),
ADD COLUMN IF NOT EXISTS courier_id UUID REFERENCES auth.users(id);

-- Index'ler ekle
CREATE INDEX IF NOT EXISTS idx_payment_transactions_type ON payment_transactions(type);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_courier ON payment_transactions(courier_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_merchant ON payment_transactions(merchant_id);

-- Kontrol et
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'payment_transactions'
  AND column_name IN ('type', 'courier_id')
ORDER BY ordinal_position;
