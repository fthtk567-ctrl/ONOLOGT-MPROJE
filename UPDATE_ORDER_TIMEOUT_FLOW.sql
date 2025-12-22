-- 1. Yeni durum kolonu ekle
ALTER TABLE delivery_requests 
ADD COLUMN IF NOT EXISTS priority_until TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS final_deadline TIMESTAMPTZ;

-- 2. Tetikleyici fonksiyonunu güncelle
CREATE OR REPLACE FUNCTION set_delivery_deadlines() RETURNS TRIGGER AS $$
BEGIN
    -- Yeni sipariş oluşturulduğunda
    -- İlk 2 dakika priority
    NEW.priority_until := NOW() + INTERVAL '2 minutes';
    -- Toplam 10 dakika süre
    NEW.final_deadline := NOW() + INTERVAL '10 minutes';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Tetikleyiciyi güncelle
DROP TRIGGER IF EXISTS set_accept_deadline ON delivery_requests;
CREATE TRIGGER set_delivery_deadlines
    BEFORE INSERT ON delivery_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_delivery_deadlines();

-- 4. Durum güncelleme fonksiyonunu güncelle
CREATE OR REPLACE FUNCTION process_delivery_timeouts() RETURNS void AS $$
BEGIN
    -- Priority süresi dolan siparişleri NORMAL statüsüne al
    UPDATE delivery_requests
    SET 
        status = 'normal',
        updated_at = NOW()
    WHERE 
        status = 'priority'
        AND priority_until < NOW();

    -- Final deadline'ı geçen siparişleri otomatik reddet
    UPDATE delivery_requests
    SET 
        status = 'rejected',
        auto_rejected = TRUE,
        updated_at = NOW()
    WHERE 
        status IN ('priority', 'normal')
        AND final_deadline < NOW()
        AND auto_rejected = FALSE;
END;
$$ LANGUAGE plpgsql;

-- 5. Zamanlanmış görevi güncelle
SELECT cron.unschedule('reject-expired-orders');
SELECT cron.schedule('process-delivery-timeouts', '* * * * *', 'SELECT process_delivery_timeouts()');