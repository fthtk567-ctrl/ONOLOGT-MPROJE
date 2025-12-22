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
    const { data: tokenData, error: tokenError } = await supabase
      .from('push_tokens')
      .select('player_id, platform')
      .eq('user_id', payload.courierId)
      .eq('is_active', true)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single()

    if (tokenError || !tokenData) {
      console.error('❌ OneSignal Player ID bulunamadı:', tokenError)
      return new Response(
        JSON.stringify({ error: 'Kurye için aktif OneSignal Player ID bulunamadı' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const playerId = tokenData.player_id
    console.log('✅ OneSignal Player ID bulundu:', playerId.substring(0, 20) + '...')

    // OneSignal credentials
    const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
    const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')!

    // OneSignal bildirim mesajını oluştur
    const oneSignalMessage = {
      app_id: ONESIGNAL_APP_ID,
      include_player_ids: [playerId],
      headings: { tr: '🚀 Yeni Teslimat İsteği!' },
      contents: { tr: `${payload.merchantName} - ${payload.deliveryFee} TL` },
      data: {
        type: 'new_order',
        order_id: payload.orderId,
        merchant_name: payload.merchantName,
        delivery_address: payload.deliveryAddress,
        delivery_fee: payload.deliveryFee.toString(),
      },
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
      priority: 10,
    }

    console.log('📤 [OneSignal] Bildirim gönderiliyor...')

    // OneSignal REST API'ye istek gönder
    const oneSignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(oneSignalMessage),
    })

    if (!oneSignalResponse.ok) {
      const errorText = await oneSignalResponse.text()
      console.error('❌ OneSignal hatası:', errorText)
      throw new Error(`OneSignal error: ${errorText}`)
    }

    const oneSignalResult = await oneSignalResponse.json()
    console.log('✅ OneSignal bildirimi gönderildi:', oneSignalResult)

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
