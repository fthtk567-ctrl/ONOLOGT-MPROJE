import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// İyzico Payment Gateway Entegrasyon Servisi
/// Türkiye'de en popüler ödeme gateway'i
class IyzicoPaymentService {
  final String _apiKey;
  final String _secretKey;
  final String _baseUrl;
  final bool _isTest;

  IyzicoPaymentService({
    required String apiKey,
    required String secretKey,
    bool isTest = true,
  }) : _apiKey = apiKey,
       _secretKey = secretKey,
       _isTest = isTest,
       _baseUrl = isTest 
           ? 'https://sandbox-api.iyzipay.com'
           : 'https://api.iyzipay.com';

  /// Ödeme isteği oluştur
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    required String currency,
    required String merchantId,
    required Map<String, dynamic> customerInfo,
    required Map<String, dynamic> addressInfo,
    required List<Map<String, dynamic>> basketItems,
  }) async {
    final request = {
      'locale': 'tr',
      'conversationId': orderId,
      'price': amount.toString(),
      'paidPrice': amount.toString(),
      'currency': currency,
      'installment': '1',
      'basketId': orderId,
      'paymentChannel': 'WEB',
      'paymentGroup': 'PRODUCT',
      'callbackUrl': 'https://onlog.app/payment/callback',
      'enabledInstallments': ['2', '3', '6', '9'],
      'buyer': customerInfo,
      'shippingAddress': addressInfo,
      'billingAddress': addressInfo,
      'basketItems': basketItems,
    };

    return await _makeRequest('/payment/iyzipos/checkoutform/initialize/auth/ecom', request);
  }

  /// Marketplace ödeme isteği (alt merchant ile)
  Future<Map<String, dynamic>> createMarketplacePayment({
    required String orderId,
    required double amount,
    required String currency,
    required String subMerchantKey,
    required double subMerchantPrice,
    required Map<String, dynamic> customerInfo,
    required Map<String, dynamic> addressInfo,
    required List<Map<String, dynamic>> basketItems,
  }) async {
    final request = {
      'locale': 'tr',
      'conversationId': orderId,
      'price': amount.toString(),
      'paidPrice': amount.toString(),
      'currency': currency,
      'installment': '1',
      'basketId': orderId,
      'paymentChannel': 'WEB',
      'paymentGroup': 'PRODUCT',
      'callbackUrl': 'https://onlog.app/payment/callback',
      'enabledInstallments': ['2', '3', '6', '9'],
      'buyer': customerInfo,
      'shippingAddress': addressInfo,
      'billingAddress': addressInfo,
      'basketItems': basketItems,
      'paymentInstrument': {
        'subMerchantKey': subMerchantKey,
        'subMerchantPrice': subMerchantPrice.toString(),
      },
    };

    return await _makeRequest('/payment/iyzipos/checkoutform/initialize/auth/ecom', request);
  }

  /// Ödeme durumunu sorgula
  Future<Map<String, dynamic>> retrievePayment(String paymentId) async {
    final request = {
      'locale': 'tr',
      'conversationId': paymentId,
      'paymentId': paymentId,
    };

    return await _makeRequest('/payment/detail', request);
  }

  /// İade işlemi
  Future<Map<String, dynamic>> refundPayment({
    required String paymentTransactionId,
    required double refundAmount,
    required String currency,
    String? description,
  }) async {
    final request = {
      'locale': 'tr',
      'conversationId': paymentTransactionId,
      'paymentTransactionId': paymentTransactionId,
      'price': refundAmount.toString(),
      'currency': currency,
      'description': description ?? 'ONLOG sipariş iadesi',
    };

    return await _makeRequest('/payment/refund', request);
  }

  /// Alt merchant (merchant panel) oluştur
  Future<Map<String, dynamic>> createSubMerchant({
    required String merchantId,
    required String businessName,
    required String email,
    required String phone,
    required String address,
    required String taxNumber,
    required String iban,
  }) async {
    final request = {
      'locale': 'tr',
      'conversationId': merchantId,
      'subMerchantExternalId': merchantId,
      'subMerchantType': 'PERSONAL', // veya 'PRIVATE_COMPANY', 'LIMITED_OR_JOINT_STOCK_COMPANY'
      'address': address,
      'contactName': businessName,
      'email': email,
      'gsmNumber': phone,
      'name': businessName,
      'iban': iban,
      'identityNumber': taxNumber,
      'currency': 'TRY',
    };

    return await _makeRequest('/onboarding/submerchant', request);
  }

  /// Alt merchant para çekme isteği
  Future<Map<String, dynamic>> payoutToSubMerchant({
    required String subMerchantKey,
    required double amount,
    required String currency,
    String? description,
  }) async {
    final request = {
      'locale': 'tr',
      'conversationId': DateTime.now().millisecondsSinceEpoch.toString(),
      'subMerchantKey': subMerchantKey,
      'price': amount.toString(),
      'currency': currency,
      'reason': description ?? 'ONLOG ödeme transferi',
    };

    return await _makeRequest('/reporting/settlement/payoutbonus', request);
  }

  /// Webhook doğrulama
  bool verifyWebhook(String receivedSignature, String payload) {
    final calculatedSignature = _generateSignature(payload);
    return receivedSignature == calculatedSignature;
  }

  /// HTTP istek gönderme (İyzico formatında)
  Future<Map<String, dynamic>> _makeRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      // İyzico için gerekli header'ları ekle
      final requestString = _prepareRequestString(data);
      final authorization = _generateAuthString(requestString);
      
      final headers = {
        'Authorization': authorization,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-iyzi-rnd': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw IyzicoException(
          'İyzico API Hatası: ${response.statusCode}',
          responseData,
        );
      }
    } catch (e) {
      if (e is IyzicoException) rethrow;
      throw IyzicoException('Bağlantı hatası: $e', {});
    }
  }

  /// İyzico için request string hazırla
  String _prepareRequestString(Map<String, dynamic> data) {
    final sortedKeys = data.keys.toList()..sort();
    final pairs = <String>[];
    
    for (final key in sortedKeys) {
      final value = data[key];
      if (value != null) {
        pairs.add('$key=${value.toString()}');
      }
    }
    
    return pairs.join('&');
  }

  /// İyzico auth string oluştur
  String _generateAuthString(String requestString) {
    final randomString = DateTime.now().millisecondsSinceEpoch.toString();
    final hashString = '$_apiKey$requestString$_secretKey$randomString';
    final hash = sha1.convert(utf8.encode(hashString)).toString();
    final authString = base64.encode(utf8.encode('$_apiKey:$hash:$randomString'));
    return 'IYZWSv2 $authString';
  }

  /// Webhook signature oluştur
  String _generateSignature(String payload) {
    final hashString = '$payload$_secretKey';
    return sha1.convert(utf8.encode(hashString)).toString();
  }

  /// İyzico konfigürasyon kontrolü
  static bool isConfigured(String apiKey, String secretKey) {
    return apiKey.isNotEmpty && 
           secretKey.isNotEmpty && 
           apiKey != 'your_iyzico_api_key' &&
           secretKey != 'your_iyzico_secret_key';
  }

  /// Test kartları - geliştirme için
  static const Map<String, Map<String, String>> testCards = {
    'success': {
      'cardNumber': '5528790000000008',
      'expiryMonth': '12',
      'expiryYear': '2030',
      'cvc': '123',
      'holderName': 'Test User',
    },
    'failure': {
      'cardNumber': '4111111111111129',
      'expiryMonth': '12',
      'expiryYear': '2030',
      'cvc': '123',
      'holderName': 'Test User',
    },
  };
}

