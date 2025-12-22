import 'package:flutter/foundation.dart';
import 'package:onlog_shared/onlog_shared.dart';

/// Gerçek API servisi - Şu anda mock data döndürüyor
/// TODO: Backend hazır olunca gerçek API entegrasyonu yapılacak
class RealApiService {
  static const String baseUrl = 'https://api.onlog.com/v1'; // TODO: Gerçek URL
  
  /// Tüm siparişleri getir
  static Future<List<Order>> fetchAllOrders({int limit = 100}) async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.fetchAllOrders - Mock data döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    // Mock data döndür (OrderService'ten)
    return [];
  }

  /// Platform bazlı siparişleri getir
  static Future<List<Order>> fetchOrdersByPlatform(
    OrderPlatform platform, {
    int limit = 50,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.fetchOrdersByPlatform - Mock data döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  /// Platformları getir
  static Future<List<Map<String, dynamic>>> fetchPlatforms() async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.fetchPlatforms - Mock data döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 300));
    
    return [
      {
        'id': 'trendyol',
        'name': 'Trendyol',
        'status': 'active',
        'order_count': 48,
        'connected_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'yemeksepeti',
        'name': 'Yemeksepeti',
        'status': 'active',
        'order_count': 23,
        'connected_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': 'getir',
        'name': 'Getir',
        'status': 'active',
        'order_count': 15,
        'connected_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
    ];
  }

  /// Sipariş oluştur
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.createOrder - Mock response döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 800));
    
    return {
      'success': true,
      'data': {
        'order_id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
      }
    };
  }

  /// Sipariş durumunu güncelle
  static Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.updateOrderStatus - Mock response döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'success': true,
      'data': {
        'order_id': orderId,
        'new_status': newStatus.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      }
    };
  }

  /// Kurye ata
  static Future<Map<String, dynamic>> assignCourier(
    String orderId,
    String courierId,
  ) async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.assignCourier - Mock response döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 600));
    
    return {
      'success': true,
      'data': {
        'order_id': orderId,
        'courier_id': courierId,
        'assigned_at': DateTime.now().toIso8601String(),
      }
    };
  }

  /// Müsait kuryeleri getir
  static Future<List<Map<String, dynamic>>> fetchAvailableCouriers() async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.fetchAvailableCouriers - Mock data döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 400));
    
    return [
      {
        'id': 'courier_1',
        'name': 'Ahmet Yılmaz',
        'phone': '+90 532 111 22 33',
        'status': 'available',
        'rating': 4.8,
        'vehicle': 'Motosiklet',
      },
      {
        'id': 'courier_2',
        'name': 'Mehmet Kaya',
        'phone': '+90 533 222 33 44',
        'status': 'available',
        'rating': 4.6,
        'vehicle': 'Bisiklet',
      },
      {
        'id': 'courier_3',
        'name': 'Ali Demir',
        'phone': '+90 534 333 44 55',
        'status': 'available',
        'rating': 4.9,
        'vehicle': 'Araba',
      },
    ];
  }

  /// İstatistikleri getir
  static Future<Map<String, dynamic>> fetchStatistics({String period = 'current_month'}) async {
    // TODO: Gerçek API çağrısı yapılacak
    debugPrint('⚠️ RealApiService.fetchStatistics - Mock data döndürülüyor');
    await Future.delayed(const Duration(milliseconds: 700));
    
    return {
      'period': period,
      'total_orders': 117,
      'completed_orders': 89,
      'pending_orders': 18,
      'cancelled_orders': 10,
      'total_revenue': 15670.50,
      'average_order_value': 133.92,
      'top_platform': 'Trendyol',
    };
  }
}
