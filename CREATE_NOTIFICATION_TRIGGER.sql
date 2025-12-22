-- =================================================================
-- ONLOG - Otomatik Bildirim Trigger'ı
-- Yeni teslimat isteği oluşturulduğunda notification_queue'ya ekle
-- =================================================================

-- 1. Önce notification_queue tablosunun var olduğundan emin ol
CREATE TABLE IF NOT EXISTS notification_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_request_id UUID NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index'ler (önce mevcut index'leri kaldır)
DROP INDEX IF EXISTS idx_notification_queue_processed;
DROP INDEX IF EXISTS idx_notification_queue_created;
DROP INDEX IF EXISTS idx_notification_queue_delivery;

CREATE INDEX idx_notification_queue_processed ON notification_queue(processed) WHERE processed = false;
CREATE INDEX idx_notification_queue_created ON notification_queue(created_at DESC);
CREATE INDEX idx_notification_queue_delivery ON notification_queue(delivery_request_id);

-- 2. RLS Politikaları
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can do everything" ON notification_queue;
CREATE POLICY "Service role can do everything" ON notification_queue
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- 3. Trigger Function'ı oluştur
CREATE OR REPLACE FUNCTION add_notification_to_queue()
RETURNS TRIGGER AS $$
DECLARE
    merchant_fcm_token TEXT;
    merchant_name TEXT;
BEGIN
    -- Merchant'ın FCM token'ını ve ismini al
    SELECT fcm_token, COALESCE(business_name, full_name, owner_name, 'İşletme')
    INTO merchant_fcm_token, merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Eğer FCM token varsa kuyruğa ekle
    IF merchant_fcm_token IS NOT NULL THEN
        INSERT INTO notification_queue (
            delivery_request_id,
            merchant_id,
            fcm_token,
            title,
            body,
            data,
            processed
        ) VALUES (
            NEW.id,
            NEW.merchant_id,
            merchant_fcm_token,
            '🚀 Yeni Teslimat İsteği',
            'Teslimat ücreti: ' || COALESCE(NEW.delivery_fee::TEXT, '0') || ' TL',
            jsonb_build_object(
                'type', 'new_delivery_request',
                'delivery_request_id', NEW.id,
                'merchant_id', NEW.merchant_id,
                'delivery_fee', NEW.delivery_fee,
                'status', NEW.status
            ),
            FALSE
        );
        
        RAISE NOTICE '✅ Bildirim kuyruğa eklendi: %', NEW.id;
    ELSE
        RAISE NOTICE '⚠️ Merchant FCM token yok: %', NEW.merchant_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger'ı oluştur (eskisi varsa sil)
DROP TRIGGER IF EXISTS trigger_add_notification_on_delivery_request ON delivery_requests;

CREATE TRIGGER trigger_add_notification_on_delivery_request
    AFTER INSERT ON delivery_requests
    FOR EACH ROW
    EXECUTE FUNCTION add_notification_to_queue();

-- 5. Kontrol
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_add_notification_on_delivery_request';

-- Test: Son 5 teslimat isteği
SELECT id, merchant_id, status, created_at 
FROM delivery_requests 
ORDER BY created_at DESC 
LIMIT 5;
