import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onlog_shared/onlog_shared.dart';

class GetirApiService {
  // Getir API yapılandırması
  static const String _baseUrl = 'https://restaurant-api.getir.com';
  static String? _apiKey;
  static String? _restaurantId;
  
  // API ayarlarını kaydet
  static void configure({
    required String apiKey,
    required String restaurantId,
  }) {
    _apiKey = apiKey;
    _restaurantId = restaurantId;
  }

  // Getir siparişlerini getir
  static Future<List<Order>> fetchOrders({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    if (_apiKey == null || _restaurantId == null) {
      throw Exception('Getir API ayarları yapılmamış!');
    }

    try {
      final queryParams = <String, String>{
        'restaurantId': _restaurantId!,
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$_baseUrl/v1/orders')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> orders = data['data'] ?? [];
        
        return orders.map((orderData) => _convertGetirOrder(orderData)).toList();
      } else {
        throw Exception('Getir API Hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Getir API Error: $e');
      rethrow;
    }
  }

  // Sipariş durumunu güncelle
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    if (_apiKey == null) {
      throw Exception('Getir API ayarları yapılmamış!');
    }

    try {
      final body = {
        'status': status,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/v1/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Getir Update Error: $e');
      return false;
    }
  }

  // Kurye bilgilerini güncelle
  static Future<bool> assignCourier({
    required String orderId,
    required String courierName,
    required String courierPhone,
    required String courierVehicle,
  }) async {
    if (_apiKey == null) {
      throw Exception('Getir API ayarları yapılmamış!');
    }

    try {
      final body = {
        'courier': {
          'name': courierName,
          'phone': courierPhone,
          'vehicle': courierVehicle,
        },
        'status': 'courier_assigned',
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/v1/orders/$orderId/courier'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Getir Courier Assignment Error: $e');
      return false;
    }
  }

  // Canlı konum güncelleme
  static Future<bool> updateCourierLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey == null) {
      throw Exception('Getir API ayarları yapılmamış!');
    }

    try {
      final body = {
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/orders/$orderId/location'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Getir Location Update Error: $e');
      return false;
    }
  }

  // Getir order'ını OnLog Order'a çevir
  static Order _convertGetirOrder(Map<String, dynamic> data) {
    final orderId = data['id'].toString();
    final orderItems = data['items'] as List<dynamic>? ?? [];
    
    // Müşteri bilgileri
    final customerInfo = data['customer'] ?? {};
    final customerName = customerInfo['name'] ?? 'Getir Müşterisi';
    
    // Adres bilgileri
    final deliveryAddress = data['delivery_address'] ?? {};
    final address = Address(
      fullAddress: deliveryAddress['full_address'] ?? '',
      district: deliveryAddress['district'] ?? '',
      city: deliveryAddress['city'] ?? '',
      buildingNo: deliveryAddress['building_number'],
      apartment: deliveryAddress['apartment'],
      floor: deliveryAddress['floor'],
      latitude: deliveryAddress['latitude']?.toDouble(),
      longitude: deliveryAddress['longitude']?.toDouble(),
    );

    // Müşteri objesi
    final customer = Customer(
      name: customerName,
      phone: customerInfo['phone'] ?? '',
      address: address,
    );

    // Ürün listesi
    final items = orderItems.map<OrderItem>((item) {
      return OrderItem(
        name: item['name'] ?? 'Bilinmeyen Ürün',
        quantity: item['quantity'] ?? 1,
        price: (item['price'] ?? 0.0).toDouble(),
        note: item['note'],
      );
    }).toList();

    // Toplam tutar
    final totalPrice = (data['total_amount'] ?? 0.0).toDouble();
    
    // Sipariş durumu
    final getirStatus = data['status'] ?? 'created';
    final orderStatus = _mapGetirStatus(getirStatus);

    // Sipariş zamanı
    final orderTime = DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now();

    // Kurye bilgileri
    final courierInfo = data['courier'] ?? {};

    return Order(
      id: orderId,
      platform: OrderPlatform.getir,
      customer: customer,
      items: items,
      totalAmount: totalPrice,
      status: orderStatus,
      orderTime: orderTime,
      courierName: courierInfo['name'],
      courierPhone: courierInfo['phone'],
      specialNote: 'Getir Siparişi - $orderId',
    );
  }

  // Getir status'unu OnLog status'una çevir
  static OrderStatus _mapGetirStatus(String getirStatus) {
    switch (getirStatus.toLowerCase()) {
      case 'created':
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
      case 'accepted':
        return OrderStatus.assigned;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'courier_assigned':
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  // OnLog status'unu Getir status'una çevir
  static String mapToGetirStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'created';
      case OrderStatus.assigned:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.pickedUp:
        return 'courier_assigned';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  // Test bağlantısı
  static Future<bool> testConnection() async {
    if (_apiKey == null || _restaurantId == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/restaurant/$_restaurantId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Getir Connection Test Error: $e');
      return false;
    }
  }
}
