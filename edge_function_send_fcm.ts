// Supabase Edge Function: send-fcm-notification
// Firebase Cloud Messaging HTTP v1 API ile bildirim gönder

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Firebase Service Account bilgileri
const FIREBASE_PROJECT_ID = "onlog-push"
const FIREBASE_PRIVATE_KEY = "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCaaor2EXlwjRPm\nTGPq84DpF9qPmZFDd8leE/vu94A/67RdOS1ftqC6cf/UMh32PGVA+wOtfv5krA3p\n3jl+W1Q7I++R+jBaSpReLFnU49LXKDe8RrCnEFGArYmrnVKLiAamwKHyVSrK9Vb1\na5do4Voe38MWlvfuIb8TOeQcO2/j2sEbE4Fprsgh+FkIMFL31p3BuTs8DyN8w6GK\ncZLTSZEwY2jXanXJjYQ/lWKWEJKbpAE119fsnjom7DpYtLDmfVb7azarqFj8dD14\nzUMCWw0qkDvwJ0z9zoeFCrR+lkEel6xC5eavaUx0mpd3C7S5y5A1xqPTE46V22YU\nAl5dD+evAgMBAAECggEAOE4rN4itqG242Nv3/x8lXVlWV9BeWKSgJ47P6ZYUDLrM\nvMVxlxoHx5Rz/ZL8u+HP5f7hm2zYJCtcs29VtY5ly17SJ398DCBvs1smsmsUYWIH\n2L5KAdEAdxRQQ+SMydYi3sEVDEEj5nfJapn9zr+FVgavo1gPNaTWgJM2a1j89q8n\ndVQGvWmgLQRcGafA05cnWZrYRh2fI1m+ZoQXDVYxFGuR6+nvkplEPhrsfR6bhXw5\n1uWWumD/lOLjnhZ2j5zF9Hk1znq3tLX9EGSXBu3Ct9VVkKmPQeJ79xCKrNH9GsY2\nEvyfYhKtoDvidN3+HhxJ52JalGlI/sbyIS0fSSATcQKBgQDMyCOjaXaejvi50vVn\n2gwgLQHAI6JViCQcKfBIId0TU80AV3aYyOKUYJ8HGOdFNQxv8vz9bcEuSsUU6Mqw\nNpmCfevgnGbSR/Rem1aeWPZsKwaqKvBvBrjxgzmZ0cFd7ZGUCzXz80SOYYjtSqZu\nTQxTiR69SVQNEuhN6tF56p2dVwKBgQDBCZJVmlEbGDRZKGXhtP1KYIiKEnWN1HnL\nMv4TxoZsKGeXHbVfCaLMDfp0NpXePBOH1+quGkvOBGJyLsqC40DlOIGX8hctWKnN\nYMLkK+AVzW8NJdzJCeNFMh1cDO12i+KStuc18wYTTiIO8yyw6wX2MxCKwTK6Cp14\nH5m4qW45aQKBgGOmJIl5YYqIwgoS2O5fUbU6kXaBIJaEeCXoVo+TQvQLvF8lMIXq\ngy920QvwF2I7DUFQucFM7ktrgPnKyg7zksHIKscS9InxD74V0xGc8tTyHv0hhfxR\nBiAoHhh21KSzXTrwNaHvR/YNCkeGIvTbs1rXB8lObIMsJzT7RlIQVABjAoGAEFvx\nTNPhH7yzYwLrb29ZL95yc9EQqU5ia/gMVDy006Gw9buMzVsRst1UZljh5o2M0ixY\nNR0BY5o3hZm1i9Yaf9KEGQ5pLGyhJ0iV+6REP1TDnoeg6GCwJAMVPeHSlgNQ1kIt\n4gKQdz5d4Ip3NR8VyEGXm0q4M9AGfFGhQ2cIclECgYBh+2BSHtTRpg5H7+kPCh88\n5RAAlUaDEUscc0si72ocqVi1hPyuDpHpq5aYT9iw/QySdZxMN17mxuUfiAt8pVMe\nECd0qy7R+1HupXgP2E/TVAEw0w5wx+AjLIeXATZzdfOBdGe55URkNGGSbOMP3pk6\nYy1BI04LZX0hWMkPrWPdOg==\n-----END PRIVATE KEY-----\n"
const FIREBASE_CLIENT_EMAIL = "firebase-adminsdk-fbsvc@onlog-push.iam.gserviceaccount.com"

serve(async (req) => {
  try {
    // CORS headers ekle
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, content-type',
        }
      })
    }

    const requestBody = await req.text()
    console.log('📥 Raw request body:', requestBody)
    
    const { userId, title, body, data } = JSON.parse(requestBody)
    
    console.log('📱 FCM İsteği alındı:', { userId, title })
    
    // Supabase'den FCM token al
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const userResponse = await fetch(`${supabaseUrl}/rest/v1/users?id=eq.${userId}&select=fcm_token`, {
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
      }
    })
    
    const users = await userResponse.json()
    
    if (!users || users.length === 0 || !users[0].fcm_token) {
      console.error('❌ FCM token bulunamadı:', userId)
      return new Response(
        JSON.stringify({ success: false, error: 'No FCM token found' }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      )
    }
    
    const fcmToken = users[0].fcm_token
    console.log('✅ FCM Token bulundu')
    
    // OAuth2 Access Token al
    const accessToken = await getAccessToken()
    console.log('✅ Access token alındı')
    
    // FCM HTTP v1 API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`
    
    // DATA-ONLY MESSAGE (arka plan için background handler çalışır)
    const message = {
      message: {
        token: fcmToken,
        data: {
          title: title,           // data içinde gönder
          body: body,
          ...(data || {}),
        },
        android: {
          priority: 'high',
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
      console.log('✅ FCM bildirimi gönderildi!')
      return new Response(
        JSON.stringify({ success: true, result }),
        { headers: { "Content-Type": "application/json" } }
      )
    } else {
      console.error('❌ FCM hatası:', result)
      return new Response(
        JSON.stringify({ success: false, error: result }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }
    
  } catch (error) {
    console.error('❌ Function error:', error.message)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})

// OAuth2 Access Token al
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  
  const header = {
    alg: "RS256",
    typ: "JWT"
  }
  
  const claimSet = {
    iss: FIREBASE_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now
  }
  
  // Base64 encode
  const encodedHeader = btoa(JSON.stringify(header))
  const encodedClaimSet = btoa(JSON.stringify(claimSet))
  
  const signatureInput = `${encodedHeader}.${encodedClaimSet}`
  
  // RS256 signature
  const encoder = new TextEncoder()
  const keyData = encoder.encode(FIREBASE_PRIVATE_KEY)
  
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBinary(FIREBASE_PRIVATE_KEY),
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
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  
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

// PEM formatını binary'ye çevir
function pemToBinary(pem: string): Uint8Array {
  const pemContents = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  
  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  
  return bytes
}
