import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Trendyol Entegrasyon Servisi
/// Trendyol API + Supabase Integration
class SupabaseTrendyolService {
  static final _supabase = Supabase.instance.client;

  // ============================================
  // TRENDYOL CREDENTİALS YÖNETİMİ
  // ============================================

  /// Merchant'ın Trendyol bilgilerini kaydet
  static Future<bool> saveCredentials({
    required String userId,
    required String supplierId,
    required String apiKey,
    required String apiSecretKey,
    bool isProduction = false,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.TABLE_TRENDYOL_CREDENTIALS).upsert({
        'user_id': userId,
        'supplier_id': supplierId,
        'api_key': apiKey,
        'api_secret_key': apiSecretKey,
        'is_production': isProduction,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Trendyol credentials kaydedildi');
      return true;
    } catch (e) {
      print('❌ Trendyol credentials kaydetme hatası: $e');
      return false;
    }
  }

  /// Merchant'ın Trendyol bilgilerini getir
  static Future<Map<String, dynamic>?> getCredentials(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_TRENDYOL_CREDENTIALS)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .single();
      
      return response;
    } catch (e) {
      print('⚠️ Trendyol credentials bulunamadı');
      return null;
    }
  }

  // ============================================
  // PLATFORM SİPARİŞLERİ
  // ============================================

  /// Trendyol siparişini kaydet
  static Future<String?> savePlatformOrder({
    required String platform,
    required String platformOrderId,
    required String merchantId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_PLATFORM_ORDERS)
          .insert({
            'platform': platform,
            'platform_order_id': platformOrderId,
            'merchant_id': merchantId,
            'order_number': orderData['order_number'],
            'customer_name': orderData['customer_name'],
            'customer_phone': orderData['customer_phone'],
            'delivery_address': orderData['delivery_address'],
            'items': orderData['items'],
            'total_amount': orderData['total_amount'],
            'platform_commission': orderData['platform_commission'],
            'net_amount': orderData['net_amount'],
            'status': orderData['status'] ?? 'pending',
            'order_date': orderData['order_date'],
          })
          .select()
          .single();
      
      print('✅ Platform siparişi kaydedildi: $platformOrderId');
      return response['id'];
    } catch (e) {
      print('❌ Platform sipariş kaydetme hatası: $e');
      return null;
    }
  }

  /// Platform siparişini ONLOG siparişine dönüştür
  static Future<bool> syncToOnlogOrder(String platformOrderId, String onlogOrderId) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_PLATFORM_ORDERS)
          .update({
            'synced_to_onlog': true,
            'onlog_order_id': onlogOrderId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', platformOrderId);
      
      print('✅ Platform siparişi ONLOG\'a senkronize edildi');
      return true;
    } catch (e) {
      print('❌ Senkronizasyon hatası: $e');
      return false;
    }
  }

  /// Merchant'ın platform siparişlerini getir
  static Future<List<Map<String, dynamic>>> getMerchantPlatformOrders({
    required String merchantId,
    String? platform,
    int limit = 50,
  }) async {
    try {
      if (platform != null) {
        final response = await _supabase
            .from(SupabaseConfig.TABLE_PLATFORM_ORDERS)
            .select()
            .eq('merchant_id', merchantId)
            .eq('platform', platform)
            .order('order_date', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final response = await _supabase
            .from(SupabaseConfig.TABLE_PLATFORM_ORDERS)
            .select()
            .eq('merchant_id', merchantId)
            .order('order_date', ascending: false)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('❌ Platform siparişleri getirme hatası: $e');
      return [];
    }
  }

  /// Son senkronizasyon zamanını güncelle
  static Future<void> updateLastSync(String userId) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_TRENDYOL_CREDENTIALS)
          .update({'last_sync': DateTime.now().toIso8601String()})
          .eq('user_id', userId);
    } catch (e) {
      print('❌ Last sync güncelleme hatası: $e');
    }
  }

  // ============================================
  // İSTATİSTİKLER
  // ============================================

  /// Platform bazlı sipariş istatistikleri
  static Future<Map<String, dynamic>> getPlatformStats(String merchantId) async {
    try {
      final orders = await getMerchantPlatformOrders(merchantId: merchantId);
      
      final stats = <String, Map<String, dynamic>>{};
      
      for (var order in orders) {
        final platform = order['platform'] as String;
        if (!stats.containsKey(platform)) {
          stats[platform] = {
            'count': 0,
            'total_amount': 0.0,
            'commission': 0.0,
          };
        }
        
        stats[platform]!['count'] = (stats[platform]!['count'] as int) + 1;
        stats[platform]!['total_amount'] = (stats[platform]!['total_amount'] as double) + 
            (order['total_amount'] ?? 0.0);
        stats[platform]!['commission'] = (stats[platform]!['commission'] as double) + 
            (order['platform_commission'] ?? 0.0);
      }
      
      return {
        'platforms': stats,
        'total_orders': orders.length,
        'total_revenue': orders.fold(0.0, (sum, o) => sum + (o['total_amount'] ?? 0.0)),
      };
    } catch (e) {
      print('❌ Platform istatistik hatası: $e');
      return {};
    }
  }
}
