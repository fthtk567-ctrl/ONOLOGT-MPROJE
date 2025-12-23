-- ✅ OneSignal Trigger Fonksiyonunu Düzelt
-- delivery_fee → declared_amount (tablo yapısına uygun)

CREATE OR REPLACE FUNCTION send_courier_onesignal_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_player_id TEXT;
  v_merchant_name TEXT;
  v_delivery_address TEXT;
  v_delivery_fee NUMERIC;
  v_edge_function_url TEXT;
  v_response extensions.http_response;
  v_service_role_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY3MjgyOSwiZXhwIjoyMDc2MjQ4ODI5fQ.-_kJYS1oba6vsC4OuTccK9gAVLySigjCI_pHOuvtHt0'; -- 🔥 YENİ KEY (2025-12-23)
BEGIN
  IF (TG_OP = 'UPDATE' AND NEW.courier_id IS NOT NULL AND 
      (OLD.courier_id IS NULL OR OLD.courier_id != NEW.courier_id)) OR
     (TG_OP = 'INSERT' AND NEW.courier_id IS NOT NULL) THEN
    
    RAISE NOTICE '[OneSignal] Kuryeye bildirim gönderiliyor: %', NEW.courier_id;
    
    SELECT player_id INTO v_player_id
    FROM push_tokens
    WHERE user_id = NEW.courier_id
      AND is_active = true
    ORDER BY updated_at DESC
    LIMIT 1;
    
    IF v_player_id IS NULL THEN
      RAISE WARNING '[OneSignal] Player ID bulunamadı: %', NEW.courier_id;
      RETURN NEW;
    END IF;
    
    SELECT COALESCE(business_name, owner_name, 'Merchant')
    INTO v_merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    v_delivery_address := COALESCE(NEW.delivery_location->>'address', 'Adres bilgisi yok');
    v_delivery_fee := COALESCE(NEW.declared_amount, 0); -- 🔥 BURASI DEĞİŞTİ: delivery_fee → declared_amount
    
    v_edge_function_url := 'https://oilldfyywtzybrmpyixx.supabase.co/functions/v1/send-courier-notification';
    
    RAISE NOTICE '[OneSignal] Edge Function çağırılıyor...';
    
    SELECT * INTO v_response
    FROM extensions.http((
      'POST',
      v_edge_function_url,
      ARRAY[
        extensions.http_header('Content-Type', 'application/json'),
        extensions.http_header('Authorization', 'Bearer ' || v_service_role_key)
      ],
      'application/json',
      json_build_object(
        'orderId', NEW.id::TEXT,
        'courierId', NEW.courier_id::TEXT,
        'merchantName', v_merchant_name,
        'deliveryAddress', v_delivery_address,
        'deliveryFee', v_delivery_fee
      )::text
    )::extensions.http_request);
    
    IF v_response.status >= 200 AND v_response.status < 300 THEN
      RAISE NOTICE '[OneSignal] ✅ Bildirim gönderildi (HTTP %)', v_response.status;
    ELSE
      RAISE WARNING '[OneSignal] ⚠️ Hata (HTTP %) - %', v_response.status, v_response.content;
    END IF;
    
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING '[OneSignal] ❌ Hata: %', SQLERRM;
    RETURN NEW;
END;
$$;
