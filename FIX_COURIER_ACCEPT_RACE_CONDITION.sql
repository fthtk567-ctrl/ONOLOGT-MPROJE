-- Kurye kabul işlemi için güvenli fonksiyon
CREATE OR REPLACE FUNCTION safe_accept_delivery(
    p_delivery_id UUID,
    p_courier_id UUID
) RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) AS $$
BEGIN
    -- Transaction başlat
    -- SERIALIZABLE: En yüksek izolasyon seviyesi
    -- Bu sayede aynı anda iki kurye kabul edemez
    BEGIN
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        
        -- Teslimatı kilitle ve durumunu kontrol et
        PERFORM id 
        FROM delivery_requests 
        WHERE id = p_delivery_id 
        AND status = 'pending'
        FOR UPDATE SKIP LOCKED;
        
        -- Eğer teslimat zaten alınmışsa veya yoksa
        IF NOT FOUND THEN
            RETURN QUERY SELECT 
                false::BOOLEAN,
                'Bu teslimat isteği artık müsait değil. Başka bir kurye almış olabilir.'::TEXT;
            RETURN;
        END IF;

        -- Kurye müsait mi kontrol et
        IF EXISTS (
            SELECT 1 FROM delivery_requests 
            WHERE courier_id = p_courier_id 
            AND status IN ('assigned', 'picked_up', 'delivering')
        ) THEN
            RETURN QUERY SELECT 
                false::BOOLEAN,
                'Aktif teslimatınız varken yeni teslimat alamazsınız.'::TEXT;
            RETURN;
        END IF;

        -- Teslimatı güvenli şekilde güncelle
        UPDATE delivery_requests 
        SET 
            courier_id = p_courier_id,
            status = 'assigned',
            assigned_at = NOW(),
            updated_at = NOW()
        WHERE id = p_delivery_id
        AND status = 'pending';

        -- Başarılı
        RETURN QUERY SELECT 
            true::BOOLEAN,
            'Teslimat başarıyla alındı!'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        -- Hata durumunda
        RETURN QUERY SELECT 
            false::BOOLEAN,
            'Bir hata oluştu: ' || SQLERRM::TEXT;
    END;
END;
$$ LANGUAGE plpgsql;

-- Test et
COMMENT ON FUNCTION safe_accept_delivery IS 
'Kurye teslimat kabul fonksiyonu. Race condition''ları önler.
Kullanım:
SELECT * FROM safe_accept_delivery(
    ''550e8400-e29b-41d4-a716-446655440000''::UUID, -- delivery_id
    ''b5c2d3d4-e5f6-4747-8838-614748494a4b''::UUID  -- courier_id
);';