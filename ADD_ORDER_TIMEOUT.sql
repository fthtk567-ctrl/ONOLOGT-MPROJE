-- 1. delivery_requests tablosuna timeout kolonları ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS accept_deadline TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS auto_rejected BOOLEAN DEFAULT FALSE;

-- 2. Otomatik red için fonksiyon
CREATE OR REPLACE FUNCTION auto_reject_expired_orders() RETURNS TRIGGER AS $$
BEGIN
    -- Yeni sipariş oluşturulduğunda 2 dakika sonrası için deadline belirle
    NEW.accept_deadline := NOW() + INTERVAL '2 minutes';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. INSERT trigger
DROP TRIGGER IF EXISTS set_accept_deadline ON delivery_requests;
CREATE TRIGGER set_accept_deadline
    BEFORE INSERT ON delivery_requests
    FOR EACH ROW
    EXECUTE FUNCTION auto_reject_expired_orders();

-- 4. Otomatik red için scheduled job (her dakika çalışacak)
CREATE OR REPLACE FUNCTION process_expired_orders() RETURNS void AS $$
BEGIN
    UPDATE delivery_requests
    SET 
        status = 'rejected',
        auto_rejected = TRUE,
        updated_at = NOW()
    WHERE 
        status = 'pending'
        AND accept_deadline < NOW()
        AND auto_rejected = FALSE;
END;
$$ LANGUAGE plpgsql;

-- 5. Scheduled job'ı oluştur (pgAgent gerekli)
SELECT cron.schedule('reject-expired-orders', '* * * * *', 'SELECT process_expired_orders()');

-- 6. Test: Son 5 teslimat isteğini kontrol et
SELECT 
    id, 
    status, 
    auto_rejected,
    accept_deadline,
    created_at,
    updated_at
FROM delivery_requests 
ORDER BY created_at DESC 
LIMIT 5;