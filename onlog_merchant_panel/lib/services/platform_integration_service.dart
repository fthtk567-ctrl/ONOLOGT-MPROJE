import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:onlog_shared/onlog_shared.dart';

class PlatformIntegrationService {
  static const String _baseUrl = 'https://api.onlog.com.tr/v1'; // Gerçek API URL'niz
  
  // Desteklenen platformlar
  static const List<Map<String, dynamic>> supportedPlatforms = [
    {
      'id': 'trendyol',
      'name': 'Trendyol',
      'icon': 'shopping_bag',
      'description': 'Türkiye\'nin en büyük e-ticaret platformu',
      'integrationUrl': '/platforms/trendyol/connect',
      'requiresAuth': true,
      'authFields': ['api_key', 'seller_id'],
    },
    {
      'id': 'getir_yemek',
      'name': 'Getir Yemek',
      'icon': 'delivery_dining',
      'description': 'Hızlı yemek teslimat platformu',
      'integrationUrl': '/platforms/getir/connect',
      'requiresAuth': true,
      'authFields': ['restaurant_id', 'api_token'],
    },
    {
      'id': 'yemeksepeti',
      'name': 'Yemeksepeti',
      'icon': 'restaurant',
      'description': 'Önde gelen yemek sipariş platformu',
      'integrationUrl': '/platforms/yemeksepeti/connect',
      'requiresAuth': true,
      'authFields': ['merchant_id', 'api_key'],
    },
    {
      'id': 'bitaksi',
      'name': 'BiTaksi',
      'icon': 'local_taxi',
      'description': 'Kurye ve taksi hizmetleri',
      'integrationUrl': '/platforms/bitaksi/connect',
      'requiresAuth': true,
      'authFields': ['partner_id', 'secret_key'],
    },
    {
      'id': 'hepsiburada',
      'name': 'Hepsiburada',
      'icon': 'store',
      'description': 'E-ticaret marketplace',
      'integrationUrl': '/platforms/hepsiburada/connect',
      'requiresAuth': true,
      'authFields': ['merchant_id', 'username', 'password'],
    },
  ];

  // Mevcut bağlı platformları getir
  static Future<List<Map<String, dynamic>>> getConnectedPlatforms() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/merchant/platforms'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['platforms'] ?? []);
      } else {
        throw Exception('Platform listesi yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Platform listesi hatası: $e');
      // Canlı modda hata durumunda boş liste döndür
      return [];
    }
  }

  // Platform bağlantısı kur
  static Future<bool> connectPlatform(
    String platformId,
    Map<String, String> credentials,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/platforms/$platformId/connect'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'platform_id': platformId,
          'credentials': credentials,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Platform bağlantısı başarısız: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Platform bağlantı hatası: $e');
      return false;
    }
  }

  // Platform bağlantısını kes
  static Future<bool> disconnectPlatform(String platformId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/platforms/$platformId/disconnect'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Platform bağlantısı kesilemedi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Platform bağlantı kesme hatası: $e');
      return false;
    }
  }

  // Platform siparişlerini getir
  static Future<List<Order>> getPlatformOrders(String platformId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/platforms/$platformId/orders'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['orders'] as List)
            .map((orderData) => Order.fromJson(orderData))
            .toList();
      } else {
        throw Exception('Platform siparişleri yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Platform sipariş hatası: $e');
      return [];
    }
  }

  // Platform durumunu kontrol et
  static Future<Map<String, dynamic>> checkPlatformStatus(String platformId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/platforms/$platformId/status'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Platform durumu kontrol edilemedi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Platform durum kontrol hatası: $e');
      return {'status': 'error', 'message': 'Bağlantı hatası'};
    }
  }

  // Auth token'ı getir (SharedPreferences'tan veya secure storage'dan)
  static Future<String> _getAuthToken() async {
    // TODO: Gerçek implementasyonda SharedPreferences veya FlutterSecureStorage kullanın
    return 'your-auth-token-here';
  }

  // Platform detaylarını ID'ye göre getir
  static Map<String, dynamic>? getPlatformDetails(String platformId) {
    return supportedPlatforms.firstWhere(
      (platform) => platform['id'] == platformId,
      orElse: () => {},
    );
  }
}




