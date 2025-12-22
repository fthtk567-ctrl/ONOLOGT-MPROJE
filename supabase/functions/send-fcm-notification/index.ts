// Supabase Edge Function - FCM Push Notification Sender (HTTP v1 API)
// Bu function, notifications tablosundaki pending kayıtları okur ve FCM v1 API ile gönderir

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Base64 URL-safe encoding helper
function base64UrlEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

// OAuth2 Access Token al (Service Account kullanarak)
async function getAccessToken(serviceAccount: any): Promise<string> {
  const jwtHeader = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const now = Math.floor(Date.now() / 1000)
  const jwtClaimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }
  const jwtClaimSetEncoded = base64UrlEncode(JSON.stringify(jwtClaimSet))

  // JWT imzalama (RS256)
  const importedKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    importedKey,
    new TextEncoder().encode(`${jwtHeader}.${jwtClaimSetEncoded}`)
  )

  const signatureEncoded = arrayBufferToBase64Url(signature)
  const jwt = `${jwtHeader}.${jwtClaimSetEncoded}.${signatureEncoded}`

  // OAuth2 token al
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenResponse.json()
  
  if (!tokenData.access_token) {
    console.error('OAuth2 Token hatası:', tokenData)
    throw new Error(`OAuth2 token alınamadı: ${JSON.stringify(tokenData)}`)
  }
  
  return tokenData.access_token
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const pemContents = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  return bytes.buffer
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Firebase Service Account JSON (Supabase Secrets'te saklanmalı)
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT bulunamadı!')
    }

    const serviceAccount = JSON.parse(serviceAccountJson)
    const projectId = serviceAccount.project_id || Deno.env.get('FIREBASE_PROJECT_ID')

    console.log('🔍 Service Account project_id:', serviceAccount.project_id)
    console.log('🔍 Final projectId:', projectId)

    if (!projectId) {
      throw new Error('FCM project_id bulunamadı. FIREBASE_SERVICE_ACCOUNT JSON\'unda project_id alanı eksikse FIREBASE_PROJECT_ID secret\'ını ekleyin.')
    }

    // Access Token al
    const accessToken = await getAccessToken(serviceAccount)

    // Request body'den notification_id al (eğer varsa)
    const body = await req.json().catch(() => ({}))
    const notificationId = body.notification_id

    let notifications
    let fetchError

    if (notificationId) {
      // Sadece belirli notification'ı al
      const result = await supabase
        .from('notifications')
        .select('*')
        .eq('id', notificationId)
        .eq('notification_status', 'pending')
        .single()
      
      notifications = result.data ? [result.data] : []
      fetchError = result.error
    } else {
      // notification_id yoksa tüm pending'leri al (backward compatibility)
      const result = await supabase
        .from('notifications')
        .select('*')
        .eq('notification_status', 'pending')
        .limit(10)
      
      notifications = result.data || []
      fetchError = result.error
    }

    if (fetchError) {
      throw fetchError
    }

    if (!notifications || notifications.length === 0) {
      return new Response(
        JSON.stringify({ message: 'Gönderilecek bildirim yok' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`${notifications.length} bildirim gönderiliyor...`)

    // Her bildirimi FCM v1 API'ye gönder
    const results = await Promise.all(
      notifications.map(async (notification) => {
        try {
          // Project ID son kontrol
          if (!projectId || projectId === 'undefined' || projectId === 'null') {
            throw new Error(`Invalid projectId: "${projectId}" (type: ${typeof projectId})`)
          }
          
          // FCM v1 API URL
          const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
          console.log('🔗 FCM URL:', fcmUrl)

          // Data field'ını hazırla (FCM sadece string key-value kabul eder)
          const dataPayload: Record<string, string> = {
            title: notification.title,
            body: notification.message,
          }
          
          // notification.data varsa ekle
          if (notification.data && typeof notification.data === 'object') {
            Object.keys(notification.data).forEach(key => {
              dataPayload[key] = String(notification.data[key])
            })
          }
          
          // ⭐ YENİ: Kaynak bilgisini ekle (Yemek App entegrasyonu)
          if (notification.data?.source) {
            dataPayload.source = notification.data.source
          }
          if (notification.data?.external_order_id) {
            dataPayload.external_order_id = notification.data.external_order_id
          }

          // FCM v1 API'ye istek at
          const fcmResponse = await fetch(fcmUrl, {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token: notification.fcm_token,
                notification: {
                  title: notification.title,
                  body: notification.message,
                },
                data: dataPayload, // String key-value pairs
                android: {
                  priority: 'high',
                  notification: {
                    sound: 'default',
                    notification_priority: 'PRIORITY_HIGH',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                  },
                },
              },
            }),
          })

          const fcmResult = await fcmResponse.json()

          // Başarılı mı?
          if (fcmResponse.ok && fcmResult.name) {
            // notification_status = 'sent' yap
            await supabase
              .from('notifications')
              .update({
                notification_status: 'sent',
                sent_at: new Date().toISOString(),
              })
              .eq('id', notification.id)

            return { id: notification.id, status: 'sent', fcmResult }
          } else {
            // Hata var
            await supabase
              .from('notifications')
              .update({
                notification_status: 'failed',
                error_message: JSON.stringify(fcmResult),
              })
              .eq('id', notification.id)

            return { id: notification.id, status: 'failed', error: fcmResult }
          }
        } catch (error) {
          console.error(`Notification ${notification.id} hatası:`, error)
          
          // Hata kaydı
          await supabase
            .from('notifications')
            .update({
              notification_status: 'failed',
              error_message: error.message,
            })
            .eq('id', notification.id)

          return { id: notification.id, status: 'failed', error: error.message }
        }
      })
    )

    return new Response(
      JSON.stringify({
        message: 'Bildirimler işlendi',
        total: notifications.length,
        results: results,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Edge Function hatası:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
