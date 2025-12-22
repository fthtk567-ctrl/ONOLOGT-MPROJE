import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_user_service.dart';
import 'supabase_fcm_service.dart';

/// Supabase Teslimat Servisi
/// Kurye teslimat süreçleri için
class SupabaseDeliveryService {
  static final _supabase = Supabase.instance.client;
  static final _fcmService = SupabaseFCMService();

  // ============================================
  // TESLİMAT TALEPLERİ
  // ============================================

  /// Yeni teslimat talebi oluştur
  static Future<String?> createDeliveryRequest({
    required String merchantId,
    required String orderId,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> deliveryLocation,
    required String customerName,
    required String customerPhone,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('delivery_requests')
          .insert({
            'merchant_id': merchantId,
            'order_id': orderId,
            'pickup_location': pickupLocation,
            'delivery_location': deliveryLocation,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'notes': notes,
            'status': 'pending',
          })
          .select()
          .single();

      print('✅ Teslimat talebi oluşturuldu');
      return response['id'];
    } catch (e) {
      print('❌ Teslimat talebi oluşturma hatası: $e');
      return null;
    }
  }

  /// Kuryeye teslimat ata
  static Future<bool> assignCourier({
    required String deliveryRequestId,
    required String courierId,
  }) async {
    try {
      await _supabase
          .from('delivery_requests')
          .update({
            'courier_id': courierId,
            'status': 'assigned',
            'assigned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deliveryRequestId);
      
      // 🔔 KURYE BİLDİRİMİ GÖNDER
      await _sendCourierNotification(courierId, deliveryRequestId);

      print('✅ Kurye atandı');
      return true;
    } catch (e) {
      print('❌ Kurye atama hatası: $e');
      return false;
    }
  }

  /// Teslimat durumunu güncelle
  static Future<bool> updateDeliveryStatus({
    required String deliveryRequestId,
    required String status, // 'picked_up', 'delivering', 'delivered', 'cancelled'
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'picked_up') {
        updateData['picked_up_at'] = DateTime.now().toIso8601String();
      } else if (status == 'delivered') {
        updateData['delivered_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('delivery_requests')
          .update(updateData)
          .eq('id', deliveryRequestId);

      print('✅ Teslimat durumu güncellendi: $status');
      return true;
    } catch (e) {
      print('❌ Durum güncelleme hatası: $e');
      return false;
    }
  }

  // ============================================
  // KONUM TAKİBİ
  // ============================================

  /// Kurye konumunu güncelle
  static Future<bool> updateCourierLocation({
    required String deliveryRequestId,
    required String courierId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Delivery request'te son konum bilgisi
      await _supabase
          .from('delivery_requests')
          .update({
            'current_location': {
              'latitude': latitude,
              'longitude': longitude,
              'updated_at': DateTime.now().toIso8601String(),
            },
          })
          .eq('id', deliveryRequestId);

      // User tablosunda da güncelle
      await SupabaseUserService.updateCourierLocation(
        courierId: courierId,
        latitude: latitude,
        longitude: longitude,
      );

      return true;
    } catch (e) {
      print('❌ Konum güncelleme hatası: $e');
      return false;
    }
  }

  // ============================================
  // SORGULAR
  // ============================================

  /// Bekleyen teslimat talepleri
  static Future<List<Map<String, dynamic>>> getPendingDeliveries() async {
    try {
      final response = await _supabase
          .from('delivery_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Bekleyen teslimatlar getirme hatası: $e');
      return [];
    }
  }

  /// Kurye'nin aktif teslimatları
  static Future<List<Map<String, dynamic>>> getCourierActiveDeliveries({
    required String courierId,
  }) async {
    try {
      final response = await _supabase
          .from('delivery_requests')
          .select()
          .eq('courier_id', courierId)
          .inFilter('status', ['assigned', 'picked_up', 'delivering'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Aktif teslimatlar getirme hatası: $e');
      return [];
    }
  }

  /// Merchant'ın teslimatları
  static Future<List<Map<String, dynamic>>> getMerchantDeliveries({
    required String merchantId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('delivery_requests')
          .select()
          .eq('merchant_id', merchantId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Merchant teslimatları getirme hatası: $e');
      return [];
    }
  }

  // ============================================
  // REALTIME STREAMS
  // ============================================

  /// Teslimat realtime stream
  static Stream<Map<String, dynamic>> streamDelivery(String deliveryId) {
    return _supabase
        .from('delivery_requests')
        .stream(primaryKey: ['id'])
        .eq('id', deliveryId)
        .map((list) => list.isNotEmpty ? list.first : {});
  }

  /// Kurye aktif teslimatları stream
  static Stream<List<Map<String, dynamic>>> streamCourierDeliveries({
    required String courierId,
  }) {
    return _supabase
        .from('delivery_requests')
        .stream(primaryKey: ['id'])
        .map((list) => list.where((d) =>
          d['courier_id'] == courierId &&
          ['assigned', 'picked_up', 'delivering'].contains(d['status'])).toList());
  }

  // ============================================
  // BİLDİRİM SİSTEMİ
  // ============================================

  /// Kuryeye teslimat bildirimi gönder
  static Future<void> _sendCourierNotification(
    String courierId, 
    String deliveryRequestId
  ) async {
    try {
      print('📱 Kuryeye bildirim gönderiliyor: $courierId');
      
      // Teslimat detaylarını al
      final delivery = await _supabase
          .from('delivery_requests')
          .select('*, merchant:merchant_id(business_name, owner_name)')
          .eq('id', deliveryRequestId)
          .single();

      final merchantName = delivery['merchant']?['business_name'] ?? 
                          delivery['merchant']?['owner_name'] ?? 
                          'Merchant';
      final deliveryAddress = delivery['delivery_location']?['address'] ?? 'Adres bilgisi yok';
      final customerName = delivery['customer_name'] ?? 'Müşteri';

      // FCM Service ile bildirim gönder
      final fcmService = SupabaseFCMService();
      final success = await fcmService.sendNotificationToUser(
        userId: courierId,
        title: '🚀 Yeni Teslimat İsteği!',
        body: '$merchantName - $deliveryAddress - $customerName',
        notificationType: 'new_order',
        orderId: delivery['order_id'] ?? deliveryRequestId,
        data: {
          'type': 'new_delivery_request',
          'delivery_request_id': deliveryRequestId,
          'order_id': delivery['order_id'] ?? deliveryRequestId,
          'merchant_name': merchantName,
          'delivery_address': deliveryAddress,
          'customer_name': customerName,
        },
      );

      if (success) {
        print('✅ Kurye bildirimi başarıyla gönderildi: $courierId');
      } else {
        print('⚠️ Kurye bildirimi gönderilemedi (token yok olabilir): $courierId');
      }
    } catch (e) {
      print('❌ Kurye bildirimi hatası: $e');
      // Hata olsa bile teslimat oluşturma devam etsin
    }
  }
}
