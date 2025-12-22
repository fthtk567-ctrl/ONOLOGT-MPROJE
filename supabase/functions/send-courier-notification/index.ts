// Edge Function: Kuryeye Yeni Teslimat İsteği Bildirimi Gönder
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  orderId: string
  courierId: string
  merchantName: string
  deliveryAddress: string
  deliveryFee: number
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Request body'den veriyi al
    const payload: NotificationPayload = await req.json()
    console.log('📦 Yeni teslimat isteği:', payload)

    // Supabase client oluştur
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Kurye FCM token'ını al
    const { data: tokenData, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token')
      .eq('user_id', payload.courierId)
      .eq('is_active', true)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single()

    if (tokenError || !tokenData) {
      console.error('❌ FCM token bulunamadı:', tokenError)
      return new Response(
        JSON.stringify({ error: 'Kurye için aktif FCM token bulunamadı' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const fcmToken = tokenData.fcm_token
    console.log('✅ FCM Token bulundu:', fcmToken.substring(0, 20) + '...')

    // Firebase Service Account credentials
    const firebaseCredentials = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!)
    
    // OAuth2 Access Token al
    const accessToken = await getAccessToken(firebaseCredentials)
    console.log('✅ Access Token alındı')

    // FCM bildirim mesajını oluştur
    const fcmMessage = {
      message: {
        token: fcmToken,
        notification: {
          title: '🚀 Yeni Teslimat İsteği!',
          body: `${payload.merchantName} - ${payload.deliveryFee} TL`,
        },
        data: {
          type: 'new_order',
          order_id: payload.orderId,
          merchant_name: payload.merchantName,
          delivery_address: payload.deliveryAddress,
          delivery_fee: payload.deliveryFee.toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'new_order',
            sound: 'default',
            priority: 'high',
          },
        },
      },
    }

    // FCM V1 API'ye istek gönder
    const projectId = firebaseCredentials.project_id
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const fcmResponse = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmMessage),
    })

    if (!fcmResponse.ok) {
      const errorText = await fcmResponse.text()
      console.error('❌ FCM hatası:', errorText)
      throw new Error(`FCM error: ${errorText}`)
    }

    const fcmResult = await fcmResponse.json()
    console.log('✅ FCM bildirimi gönderildi:', fcmResult)

    // Notification history'ye kaydet
    await supabase.from('notification_history').insert({
      user_id: payload.courierId,
      title: '🚀 Yeni Teslimat İsteği!',
      body: `${payload.merchantName} - ${payload.deliveryFee} TL`,
      data: {
        order_id: payload.orderId,
        merchant_name: payload.merchantName,
        delivery_address: payload.deliveryAddress,
        delivery_fee: payload.deliveryFee,
      },
      fcm_message_id: fcmResult.name,
      status: 'sent',
    })

    return new Response(
      JSON.stringify({ success: true, messageId: fcmResult.name }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Hata:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Google OAuth2 Access Token almak için yardımcı fonksiyon
async function getAccessToken(credentials: any): Promise<string> {
  const jwtHeader = {
    alg: 'RS256',
    typ: 'JWT',
  }

  const now = Math.floor(Date.now() / 1000)
  const jwtClaimSet = {
    iss: credentials.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  // JWT oluştur
  const jwtHeaderBase64 = base64UrlEncode(JSON.stringify(jwtHeader))
  const jwtClaimSetBase64 = base64UrlEncode(JSON.stringify(jwtClaimSet))
  const signatureInput = `${jwtHeaderBase64}.${jwtClaimSetBase64}`

  // Private key ile imzala
  const privateKey = await importPrivateKey(credentials.private_key)
  const signature = await signJWT(signatureInput, privateKey)
  const jwt = `${signatureInput}.${signature}`

  // Token endpoint'e istek gönder
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  if (!tokenResponse.ok) {
    throw new Error(`Token request failed: ${await tokenResponse.text()}`)
  }

  const tokenData = await tokenResponse.json()
  return tokenData.access_token
}

function base64UrlEncode(str: string): string {
  const encoder = new TextEncoder()
  const data = encoder.encode(str)
  let base64 = btoa(String.fromCharCode(...data))
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemContents = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

  return await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  )
}

async function signJWT(data: string, privateKey: CryptoKey): Promise<string> {
  const encoder = new TextEncoder()
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    encoder.encode(data)
  )
  
  const signatureArray = new Uint8Array(signature)
  let base64 = btoa(String.fromCharCode(...signatureArray))
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}
