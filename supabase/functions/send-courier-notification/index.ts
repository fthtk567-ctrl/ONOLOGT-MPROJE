// Edge Function: Kuryeye Yeni Teslimat İsteği Bildirimi Gönder (OneSignal)
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
    console.log('📦 [OneSignal] Yeni teslimat isteği:', payload)

    // Supabase client oluştur
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Kurye OneSignal Player ID'sini al
    console.log('🔍 Player ID arıyorum, Courier ID:', payload.courierId)
    
    const { data: tokenData, error: tokenError } = await supabase
      .from('push_tokens')
      .select('player_id, platform')
      .eq('user_id', payload.courierId)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single()

    console.log('📊 Database sonucu - tokenData:', tokenData, 'error:', tokenError)

    if (tokenError || !tokenData) {
      console.error('❌ OneSignal Player ID bulunamadı:', tokenError)
      return new Response(
        JSON.stringify({ error: 'Kurye için aktif OneSignal Player ID bulunamadı' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const playerId = tokenData.player_id
    console.log('✅ OneSignal Player ID bulundu:', playerId)
    console.log('🔍 Player ID Detayları:')
    console.log('   - Player ID:', playerId)
    console.log('   - Player ID Type:', typeof playerId)
    console.log('   - Player ID Length:', playerId?.length)
    console.log('   - Platform:', tokenData.platform)

    // OneSignal credentials
    const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
    const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_APP_REST_KEY')!

    console.log('🔑 OneSignal Credentials:')
    console.log('   - App ID:', ONESIGNAL_APP_ID)
    console.log('   - API Key başlangıç:', ONESIGNAL_REST_API_KEY?.substring(0, 20) + '...')

    // OneSignal bildirim mesajını oluştur (v5 API format)
    const oneSignalMessage = {
      app_id: ONESIGNAL_APP_ID,
      include_aliases: {
        onesignal_id: [playerId]
      },
      target_channel: 'push',
      headings: { en: '🚀 Yeni Teslimat İsteği!' },
      contents: { en: `${payload.merchantName} - ${payload.deliveryFee} TL` },
      data: {
        type: 'new_order',
        order_id: payload.orderId,
        merchant_name: payload.merchantName,
        delivery_address: payload.deliveryAddress,
        delivery_fee: payload.deliveryFee.toString(),
      },
      // iOS ARKA PLAN BİLDİRİMLERİ için ZORUNLU ayarlar
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
      ios_sound: 'default',
      mutable_content: true,
      content_available: true,
      priority: 5,
    }

    console.log('📤 [OneSignal] Bildirim gönderiliyor...')
    console.log('📨 OneSignal Message:', JSON.stringify(oneSignalMessage, null, 2))

    // OneSignal REST API'ye istek gönder
    const oneSignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(oneSignalMessage),
    })

    if (!oneSignalResponse.ok) {
      const errorText = await oneSignalResponse.text()
      console.error('❌ OneSignal hatası:', errorText)
      throw new Error(`OneSignal error: ${errorText}`)
    }

    const oneSignalResult = await oneSignalResponse.json()
    console.log('📦 OneSignal FULL Response:', JSON.stringify(oneSignalResult, null, 2))
    console.log('✅ OneSignal bildirimi gönderildi:', oneSignalResult)

    // Notification history'ye kaydet
    await supabase.from('notification_history').insert({
      user_id: payload.courierId,
      notification_type: 'new_order', // ✅ EKLENEN ALAN
      title: '🚀 Yeni Teslimat İsteği!',
      body: `${payload.merchantName} - ${payload.deliveryFee} TL`,
      data: {
        order_id: payload.orderId,
        merchant_name: payload.merchantName,
        delivery_address: payload.deliveryAddress,
        delivery_fee: payload.deliveryFee,
      },
      fcm_message_id: oneSignalResult.id, // OneSignal notification ID
      status: 'sent',
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        notificationId: oneSignalResult.id,
        recipients: oneSignalResult.recipients 
      }),
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
