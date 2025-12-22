import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Request body'yi parse et
    const { delivery_request_id, courier_id, merchant_name, declared_amount, courier_payment_due } = await req.json()

    console.log('📨 FCM bildirimi gönderiliyor:', { courier_id, merchant_name })

    // Courier'ı ve FCM token'ını al
    const { data: courier, error: courierError } = await supabase
      .from('users')
      .select('fcm_token, email')
      .eq('id', courier_id)
      .single()

    if (courierError || !courier?.fcm_token) {
      console.error('❌ Kurye FCM token bulunamadı:', courierError)
      return new Response(
        JSON.stringify({ error: 'Kurye FCM token bulunamadı' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // FCM bildirimi hazırla
    const fcmPayload = {
      message: {
        token: courier.fcm_token,
        notification: {
          title: '🚀 Yeni Teslimat İsteği!',
          body: `${merchant_name} - Tutar: ${declared_amount} TL - Kazanç: ${courier_payment_due} TL`,
        },
        data: {
          type: 'new_delivery_request',
          delivery_request_id: delivery_request_id,
          merchant_name: merchant_name,
          declared_amount: declared_amount.toString(),
          courier_payment_due: courier_payment_due.toString(),
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'new_order_channel',
            sound: 'default',
            priority: 'high',
          },
        },
      },
    }

    // Google FCM Server Key (Firebase Console'dan alın)
    const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')
    if (!FCM_SERVER_KEY) {
      throw new Error('FCM_SERVER_KEY environment variable bulunamadı')
    }

    // FCM'e bildirim gönder
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: courier.fcm_token,
        notification: {
          title: '🚀 Yeni Teslimat İsteği!',
          body: `${merchant_name} - Tutar: ${declared_amount} TL`,
        },
        data: {
          type: 'new_delivery_request',
          delivery_request_id: delivery_request_id,
        },
      }),
    })

    const fcmResult = await fcmResponse.json()
    console.log('✅ FCM Response:', fcmResult)

    if (fcmResult.success === 1) {
      return new Response(
        JSON.stringify({ success: true, message: 'Bildirim gönderildi' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } else {
      throw new Error(`FCM Hatası: ${JSON.stringify(fcmResult)}`)
    }

  } catch (error) {
    console.error('❌ Hata:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})