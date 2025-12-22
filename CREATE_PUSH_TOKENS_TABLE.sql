-- OneSignal Push Tokens Tablosu
-- Firebase FCM'den OneSignal'e geçiş için yeni tablo
-- Her kullanıcı için OneSignal Player ID'leri saklar

CREATE TABLE IF NOT EXISTS public.push_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    player_id TEXT NOT NULL, -- OneSignal Player ID
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    subscription_id TEXT, -- OneSignal Subscription ID
    device_model TEXT,
    device_os TEXT,
    app_version TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Bir kullanıcının her platform için yalnızca bir aktif token'ı olabilir
    UNIQUE(user_id, platform, player_id)
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON public.push_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_push_tokens_player_id ON public.push_tokens(player_id);
CREATE INDEX IF NOT EXISTS idx_push_tokens_active ON public.push_tokens(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_push_tokens_platform ON public.push_tokens(platform);

-- Updated_at otomasyonu
CREATE OR REPLACE FUNCTION update_push_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_push_tokens_updated_at
    BEFORE UPDATE ON public.push_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_push_tokens_updated_at();

-- RLS (Row Level Security) Politikaları
ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi token'larını görebilir
CREATE POLICY "Users can view their own tokens"
    ON public.push_tokens
    FOR SELECT
    USING (auth.uid() = user_id);

-- Kullanıcılar sadece kendi token'larını ekleyebilir
CREATE POLICY "Users can insert their own tokens"
    ON public.push_tokens
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Kullanıcılar sadece kendi token'larını güncelleyebilir
CREATE POLICY "Users can update their own tokens"
    ON public.push_tokens
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Kullanıcılar sadece kendi token'larını silebilir
CREATE POLICY "Users can delete their own tokens"
    ON public.push_tokens
    FOR DELETE
    USING (auth.uid() = user_id);

-- Service role tüm işlemleri yapabilir (Edge Functions için)
CREATE POLICY "Service role has full access"
    ON public.push_tokens
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- Temizlik fonksiyonu: 90 günden eski kullanılmayan token'ları sil
CREATE OR REPLACE FUNCTION cleanup_old_push_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM public.push_tokens
    WHERE last_used_at < NOW() - INTERVAL '90 days'
    AND is_active = false;
END;
$$ LANGUAGE plpgsql;

-- Kullanıcının eski token'larını pasif yap, yeni token'ı aktif et
CREATE OR REPLACE FUNCTION upsert_push_token(
    p_user_id UUID,
    p_player_id TEXT,
    p_platform TEXT,
    p_subscription_id TEXT DEFAULT NULL,
    p_device_model TEXT DEFAULT NULL,
    p_device_os TEXT DEFAULT NULL,
    p_app_version TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_token_id UUID;
BEGIN
    -- Aynı kullanıcı ve platform için eski token'ları pasif yap
    UPDATE public.push_tokens
    SET is_active = false,
        updated_at = NOW()
    WHERE user_id = p_user_id
    AND platform = p_platform
    AND player_id != p_player_id
    AND is_active = true;
    
    -- Yeni token'ı ekle veya güncelle
    INSERT INTO public.push_tokens (
        user_id,
        player_id,
        platform,
        subscription_id,
        device_model,
        device_os,
        app_version,
        is_active,
        last_used_at
    ) VALUES (
        p_user_id,
        p_player_id,
        p_platform,
        p_subscription_id,
        p_device_model,
        p_device_os,
        p_app_version,
        true,
        NOW()
    )
    ON CONFLICT (user_id, platform, player_id)
    DO UPDATE SET
        subscription_id = COALESCE(EXCLUDED.subscription_id, push_tokens.subscription_id),
        device_model = COALESCE(EXCLUDED.device_model, push_tokens.device_model),
        device_os = COALESCE(EXCLUDED.device_os, push_tokens.device_os),
        app_version = COALESCE(EXCLUDED.app_version, push_tokens.app_version),
        is_active = true,
        last_used_at = NOW(),
        updated_at = NOW()
    RETURNING id INTO v_token_id;
    
    RETURN v_token_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mevcut fcm_tokens verilerini yeni tabloya migrate et (opsiyonel)
-- NOT: Bu migration'ı çalıştırmadan önce mevcut fcm_tokens tablosunu kontrol et
-- UNCOMMENT YAPMADAN ÖNCE fcm_tokens tablosu yapısını kontrol et!

/*
INSERT INTO public.push_tokens (user_id, player_id, platform, created_at, updated_at, last_used_at)
SELECT 
    user_id,
    fcm_token as player_id, -- FCM token'ları geçici olarak player_id olarak kaydet
    platform,
    created_at,
    updated_at,
    updated_at as last_used_at
FROM public.user_fcm_tokens
ON CONFLICT (user_id, platform, player_id) DO NOTHING;
*/

-- Test verisi ekle (SADECE DEV ORTAMINDA!)
-- PRODUCTION'da bu satırı YORUMA AL!
/*
INSERT INTO public.push_tokens (user_id, player_id, platform, device_model, device_os, app_version)
VALUES (
    (SELECT id FROM users WHERE email = 'courier@onlog.com' LIMIT 1),
    'test-player-id-123',
    'ios',
    'iPhone 11',
    '26.0',
    '1.0.0'
) ON CONFLICT DO NOTHING;
*/

-- Tablo bilgilerini göster
SELECT 
    'push_tokens tablosu başarıyla oluşturuldu!' as message,
    COUNT(*) as total_tokens,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(*) FILTER (WHERE is_active = true) as active_tokens
FROM public.push_tokens;
