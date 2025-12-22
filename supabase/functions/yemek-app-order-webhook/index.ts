import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// deno-lint-ignore no-explicit-any
declare const Deno: { env: { get(key: string): string | undefined } }

type MerchantMapping = {
  onlog_merchant_id: string
  restaurant_name: string | null
  yemek_app_restaurant_id: string
  is_active: boolean
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-yemek-app-signature',
}

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    
    console.log('[Yemek App v2] Incoming order:', payload.order_id)
    console.log('[Yemek App v2] FULL PAYLOAD:', JSON.stringify(payload, null, 2))

    // 1. API Key Kontrolü
    const authHeader = req.headers.get('Authorization')
    const expectedKey = Deno.env.get('YEMEK_APP_API_KEY')
    
    if (!authHeader || authHeader !== `Bearer ${expectedKey}`) {
      console.error('[Yemek App] Unauthorized request')
      return new Response(
        JSON.stringify({ 
          success: false, 
          error_code: 'UNAUTHORIZED',
          message: 'Invalid API key' 
        }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    console.log('[Yemek App] Supabase URL:', supabaseUrl)
    const supabase = createClient(supabaseUrl, supabaseKey)

    // 3. Merchant Mapping Kontrolü - TÜM KAYITLARI ÇEK VE JAVASCRIPT'TE FİLTRELE
    console.log('[Yemek App] Looking for restaurant_id:', payload.restaurant_id)

    const normalizedSearchId = payload.restaurant_id?.toString().trim().toLowerCase()
    
    // Tüm aktif mapping'leri çek
    const { data, error: mappingError } = await supabase
      .from<MerchantMapping>('onlog_merchant_mapping')
      .select('onlog_merchant_id, restaurant_name, yemek_app_restaurant_id, is_active')
      .eq('is_active', true)
    const allMappings: MerchantMapping[] = data ?? []
    
    const debugSample = allMappings.slice(0, 10).map((m) => ({
      yemek_app_restaurant_id: m.yemek_app_restaurant_id,
      normalized_id: m.yemek_app_restaurant_id?.trim().toLowerCase(),
      length: m.yemek_app_restaurant_id?.length,
      onlog_merchant_id: m.onlog_merchant_id
    }))

    console.log('[Yemek App] All mappings fetched:', { 
      total: allMappings.length,
      mappingError,
      searchId: normalizedSearchId,
      sample: debugSample
    })
    
    // JavaScript'te manuel filtrele
    const mapping = allMappings.find((m) => (
      m.yemek_app_restaurant_id?.trim().toLowerCase() === normalizedSearchId
    )) || null
    
    console.log('[Yemek App] After JS filter:', { 
      found: !!mapping,
      mapping: mapping ? { id: mapping.onlog_merchant_id, name: mapping.restaurant_name } : null
    })
    
    if (mappingError || !mapping) {
      console.error('[Yemek App] Restaurant not found:', payload.restaurant_id, 'Error:', mappingError)
      return new Response(
        JSON.stringify({ 
          success: false,
          error_code: 'RESTAURANT_NOT_FOUND',
          message: `Restaurant ${payload.restaurant_id} is not registered in ONLOG`
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log('[Yemek App] Restaurant found:', mapping.restaurant_name, 'ID:', mapping.onlog_merchant_id)

    // 4. Hızlı Kurye Modu Kontrolü
    const isQuickCourier = payload.quick_courier_request === true
    console.log('[Yemek App] Request type:', isQuickCourier ? 'QUICK COURIER (text-only address)' : 'NORMAL ORDER (map coordinates)')

    // 4.1. Tutar ve Ödeme Yöntemi Validasyonu (HER ZAMAN ZORUNLU)
    if (!payload.declared_amount || payload.declared_amount <= 0) {
      console.error('[Yemek App] REJECTED - Invalid amount:', payload.declared_amount)
      return new Response(
        JSON.stringify({ 
          success: false,
          error_code: 'INVALID_AMOUNT',
          message: 'Sipariş tutarı zorunludur ve 0\'dan büyük olmalıdır (komisyon hesaplaması için gerekli)',
          received_amount: payload.declared_amount || null
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (!payload.payment_method || !['cash', 'online', 'card'].includes(payload.payment_method)) {
      console.error('[Yemek App] REJECTED - Invalid payment method:', payload.payment_method)
      return new Response(
        JSON.stringify({ 
          success: false,
          error_code: 'INVALID_PAYMENT_METHOD',
          message: 'Ödeme yöntemi zorunludur (cash, online, card)',
          received_payment_method: payload.payment_method || null
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // 4.2. Koordinat Validasyonu (Sadece normal sipariş için zorunlu)
    if (!isQuickCourier) {
      if (!payload.delivery_address || 
          !payload.delivery_address.latitude || 
          !payload.delivery_address.longitude ||
          payload.delivery_address.latitude === 0 ||
          payload.delivery_address.longitude === 0) {
        console.error('[Yemek App] REJECTED - Invalid delivery address:', payload.delivery_address)
        return new Response(
          JSON.stringify({ 
            success: false,
            error_code: 'INVALID_DELIVERY_ADDRESS',
            message: 'Normal sipariş için teslimat adresi koordinatları zorunludur (latitude/longitude 0 olamaz)',
            received_coordinates: {
              latitude: payload.delivery_address?.latitude || null,
              longitude: payload.delivery_address?.longitude || null
            }
          }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
      console.log('[Yemek App] Delivery address valid ✅')
    } else {
      // Hızlı kurye modunda text adres varsa yeter
      if (!payload.delivery_address?.full_address?.trim()) {
        console.error('[Yemek App] REJECTED - Quick courier needs text address')
        return new Response(
          JSON.stringify({ 
            success: false,
            error_code: 'MISSING_TEXT_ADDRESS',
            message: 'Hızlı kurye modu için en azından text adres gereklidir',
          }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
      console.log('[Yemek App] Quick courier mode - text address valid ✅')
    }
    
    // 5. Teslimat Ücreti Hesaplama
    const deliveryFee = 15.00
    const merchantCommission = payload.declared_amount * 0.20
    
    // 6. Delivery Request Oluştur
    const deliveryData = {
      merchant_id: mapping.onlog_merchant_id,
      package_count: payload.package_count || 1,
      declared_amount: payload.declared_amount,
      merchant_payment_due: merchantCommission,
      courier_payment_due: 0, // Kurye atanınca güncellenecek
      status: 'pending',
      
      // ⭐ YENİ ALANLAR - Müşteri bilgileri
      recipient_name: payload.customer_name || 'Müşteri',
      recipient_phone: payload.customer_phone || '',
      
      // ⭐ YENİ ALANLAR - Merchant bilgileri
      merchant_name: payload.restaurant_name || mapping.restaurant_name || null,
      merchant_phone: payload.restaurant_phone || null,
      
      // ⭐ YENİ ALANLAR - Ödeme ve zaman
      payment_method: payload.payment_method, // ✅ ZORUNLU - validasyon eklendi
      estimated_delivery_time: payload.estimated_delivery_time || null,
      courier_type: 'esnaf', // Default esnaf
      
      pickup_location: {
        latitude: payload.restaurant_address.latitude,
        longitude: payload.restaurant_address.longitude,
        address: payload.restaurant_address.full_address
      },
      delivery_location: isQuickCourier ? {
        // HIZLI KURYE MODU: Koordinatlar NULL, sadece text adres
        latitude: null,
        longitude: null,
        address: payload.delivery_address.full_address,
        notes: payload.delivery_address.notes || 'Kurye restorana geldiğinde adres verilecek'
      } : {
        // NORMAL SİPARİŞ: Tam koordinatlar
        latitude: payload.delivery_address.latitude,
        longitude: payload.delivery_address.longitude,
        address: payload.delivery_address.full_address,
        notes: payload.delivery_address.notes || ''
      },
      notes: isQuickCourier 
        ? `⚡ HIZLI KURYE: ${payload.notes || 'Kurye restorana geldiğinde müşteri adresi verilecek'}` 
        : (payload.notes || ''),
      external_order_id: payload.order_id, // ⭐ YO-4521
      source: 'yemek_app', // ⭐ Platform
      created_at: new Date().toISOString()
    }

    const { data: delivery, error: deliveryError } = await supabase
      .from('delivery_requests')
      .insert(deliveryData)
      .select()
      .single()

    if (deliveryError) {
      console.error('[Yemek App] Delivery creation error:', deliveryError)
      throw deliveryError
    }

    console.log('[Yemek App] Delivery created:', delivery.id, isQuickCourier ? '(QUICK MODE)' : '(NORMAL)')

    // 6. Merchant'a FCM Bildirimi Gönder
    try {
      const { data: merchant } = await supabase
        .from('users')
        .select('fcm_token')
        .eq('id', mapping.onlog_merchant_id)
        .single()

      if (merchant?.fcm_token) {
        const notificationTitle = isQuickCourier 
          ? '⚡ Hızlı Kurye Talebi!' 
          : '🍕 Yeni Yemek App Siparişi!'
        
        const notificationMessage = isQuickCourier
          ? `Talep No: ${payload.order_id} - Kurye restorana gelecek`
          : `Sipariş No: ${payload.order_id} - ${payload.declared_amount}₺`

        const { data: notification, error: notifError } = await supabase
          .from('notifications')
          .insert({
            user_id: mapping.onlog_merchant_id,
            fcm_token: merchant.fcm_token,
            type: isQuickCourier ? 'QUICK_COURIER_REQUEST' : 'NEW_ORDER',
            title: notificationTitle,
            message: notificationMessage,
            notification_status: 'pending',
            data: {
              type: isQuickCourier ? 'QUICK_COURIER_REQUEST' : 'NEW_ORDER',
              deliveryId: delivery.id,
              source: 'yemek_app',
              external_order_id: payload.order_id,
              quick_courier_mode: isQuickCourier
            }
          })
          .select('id')
          .single()

        if (!notifError && notification) {
          console.log('[Yemek App] Notification record created, FCM will send automatically')
        }
      }
    } catch (notifError) {
      console.warn('[Yemek App] Notification failed (non-critical):', notifError)
    }

    // 7. Başarılı Yanıt
    return new Response(
      JSON.stringify({
        success: true,
        delivery_id: delivery.id,
        external_order_id: payload.order_id,
        courier_assigned: false, // Kurye ataması async (trigger ile)
        request_type: isQuickCourier ? 'quick_courier' : 'normal_order',
        message: isQuickCourier 
          ? 'Quick courier request received, courier will contact restaurant for delivery address'
          : 'Order received successfully, courier assignment in progress',
        estimated_pickup_time: '10-15 dakika'
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('[Yemek App] Fatal error:', error)
    const message = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({ 
        success: false,
        error_code: 'INTERNAL_ERROR',
        message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
