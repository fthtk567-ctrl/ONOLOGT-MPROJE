import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/trendyol_order_model.dart';

/// Trendyol Go Yemek API Servisi
/// Model 1 (STORE) - Kendi kuryemizle teslimat
class TrendyolApiService {
  // Singleton pattern
  static final TrendyolApiService _instance = TrendyolApiService._internal();
  factory TrendyolApiService() => _instance;
  TrendyolApiService._internal();

  // Environment
  static const bool _isProduction = false; // TODO: Production'da true yap
  
  // Base URLs
  static const String _prodBaseUrl = 'https://api.tgoapis.com/integrator';
  static const String _stageBaseUrl = 'https://stageapi.tgoapis.com/integrator';
  
  String get baseUrl => _isProduction ? _prodBaseUrl : _stageBaseUrl;

  // Credentials - TODO: Trendyol Satıcı Paneli'nden al
  // Hesap Bilgilerim > Entegrasyon Bilgileri
  String? _supplierId;
  String? _apiKey;
  String? _apiSecretKey;
  String? _entegratorName;

  /// API bilgilerini ayarla
  void setCredentials({
    required String supplierId,
    required String apiKey,
    required String apiSecretKey,
    String entegratorName = 'SelfIntegration',
  }) {
    _supplierId = supplierId;
    _apiKey = apiKey;
    _apiSecretKey = apiSecretKey;
    _entegratorName = entegratorName;
  }

  /// Basic Authentication header oluştur
  Map<String, String> _getHeaders() {
    if (_apiKey == null || _apiSecretKey == null || _supplierId == null) {
      throw Exception('API credentials not set! Call setCredentials() first.');
    }

    // Basic Auth: base64(apiKey:apiSecretKey)
    final credentials = base64Encode(utf8.encode('$_apiKey:$_apiSecretKey'));
    
    return {
      'Authorization': 'Basic $credentials',
      'User-Agent': '$_supplierId - $_entegratorName',
      'Content-Type': 'application/json',
    };
  }

  /// Sipariş Paketlerini Çek
  /// GET /order/meal/suppliers/{supplierId}/packages
  Future<TrendyolOrderResponse> fetchPackages({
    String? storeId,
    List<String>? packageStatuses, // Created, Picking, Invoiced, Shipped, Delivered, Cancelled, UnSupplied, Returned
    int? packageModificationStartDate, // Epoch milliseconds
    int? packageModificationEndDate,
    int page = 0,
    int size = 50, // Max 50
  }) async {
    debugPrint('🔍 [Trendyol] kIsWeb = $kIsWeb');
    
    // Web platformda MOCK data dön (CORS bypass)
    if (kIsWeb) {
      debugPrint('🌐 [Trendyol] Web platform - returning MOCK packages for demo');
      return _createMockPackagesResponse();
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (storeId != null) queryParams['storeId'] = storeId;
      if (packageStatuses != null && packageStatuses.isNotEmpty) {
        queryParams['packageStatuses'] = packageStatuses.join(',');
      }
      if (packageModificationStartDate != null) {
        queryParams['packageModificationStartDate'] = packageModificationStartDate.toString();
      }
      if (packageModificationEndDate != null) {
        queryParams['packageModificationEndDate'] = packageModificationEndDate.toString();
      }

      final uri = Uri.parse('$baseUrl/order/meal/suppliers/$_supplierId/packages')
          .replace(queryParameters: queryParams);

      debugPrint('📡 [Trendyol] Fetching packages: $uri');

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final result = TrendyolOrderResponse.fromJson(json);
        debugPrint('✅ [Trendyol] Fetched ${result.content.length} packages');
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed! Check API credentials.');
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests! Rate limit exceeded (50 req/10s).');
      } else {
        throw Exception('Failed to fetch packages: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error fetching packages: $e');
      rethrow;
    }
  }

