# Firebase Cloud Messaging - Supabase Edge Function Setup

## ADIM 1: Firebase Service Account Key
1. https://console.firebase.google.com → onlog-push
2. Settings → Project settings → Service accounts
3. "Generate new private key" tıkla
4. JSON dosyasını indir

## ADIM 2: Supabase CLI Kur (PowerShell)
```powershell
# Scoop ile Supabase CLI kur
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

## ADIM 3: Supabase Projesi Başlat
```powershell
cd C:\onlog_projects
supabase init
supabase login
supabase link --project-ref piqhfygnbfaxvxbzqjkm
```

## ADIM 4: Edge Function Oluştur
```powershell
supabase functions new send-fcm-notification
```

## ADIM 5: Edge Function Kodu (TypeScript)

Dosya: `supabase/functions/send-fcm-notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Firebase Admin SDK alternatifi - HTTP v1 API kullan
const FIREBASE_PROJECT_ID = "onlog-push"
const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')!
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!

serve(async (req) => {
  try {
    const { userId, title, body, data } = await req.json()
    
    // Supabase'den FCM token al
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    const { data: user, error } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', userId)
      .single()
    
    if (error || !user?.fcm_token) {
      return new Response(
        JSON.stringify({ success: false, error: 'No FCM token found' }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      )
    }
    
    // OAuth2 token al (Firebase Admin SDK olmadan)
    const accessToken = await getAccessToken()
    
    // FCM HTTP v1 API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`
    
    const message = {
      message: {
        token: user.fcm_token,
        notification: {
          title: title,
          body: body,
        },
        data: data || {},
        android: {
          priority: 'high',
          notification: {
            channel_id: 'new_order_channel',
            sound: 'default',
          }
        }
      }
    }
    
    const response = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message)
    })
    
    const result = await response.json()
    
    if (response.ok) {
      return new Response(
        JSON.stringify({ success: true, result }),
        { headers: { "Content-Type": "application/json" } }
      )
    } else {
      console.error('FCM Error:', result)
      return new Response(
        JSON.stringify({ success: false, error: result }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }
    
  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})

// OAuth2 Access Token al (Firebase Admin SDK alternatifi)
async function getAccessToken(): Promise<string> {
  const jwtHeader = btoa(JSON.stringify({
    alg: "RS256",
    typ: "JWT"
  }))
  
  const now = Math.floor(Date.now() / 1000)
  const jwtClaimSet = btoa(JSON.stringify({
    iss: FIREBASE_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now
  }))
  
  const signatureInput = `${jwtHeader}.${jwtClaimSet}`
  
  // RS256 signature (Deno crypto API ile)
  const encoder = new TextEncoder()
  const keyData = encoder.encode(FIREBASE_PRIVATE_KEY)
  
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  )
  
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signatureInput)
  )
  
  const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
  const jwt = `${signatureInput}.${signatureBase64}`
  
  // Token al
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
  })
  
  const tokenData = await tokenResponse.json()
  return tokenData.access_token
}
```

## ADIM 6: Secrets Ekle
```powershell
# Firebase service account JSON'dan al
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
supabase secrets set FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxx@onlog-push.iam.gserviceaccount.com"
```

## ADIM 7: Deploy Et
```powershell
supabase functions deploy send-fcm-notification
```

## ADIM 8: Database Trigger'ı Güncelle

SQL:
```sql
CREATE OR REPLACE FUNCTION notify_courier_edge_function()
RETURNS TRIGGER AS $$
DECLARE
  merchant_name TEXT;
  function_url TEXT := 'https://piqhfygnbfaxvxbzqjkm.supabase.co/functions/v1/send-fcm-notification';
  service_role_key TEXT := 'YOUR_SERVICE_ROLE_KEY';
BEGIN
  IF NEW.courier_id IS NOT NULL AND (OLD.courier_id IS NULL OR OLD.courier_id != NEW.courier_id) THEN
    
    SELECT COALESCE(business_name, owner_name, full_name, 'Merchant')
    INTO merchant_name
    FROM users
    WHERE id = NEW.merchant_id;
    
    -- Edge Function'a POST gönder
    PERFORM extensions.http((
      'POST',
      function_url,
      ARRAY[
        extensions.http_header('Authorization', 'Bearer ' || service_role_key),
        extensions.http_header('Content-Type', 'application/json')
      ],
      'application/json',
      json_build_object(
        'userId', NEW.courier_id,
        'title', '🚀 Yeni Teslimat İsteği!',
        'body', merchant_name || ' - ' || NEW.declared_amount || ' TL',
        'data', json_build_object(
          'type', 'new_delivery',
          'delivery_id', NEW.id::text
        )
      )::text
    )::extensions.http_request);
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## TEST
```powershell
curl -X POST https://piqhfygnbfaxvxbzqjkm.supabase.co/functions/v1/send-fcm-notification \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"userId":"250f4abe-858a-457b-b972-9a76340b07c2","title":"Test","body":"Test mesajı"}'
```
