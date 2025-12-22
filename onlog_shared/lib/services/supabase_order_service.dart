import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Sipariş Servisi
/// Tüm sipariş operasyonları için merkezi servis
class SupabaseOrderService {
  static final _supabase = Supabase.instance.client;

  // ============================================
  // SİPARİŞ OLUŞTURMA
  // ============================================

  /// Yeni sipariş oluştur
  static Future<Map<String, dynamic>?> createOrder({
    required String restaurantId,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double totalAmount,
    String paymentMethod = 'cash',
    String? courierId,
    Map<String, dynamic>? customerLocation,
  }) async {
    try {
      // ⚠️ ÇOK ÖNEMLİ: Merchant'ın şu anki komisyon bilgisini al
      final merchantCommission = await _getMerchantCommission(restaurantId);
      
      final orderData = {
        'restaurant_id': restaurantId,
        'courier_id': courierId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'customer_location': customerLocation,
        'items': items,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total_amount': totalAmount,
        'status': 'pending',
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        // 🔒 KOMİSYON BİLGİSİNİ SİPARİŞE KAYDET (değişmez!)
        'commission_type': merchantCommission['type'],
        'commission_value': merchantCommission['value'],
        'commission_snapshot_date': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .insert(orderData)
          .select()
          .single();

      print('✅ Sipariş oluşturuldu: ${response['id']}');
      print('💰 Komisyon: ${merchantCommission['type']} = ${merchantCommission['value']}');
      return response;
    } catch (e) {
      print('❌ Sipariş oluşturma hatası: $e');
      return null;
    }
  }

  /// Merchant'ın şu anki komisyon bilgisini al
  /// ⚠️ Bu bilgi sipariş anında kaydedilir ve sonradan değişmez!
  static Future<Map<String, dynamic>> _getMerchantCommission(String merchantId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('commission_settings')
          .eq('id', merchantId)
          .single();

      final settings = response['commission_settings'];
      
      if (settings == null || settings is! Map) {
        print('⚠️ Merchant komisyon ayarı yok, default %15 uygulanıyor');
        return {'type': 'percentage', 'value': 15.0};
      }

      final type = settings['type'] ?? 'percentage';
      
      if (type == 'percentage') {
        final rate = settings['commission_rate'] ?? 15.0;
        return {'type': 'percentage', 'value': rate};
      } else if (type == 'perOrder') {
        final fee = settings['per_order_fee'] ?? 0.0;
        return {'type': 'perOrder', 'value': fee};
      }

      return {'type': 'percentage', 'value': 15.0};
    } catch (e) {
      print('❌ Komisyon bilgisi alınamadı: $e');
      return {'type': 'percentage', 'value': 15.0};
    }
  }

  // ============================================
  // SİPARİŞ SORGULAMA
  // ============================================

  /// Sipariş detayını getir
  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select()
          .eq('id', orderId)
          .single();

