import 'dart:convert';

/// PayTR Payment Gateway Entegrasyon Servisi
/// Türkiye'de yaygın kullanılan ödeme gateway'i
class PayTRPaymentService {
  final String _merchantId;
  final String _merchantKey;
  final String _merchantSalt;
  final String _baseUrl;

  PayTRPaymentService({
    required String merchantId,
    required String merchantKey,
    required String merchantSalt,
    bool isTest = true,
  }) : _merchantId = merchantId,
       _merchantKey = merchantKey,
       _merchantSalt = merchantSalt,
       _baseUrl = isTest 
           ? 'https://www.paytr.com/odeme/api'
           : 'https://www.paytr.com/odeme/api';

  /// Ödeme isteği oluştur
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    required String currency,
    required String merchantId,
    required Map<String, dynamic> customerInfo,
    required List<Map<String, dynamic>> basketItems,
    String? callbackUrl,
  }) async {
    // PayTR kuruş cinsinden bekliyor
    final amountInKurus = (amount * 100).toInt();
    
    final request = {
      'merchant_id': _merchantId,
      'user_ip': customerInfo['ip'] ?? '127.0.0.1',
      'merchant_oid': orderId,
      'email': customerInfo['email'],
      'payment_amount': amountInKurus.toString(),
      'currency': currency,
      'test_mode': '1', // Test modunda
      'non_3d': '0', // 3D Secure kullan
      'merchant_ok_url': callbackUrl ?? 'https://onlog.app/payment/success',
      'merchant_fail_url': callbackUrl ?? 'https://onlog.app/payment/fail',
      'user_name': '${customerInfo['name']} ${customerInfo['surname']}',
      'user_address': customerInfo['address'] ?? '',
      'user_phone': customerInfo['phone'] ?? '',
      'user_basket': _prepareBasket(basketItems),
      'debug_on': '1',
      'installment_count': '0', // Taksit yok
      'no_installment': '1',
      'max_installment': '0',
      'timeout_limit': '30',
      'lang': 'tr',
    };

    // PayTR token oluştur
    final token = _generatePayTRToken(request);
    request['paytr_token'] = token;

    return {
      'status': 'success',
      'payment_url': '$_baseUrl/odeme',
      'form_data': request,
      'order_id': orderId,
    };
  }

  /// Ödeme sonucunu doğrula
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> postData) async {
    final merchantOid = postData['merchant_oid'];
    final status = postData['status'];
    final totalAmount = postData['total_amount'];
    final hash = postData['hash'];

    // Hash doğrulama
    final expectedHash = _generateVerificationHash(merchantOid, status, totalAmount);
    
    if (hash != expectedHash) {
      return {
        'success': false,
        'error': 'Hash doğrulaması başarısız',
        'order_id': merchantOid,
      };
    }

    final isSuccess = status == 'success';
    
    return {
      'success': isSuccess,
      'status': status,
      'order_id': merchantOid,
      'amount': (int.parse(totalAmount) / 100).toDouble(),
      'transaction_id': postData['payment_id'],
      'error_message': isSuccess ? null : 'Ödeme başarısız',
    };
  }

  /// İade işlemi
  Future<Map<String, dynamic>> refundPayment({
    required String orderId,
    required double refundAmount,
    String? reason,
  }) async {
    final amountInKurus = (refundAmount * 100).toInt();
    
    final request = {
      'merchant_id': _merchantId,
      'merchant_oid': orderId,
      'return_amount': amountInKurus.toString(),
      'reason': reason ?? 'ONLOG sipariş iadesi',
    };

    final token = _generateRefundToken(request);
    request['paytr_token'] = token;

    // PayTR API çağrısı burada yapılacak
    // HTTP client dependency'si olmadığı için mock response döndürüyoruz
    return {
      'success': true,
      'message': 'İade işlemi başlatıldı',
      'order_id': orderId,
      'refund_amount': refundAmount,
    };
  }

  /// Sepet verilerini PayTR formatına çevir
  String _prepareBasket(List<Map<String, dynamic>> basketItems) {
    final basket = basketItems.map((item) {
      return [
        item['name'] ?? 'Ürün',
        (item['price'] ?? 0.0).toString(),
        (item['quantity'] ?? 1).toString(),
      ];
    }).toList();

    return base64.encode(utf8.encode(json.encode(basket)));
  }

  /// PayTR token oluştur
  String _generatePayTRToken(Map<String, dynamic> data) {
    final hashString = '${data['merchant_id']}${data['user_ip']}${data['merchant_oid']}'
                      '${data['email']}${data['payment_amount']}${data['user_basket']}'
                      '${data['non_3d']}${data['installment_count']}${data['currency']}'
                      '${data['test_mode']}$_merchantSalt';
    
    // Gerçek implementasyonda SHA256 hash kullanılacak
    // Şimdilik basit bir hash simülasyonu
    return _simpleHash(hashString);
  }

  /// İade token'ı oluştur
  String _generateRefundToken(Map<String, dynamic> data) {
    final hashString = '${data['merchant_id']}${data['merchant_oid']}'
                      '${data['return_amount']}$_merchantSalt';
    
    return _simpleHash(hashString);
  }

  /// Ödeme doğrulama hash'i oluştur
  String _generateVerificationHash(String merchantOid, String status, String totalAmount) {
    final hashString = '$merchantOid$_merchantSalt$status$totalAmount';
    return _simpleHash(hashString);
  }

  /// Basit hash fonksiyonu (geliştirme için)
  String _simpleHash(String input) {
    return input.hashCode.abs().toRadixString(16);
  }

  /// PayTR konfigürasyon kontrolü
  static bool isConfigured(String merchantId, String merchantKey, String merchantSalt) {
    return merchantId.isNotEmpty && 
           merchantKey.isNotEmpty && 
           merchantSalt.isNotEmpty &&
           merchantId != 'your_paytr_merchant_id' &&
           merchantKey != 'your_paytr_merchant_key' &&
           merchantSalt != 'your_paytr_merchant_salt';
  }

  /// Test kartları
  static const Map<String, Map<String, String>> testCards = {
    'success': {
      'cardNumber': '5406675406675403',
      'expiryMonth': '12',
      'expiryYear': '26',
      'cvc': '000',
    },
    'failure': {
      'cardNumber': '4111111111111129',
      'expiryMonth': '12',
      'expiryYear': '26',
      'cvc': '000',
    },
  };

  /// PayTR desteklenen bankalar
  static const List<String> supportedBanks = [
    'Akbank',
    'Garanti BBVA',
    'İş Bankası',
    'Yapı Kredi',
    'Ziraat Bankası',
    'Halkbank',
    'VakıfBank',
    'Denizbank',
    'TEB',
    'ING Bank',
    'QNB Finansbank',
    'HSBC',
  ];

  /// PayTR taksit seçenekleri
  static const Map<String, List<int>> installmentOptions = {
    'Akbank': [2, 3, 6, 9, 12],
    'Garanti BBVA': [2, 3, 6, 9, 12],
    'İş Bankası': [2, 3, 6, 9, 12],
    'Yapı Kredi': [2, 3, 6, 9, 12],
    'Ziraat Bankası': [2, 3, 6, 9, 12],
    'Halkbank': [2, 3, 6, 9, 12],
    'VakıfBank': [2, 3, 6, 9, 12],
    'Denizbank': [2, 3, 6, 9, 12],
    'TEB': [2, 3, 6, 9, 12],
  };
}

/// PayTR özel exception sınıfı
class PayTRException implements Exception {
  final String message;
  final Map<String, dynamic> details;
  
  PayTRException(this.message, this.details);
  
  @override
  String toString() => 'PayTRException: $message - Details: $details';
}