  /// Tek Sipariş Detayını Çek
  /// GET /order/meal/suppliers/{supplierId}/packages/{packageId}
  Future<TrendyolOrderModel> fetchPackageById(String packageId) async {
    try {
      final uri = Uri.parse('$baseUrl/order/meal/suppliers/$_supplierId/packages/$packageId');

      debugPrint('📡 [Trendyol] Fetching package: $packageId');

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final result = TrendyolOrderModel.fromJson(json);
        debugPrint('✅ [Trendyol] Fetched package: ${result.orderNumber}');
        return result;
      } else if (response.statusCode == 404) {
        throw Exception('Package not found: $packageId');
      } else {
        throw Exception('Failed to fetch package: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error fetching package: $e');
      rethrow;
    }
  }

  /// Siparişi Kabul Et (Created → Picking)
  /// PUT /order/meal/suppliers/{supplierId}/packages/{packageId}/picking
  Future<bool> acceptOrder(String packageId) async {
    try {
      final uri = Uri.parse('$baseUrl/order/meal/suppliers/$_supplierId/packages/$packageId/picking');

      debugPrint('📡 [Trendyol] Accepting order: $packageId');

      final response = await http.put(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        debugPrint('✅ [Trendyol] Order accepted: $packageId');
        return true;
      } else {
        debugPrint('❌ [Trendyol] Failed to accept order: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error accepting order: $e');
      return false;
    }
  }

  /// Siparişi Hazır Olarak İşaretle (Picking → Invoiced)
  /// PUT /order/meal/suppliers/{supplierId}/packages/{packageId}/invoiced
  Future<bool> markOrderReady(String packageId) async {
    try {
      final uri = Uri.parse('$baseUrl/order/meal/suppliers/$_supplierId/packages/$packageId/invoiced');

      debugPrint('📡 [Trendyol] Marking order ready: $packageId');

      final response = await http.put(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        debugPrint('✅ [Trendyol] Order marked ready: $packageId');
        return true;
      } else {
        debugPrint('❌ [Trendyol] Failed to mark ready: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error marking ready: $e');
      return false;
    }
  }

  /// Siparişi Yola Çıktı Olarak İşaretle (Invoiced → Shipped)
  /// PUT /order/meal/suppliers/{supplierId}/packages/{packageId}/shipped
  Future<bool> markOrderShipped(String packageId) async {
    try {
      final uri = Uri.parse('$baseUrl/order/meal/suppliers/$_supplierId/packages/$packageId/shipped');

      debugPrint('📡 [Trendyol] Marking order shipped: $packageId');

      final response = await http.put(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        debugPrint('✅ [Trendyol] Order marked shipped: $packageId');
        return true;
      } else {
        debugPrint('❌ [Trendyol] Failed to mark shipped: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error marking shipped: $e');
      return false;
    }
  }

  /// Siparişi Teslim Edildi Olarak İşaretle (Shipped → Delivered)
  /// PUT /order/meal/suppliers/{supplierId}/packages/{packageId}/delivered
  Future<bool> markOrderDelivered(String packageId) async {
    try {
      final uri = Uri.parse('$baseUrl/order/meal/suppliers/$_supplierId/packages/$packageId}/delivered');

      debugPrint('📡 [Trendyol] Marking order delivered: $packageId');

      final response = await http.put(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        debugPrint('✅ [Trendyol] Order marked delivered: $packageId');
        return true;
      } else {
        debugPrint('❌ [Trendyol] Failed to mark delivered: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error marking delivered: $e');
      return false;
    }
  }

  /// Siparişi İptal Et (Created/Picking → UnSupplied)
  /// PUT /order/meal/suppliers/{supplierId}/packages/{packageId}/unsupplied
  /// 
  /// reasonId:
  /// - 621: Tedarik problemi
  /// - 622: Mağaza kapalı
  /// - 623: Mağaza sipariş hazırlayamıyor
  /// - 624: Yüksek yoğunluk / Kurye yok
  /// - 626: Alan Dışı
  /// - 627: Sipariş karışıklığı
  Future<bool> cancelOrder(String packageId, {required int reasonId}) async {
    try {
      final uri = Uri.parse('$baseUrl/order/meal/suppliers/$_supplierId/packages/$packageId/unsupplied');

      final body = jsonEncode({
        'reasonId': reasonId,
      });

      debugPrint('📡 [Trendyol] Cancelling order: $packageId (reason: $reasonId)');

      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Trendyol] Order cancelled: $packageId');
        return true;
      } else {
        debugPrint('❌ [Trendyol] Failed to cancel: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error cancelling order: $e');
      return false;
    }
  }

  /// Yeni Siparişleri Çek (Created durumunda)
  Future<List<TrendyolOrderModel>> fetchNewOrders() async {
    final response = await fetchPackages(
      packageStatuses: ['Created'],
      size: 50,
    );
    return response.content;
  }

  /// Hazırlanıyor Siparişleri Çek (Picking durumunda)
  Future<List<TrendyolOrderModel>> fetchPreparingOrders() async {
    final response = await fetchPackages(
      packageStatuses: ['Picking'],
      size: 50,
    );
    return response.content;
  }

  /// Yolda Siparişleri Çek (Shipped durumunda)
  Future<List<TrendyolOrderModel>> fetchShippedOrders() async {
    final response = await fetchPackages(
      packageStatuses: ['Shipped'],
      size: 50,
    );
    return response.content;
  }

  /// Bugünkü Siparişleri Çek (Tüm durumlar)
  Future<List<TrendyolOrderModel>> fetchTodayOrders() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final response = await fetchPackages(
      packageModificationStartDate: todayStart.millisecondsSinceEpoch,
      packageModificationEndDate: todayEnd.millisecondsSinceEpoch,
      size: 50,
    );
    return response.content;
  }

  /// Test için Mock Credentials
  void setTestCredentials() {
    setCredentials(
      supplierId: '107385', // Örnek ID (dökümantasyondan)
      apiKey: 'test-api-key', // TODO: Gerçek API key gerekli
      apiSecretKey: 'test-api-secret', // TODO: Gerçek secret gerekli
      entegratorName: 'OnlogMerchantPanel',
    );
  }

  /// Test Siparişi Oluştur (STAGE Ortamı)
  /// POST /meal-test-order/orders/meal
  /// 
  /// Bu metod SADECE test ortamında (STAGE) çalışır!
  /// Gerçek bir Trendyol siparişi simüle eder.
  /// 
  /// ⚠️ WEB: CORS nedeniyle direkt API çağrısı yapılamaz, mock response döner
  /// ✅ MOBILE/DESKTOP: Gerçek API çağrısı yapılır
  Future<String?> createTestOrder({
    String customerFirstName = 'Ahmet',
    String customerLastName = 'Yılmaz',
    String productName = 'Hamburger Menü',
    int productId = 161162, // Örnek product ID
    int quantity = 1,
    double latitude = 40.9908, // Kadıköy
    double longitude = 29.0251,
    String city = 'İstanbul',
    String district = 'Kadıköy',
    String neighborhood = 'Fenerbahçe Mah',
    String addressText = 'Cumhuriyet Mahallesi Selimiye Caddesi',
    String phone = '5551234567',
    bool isCashOnDelivery = true,
    String paymentType = 'CASH', // CASH veya CARD
  }) async {
    try {
      // Test için credentials yoksa ayarla
      if (_supplierId == null || _apiKey == null || _apiSecretKey == null) {
        debugPrint('⚠️ [Trendyol] No credentials set, using test credentials...');
        setTestCredentials();
      }

      // Web platformunda CORS nedeniyle mock response döndür
      if (kIsWeb) {
        debugPrint('🌐 [Trendyol] Web platform detected - returning MOCK test order');
        debugPrint('   Customer: $customerFirstName $customerLastName');
        debugPrint('   Product: $productName x$quantity');
        debugPrint('   Location: $district, $city ($latitude, $longitude)');
        debugPrint('   💡 For real API testing, use mobile/desktop or backend proxy');
        
        // Mock order number
        final mockOrderNumber = 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('✅ [Trendyol] Mock test order created!');
        debugPrint('   Order Number: $mockOrderNumber');
        debugPrint('   ⚠️ This is a MOCK order - not sent to real API');
        
        return mockOrderNumber;
      }

      // STAGE ortamında test endpoint'i
      final uri = Uri.parse('https://stageapi.tgoapis.com/integrator/meal-test-order/orders/meal');

      final body = jsonEncode({
        'address': {
          'addressDescription': 'Test adresi',
          'addressText': addressText,
          'apartmentNumber': 5,
          'city': city,
          'company': '',
          'district': district,
          'doorNumber': 3,
          'email': 'test@test.com',
          'floor': 2,
          'latitude': latitude,
          'longitude': longitude,
          'neighborhood': neighborhood,
          'phone': phone.replaceAll(RegExp(r'[^0-9]'), ''), // Sadece rakam
        },
        'isStorePickupSelected': false, // Gel-Al değil, normal teslimat
        'customer': {
          'customerFirstName': customerFirstName,
          'customerLastName': customerLastName,
          'note': 'Test siparişi',
        },
        'lines': [
          {
            'ingredientOptions': {
              'exclude': [],
              'include': [],
            },
            'modifierProducts': [],
            'product': {
              'productId': productId,
              'productName': productName,
            },
            'quantity': quantity,
          }
        ],
        'store': {
          'deliveryType': 'STORE', // Model 1 - Kendi kuryemiz
          'storeId': _supplierId != null ? int.tryParse(_supplierId!) ?? 330 : 330,
          'supplierId': _supplierId != null ? int.tryParse(_supplierId!) ?? 107385 : 107385,
        },
        'coupon': {}, // Boş kupon
        'promotions': [], // Boş promosyon
        'payment': {
          'isPaidWithMealCard': false,
          'mealCardType': '',
          'isCashOnDeliveryPaid': isCashOnDelivery,
          'onDeliveryPaymentType': paymentType, // CASH veya CARD
        }
      });

      debugPrint('📡 [Trendyol] Creating test order...');
      debugPrint('   Customer: $customerFirstName $customerLastName');
      debugPrint('   Product: $productName x$quantity');
      debugPrint('   Location: $district, $city ($latitude, $longitude)');

      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ [Trendyol] Request timeout after 10 seconds');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final orderNumber = json['orderNumber']?.toString();
        
        debugPrint('✅ [Trendyol] Test order created successfully!');
        debugPrint('   Order Number: $orderNumber');
        debugPrint('   💡 Polling service will pick it up in ~30 seconds');
        
        return orderNumber;
      } else {
        debugPrint('❌ [Trendyol] Failed to create test order: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [Trendyol] Error creating test order: $e');
      return null;
    }
  }

  /// Basitleştirilmiş Test Siparişi Oluştur
  Future<String?> createSimpleTestOrder() async {
    return await createTestOrder(
      customerFirstName: 'Test',
      customerLastName: 'Müşteri',
      productName: 'Hamburger Menü',
      quantity: 2,
      district: 'Kadıköy',
      city: 'İstanbul',
    );
  }

  /// MOCK Packages Response (Web için demo)
  TrendyolOrderResponse _createMockPackagesResponse() {
    debugPrint('✅ [Trendyol] Returning MOCK empty response for web demo (use mobile for real API)');
    
    // Web'de boş liste - gerçek API CORS engeli yüzünden çalışmıyor
    // Gerçek test için mobil cihaz kullanın
    return TrendyolOrderResponse(
      content: [],
      page: 0,
      size: 50,
      totalCount: 0,
      totalPages: 0,
    );
  }
}

