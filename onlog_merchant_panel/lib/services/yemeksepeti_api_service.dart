import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onlog_shared/onlog_shared.dart';

class YemeksepetiApiService {
  // Yemeksepeti API yapılandırması
  static const String _baseUrl = 'https://service.yemeksepeti.com/YS.WebServices';
  static String? _username;
  static String? _password;
  static String? _restaurantId;
  
  // API ayarlarını kaydet
  static void configure({
    required String username,
    required String password,
    required String restaurantId,
  }) {
    _username = username;
    _password = password;
    _restaurantId = restaurantId;
  }

  // Yemeksepeti siparişlerini getir
  static Future<List<Order>> fetchOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_username == null || _password == null || _restaurantId == null) {
      throw Exception('Yemeksepeti API ayarları yapılmamış!');
    }

    try {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      
      final queryParams = <String, String>{
        'restaurantId': _restaurantId!,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$_baseUrl/OrderService.svc/GetOrders')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> orders = data['Orders'] ?? [];
        
        return orders.map((orderData) => _convertYemeksepetiOrder(orderData)).toList();
      } else {
        throw Exception('Yemeksepeti API Hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Yemeksepeti API Error: $e');
      rethrow;
    }
  }

  // Sipariş durumunu güncelle
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    if (_username == null || _password == null) {
      throw Exception('Yemeksepeti API ayarları yapılmamış!');
    }

    try {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      
      final body = {
        'OrderId': orderId,
        'Status': status,
        if (note != null) 'Note': note,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/OrderService.svc/UpdateOrderStatus'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Yemeksepeti Update Error: $e');
      return false;
    }
  }

  // Kurye atama
  static Future<bool> assignCourier({
    required String orderId,
    required String courierName,
    required String courierPhone,
  }) async {
    if (_username == null || _password == null) {
      throw Exception('Yemeksepeti API ayarları yapılmamış!');
    }

    try {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      
      final body = {
        'OrderId': orderId,
        'CourierName': courierName,
        'CourierPhone': courierPhone,
        'Status': 'CourierAssigned',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/OrderService.svc/AssignCourier'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Yemeksepeti Courier Assignment Error: $e');
      return false;
    }
  }

  // Yemeksepeti order'ını OnLog Order'a çevir
  static Order _convertYemeksepetiOrder(Map<String, dynamic> data) {
    final orderId = data['OrderId'].toString();
    final orderItems = data['OrderItems'] as List<dynamic>? ?? [];
    
    // Müşteri bilgileri
    final customerInfo = data['Customer'] ?? {};
    final customerName = '${customerInfo['FirstName'] ?? ''} ${customerInfo['LastName'] ?? ''}'.trim();
    
    // Adres bilgileri
    final deliveryAddress = data['DeliveryAddress'] ?? {};
    final address = Address(
      fullAddress: deliveryAddress['FullAddress'] ?? '',
      district: deliveryAddress['District'] ?? '',
      city: deliveryAddress['City'] ?? '',
      buildingNo: deliveryAddress['BuildingNumber'],
      apartment: deliveryAddress['Apartment'],
      floor: deliveryAddress['Floor'],
      latitude: deliveryAddress['Latitude']?.toDouble(),
      longitude: deliveryAddress['Longitude']?.toDouble(),
    );

    // Müşteri objesi
    final customer = Customer(
      name: customerName.isEmpty ? 'Yemeksepeti Müşterisi' : customerName,
      phone: customerInfo['Phone'] ?? '',
      address: address,
    );

    // Ürün listesi
    final items = orderItems.map<OrderItem>((item) {
      return OrderItem(
        name: item['ProductName'] ?? 'Bilinmeyen Ürün',
        quantity: item['Quantity'] ?? 1,
        price: (item['UnitPrice'] ?? 0.0).toDouble(),
        note: item['Note'],
      );
    }).toList();

    // Toplam tutar
    final totalPrice = (data['TotalAmount'] ?? 0.0).toDouble();
    
    // Sipariş durumu
    final yemeksepetiStatus = data['Status'] ?? 'New';
    final orderStatus = _mapYemeksepetiStatus(yemeksepetiStatus);

    // Sipariş zamanı
    final orderTime = DateTime.tryParse(data['OrderDate'] ?? '') ?? DateTime.now();

    return Order(
      id: orderId,
      platform: OrderPlatform.yemeksepeti,
      customer: customer,
      items: items,
      totalAmount: totalPrice,
      status: orderStatus,
      orderTime: orderTime,
      courierName: data['CourierName'],
      courierPhone: data['CourierPhone'],
      specialNote: 'Yemeksepeti Siparişi - $orderId',
    );
  }

  // Yemeksepeti status'unu OnLog status'una çevir
  static OrderStatus _mapYemeksepetiStatus(String yemeksepetiStatus) {
    switch (yemeksepetiStatus.toLowerCase()) {
      case 'new':
      case 'received':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.assigned;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'courierassigned':
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  // OnLog status'unu Yemeksepeti status'una çevir
  static String mapToYemeksepetiStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'New';
      case OrderStatus.assigned:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'CourierAssigned';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Test bağlantısı
  static Future<bool> testConnection() async {
    if (_username == null || _password == null || _restaurantId == null) {
      return false;
    }

    try {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      
      final response = await http.get(
        Uri.parse('$_baseUrl/RestaurantService.svc/GetRestaurantInfo/$_restaurantId'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Yemeksepeti Connection Test Error: $e');
      return false;
    }
  }
}