      return response;
    } catch (e) {
      print('❌ Sipariş getirme hatası: $e');
      return null;
    }
  }

  /// Merchant'ın siparişlerini getir
  static Future<List<Map<String, dynamic>>> getMerchantOrders({
    required String merchantId,
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select()
          .eq('restaurant_id', merchantId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Merchant siparişleri getirme hatası: $e');
      return [];
    }
  }

  /// Kurye'nin siparişlerini getir
  static Future<List<Map<String, dynamic>>> getCourierOrders({
    required String courierId,
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select()
          .eq('courier_id', courierId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Kurye siparişleri getirme hatası: $e');
      return [];
    }
  }

  /// Bekleyen siparişler (kurye atanmamış)
  static Future<List<Map<String, dynamic>>> getPendingOrders({
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select()
          .eq('status', 'pending')
          .isFilter('courier_id', null)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Bekleyen siparişler getirme hatası: $e');
      return [];
    }
  }

  // ============================================
  // SİPARİŞ GÜNCELLEME
  // ============================================

  /// Sipariş durumunu güncelle
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? courierNote,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (courierNote != null) {
        updateData['courier_note'] = courierNote;
      }

      // Status'e göre özel alanlar
      if (status == 'accepted') {
        updateData['accepted_at'] = DateTime.now().toIso8601String();
      } else if (status == 'picked_up') {
        updateData['picked_up_at'] = DateTime.now().toIso8601String();
      } else if (status == 'delivered') {
        updateData['delivered_at'] = DateTime.now().toIso8601String();
        updateData['payment_status'] = 'completed';
      } else if (status == 'cancelled') {
        updateData['cancelled_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .update(updateData)
          .eq('id', orderId);

      print('✅ Sipariş durumu güncellendi: $status');
      return true;
    } catch (e) {
      print('❌ Sipariş durum güncelleme hatası: $e');
      return false;
    }
  }

  /// Kuryeyi ata
  static Future<bool> assignCourier({
    required String orderId,
    required String courierId,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .update({
            'courier_id': courierId,
            'status': 'assigned',
            'assigned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      print('✅ Kurye atandı');
      return true;
    } catch (e) {
      print('❌ Kurye atama hatası: $e');
      return false;
    }
  }

  /// Ödeme durumunu güncelle
  static Future<bool> updatePaymentStatus({
    required String orderId,
    required String paymentStatus, // 'pending', 'completed', 'failed'
    String? transactionId,
  }) async {
    try {
      final updateData = {
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['payment_transaction_id'] = transactionId;
      }

      await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .update(updateData)
          .eq('id', orderId);

      print('✅ Ödeme durumu güncellendi: $paymentStatus');
      return true;
    } catch (e) {
      print('❌ Ödeme durum güncelleme hatası: $e');
      return false;
    }
  }

  // ============================================
  // REALTIME STREAMS
  // ============================================

  /// Merchant sipariş stream'i
  static Stream<List<Map<String, dynamic>>> streamMerchantOrders({
    required String merchantId,
    String? status,
  }) {
    var query = _supabase
        .from(SupabaseConfig.TABLE_ORDERS)
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', merchantId);

    return query.map((list) {
      if (status != null) {
        return list.where((order) => order['status'] == status).toList();
      }
      return list;
    });
  }

  /// Kurye sipariş stream'i
  static Stream<List<Map<String, dynamic>>> streamCourierOrders({
    required String courierId,
    String? status,
  }) {
    var query = _supabase
        .from(SupabaseConfig.TABLE_ORDERS)
        .stream(primaryKey: ['id'])
        .eq('courier_id', courierId);

    return query.map((list) {
      if (status != null) {
        return list.where((order) => order['status'] == status).toList();
      }
      return list;
    });
  }

  /// Bekleyen siparişler stream'i
  static Stream<List<Map<String, dynamic>>> streamPendingOrders() {
    return _supabase
        .from(SupabaseConfig.TABLE_ORDERS)
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((list) => list.where((order) => order['courier_id'] == null).toList());
  }

  // ============================================
  // İSTATİSTİKLER
  // ============================================

  /// Sipariş istatistikleri
  static Future<Map<String, dynamic>> getOrderStats({
    String? merchantId,
    String? courierId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select();

      if (merchantId != null) {
        query = query.eq('restaurant_id', merchantId);
      }

      if (courierId != null) {
        query = query.eq('courier_id', courierId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final orders = await query;

      double totalRevenue = 0;
      int completedCount = 0;
      int cancelledCount = 0;
      int pendingCount = 0;

      for (var order in orders) {
        if (order['status'] == 'delivered') {
          totalRevenue += (order['total_amount'] ?? 0.0);
          completedCount++;
        } else if (order['status'] == 'cancelled') {
          cancelledCount++;
        } else if (order['status'] == 'pending') {
          pendingCount++;
        }
      }

      return {
        'total_orders': orders.length,
        'completed_orders': completedCount,
        'cancelled_orders': cancelledCount,
        'pending_orders': pendingCount,
        'total_revenue': totalRevenue,
        'average_order_value': completedCount > 0 ? totalRevenue / completedCount : 0.0,
      };
    } catch (e) {
      print('❌ İstatistik hesaplama hatası: $e');
      return {
        'total_orders': 0,
        'completed_orders': 0,
        'cancelled_orders': 0,
        'pending_orders': 0,
        'total_revenue': 0.0,
        'average_order_value': 0.0,
      };
    }
  }
}