/// İyzico özel exception sınıfı
class IyzicoException implements Exception {
  final String message;
  final Map<String, dynamic> details;
  
  IyzicoException(this.message, this.details);
  
  @override
  String toString() => 'IyzicoException: $message - Details: $details';
}

/// İyzico için kullanıcı bilgisi formatı
class IyzicoBuyer {
  final String id;
  final String name;
  final String surname;
  final String gsmNumber;
  final String email;
  final String identityNumber;
  final String registrationAddress;
  final String ip;
  final String city;
  final String country;
  final String zipCode;

  IyzicoBuyer({
    required this.id,
    required this.name,
    required this.surname,
    required this.gsmNumber,
    required this.email,
    required this.identityNumber,
    required this.registrationAddress,
    required this.ip,
    required this.city,
    required this.country,
    required this.zipCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'surname': surname,
    'gsmNumber': gsmNumber,
    'email': email,
    'identityNumber': identityNumber,
    'lastLoginDate': DateTime.now().toIso8601String(),
    'registrationDate': DateTime.now().toIso8601String(),
    'registrationAddress': registrationAddress,
    'ip': ip,
    'city': city,
    'country': country,
    'zipCode': zipCode,
  };
}

/// İyzico için adres bilgisi formatı
class IyzicoAddress {
  final String contactName;
  final String city;
  final String country;
  final String address;
  final String zipCode;

  IyzicoAddress({
    required this.contactName,
    required this.city,
    required this.country,
    required this.address,
    required this.zipCode,
  });

  Map<String, dynamic> toJson() => {
    'contactName': contactName,
    'city': city,
    'country': country,
    'address': address,
    'zipCode': zipCode,
  };
}

/// İyzico için sepet öğesi formatı
class IyzicoBasketItem {
  final String id;
  final String name;
  final String category1;
  final String itemType;
  final double price;

  IyzicoBasketItem({
    required this.id,
    required this.name,
    required this.category1,
    required this.itemType,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category1': category1,
    'category2': category1, // İyzico gereksinimi
    'itemType': itemType, // PHYSICAL, VIRTUAL
    'price': price.toString(),
  };
}