
/// Param Payment Gateway Entegrasyon Servisi
/// Akbank'ın dijital ödeme platformu
class ParamPaymentService {
  final String _clientCode;
  final String _clientUsername;
  final String _clientPassword;
  final String _baseUrl;

  ParamPaymentService({
    required String clientCode,
    required String clientUsername,
    required String clientPassword,
    bool isTest = true,
  }) : _clientCode = clientCode,
       _clientUsername = clientUsername,
       _clientPassword = clientPassword,
       _baseUrl = isTest 
           ? 'https://test-dmz.param.com.tr'
           : 'https://dmz.param.com.tr';

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
    // Param kuruş cinsinden bekliyor
    final amountInKurus = (amount * 100).toInt();
    
    final request = {
      'CLIENT_CODE': _clientCode,
      'CLIENT_USERNAME': _clientUsername,
      'CLIENT_PASSWORD': _clientPassword,
      'MERCHANT_PAYMENTCODE': orderId,
      'PAYMENT_AMOUNT': amountInKurus.toString(),
      'CURRENCY_CODE': currency,
      'CLIENT_LANG': 'tr',
      'MERCHANT_OK_URL': callbackUrl ?? 'https://onlog.app/payment/success',
      'MERCHANT_FAIL_URL': callbackUrl ?? 'https://onlog.app/payment/fail',
      'INSTALLMENT_COUNT': '1',
      'DESCRIPTION': 'ONLOG Sipariş Ödemesi - $orderId',
      'CUSTOM_FIELD_1': merchantId,
      'CUSTOM_FIELD_2': customerInfo['email'] ?? '',
      'CUSTOM_FIELD_3': customerInfo['phone'] ?? '',
      'DCC_CURRENCY': 'TL',
      'SUM_CURRENCY': 'TL',
      'MAX_INSTALLMENT': '12',
    };

    return {
      'status': 'success',
      'payment_url': '$_baseUrl/fim/api',
      'form_data': request,
      'order_id': orderId,
    };
  }

  /// QR kod ödemesi oluştur (Param'ın özel özelliği)
  Future<Map<String, dynamic>> createQRPayment({
    required String orderId,
    required double amount,
    required String merchantId,
    int? expireMinutes,
  }) async {
    final amountInKurus = (amount * 100).toInt();
    final expiry = expireMinutes ?? 30; // Varsayılan 30 dakika
    
    final request = {
      'CLIENT_CODE': _clientCode,
      'CLIENT_USERNAME': _clientUsername,
      'CLIENT_PASSWORD': _clientPassword,
      'MERCHANT_PAYMENTCODE': orderId,
      'PAYMENT_AMOUNT': amountInKurus.toString(),
      'CURRENCY_CODE': 'TRY',
      'QR_TIMEOUT': expiry.toString(),
      'DESCRIPTION': 'ONLOG QR Ödeme - $orderId',
      'CUSTOM_FIELD_1': merchantId,
    };

    // Gerçek implementasyonda Param QR API çağrısı yapılacak
    return {
      'success': true,
      'qr_code': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      'qr_url': 'https://param.com.tr/qr/$orderId',
      'order_id': orderId,
      'expire_time': DateTime.now().add(Duration(minutes: expiry)),
    };
  }

  /// Ödeme durumunu sorgula
  Future<Map<String, dynamic>> queryPayment(String orderId) async {
    final request = {
      'CLIENT_CODE': _clientCode,
      'CLIENT_USERNAME': _clientUsername,
      'CLIENT_PASSWORD': _clientPassword,
      'MERCHANT_PAYMENTCODE': orderId,
    };

    // Mock response - gerçek implementasyonda API çağrısı yapılacak
    return {
      'success': true,
      'status': 'completed',
      'order_id': orderId,
      'payment_status': '1', // 1: Başarılı, 0: Başarısız
      'amount': '10000', // Kuruş cinsinden
      'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  /// İade işlemi
  Future<Map<String, dynamic>> refundPayment({
    required String orderId,
    required String transactionId,
    required double refundAmount,
    String? reason,
  }) async {
    final amountInKurus = (refundAmount * 100).toInt();
    
    final request = {
      'CLIENT_CODE': _clientCode,
      'CLIENT_USERNAME': _clientUsername,
      'CLIENT_PASSWORD': _clientPassword,
      'MERCHANT_PAYMENTCODE': orderId,
      'TRANSACTION_ID': transactionId,
      'REFUND_AMOUNT': amountInKurus.toString(),
      'REFUND_REASON': reason ?? 'ONLOG sipariş iadesi',
    };

    return {
      'success': true,
      'message': 'İade işlemi başlatıldı',
      'order_id': orderId,
      'refund_amount': refundAmount,
      'refund_id': 'REF${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  /// Param ödeme sonucunu doğrula
  Map<String, dynamic> verifyPayment(Map<String, dynamic> postData) {
    final orderId = postData['MERCHANT_PAYMENTCODE'];
    final status = postData['PAYMENT_STATUS'];
    final amount = postData['PAYMENT_AMOUNT'];
    final transactionId = postData['TRANSACTION_ID'];

    final isSuccess = status == '1';
    
    return {
      'success': isSuccess,
      'status': isSuccess ? 'completed' : 'failed',
      'order_id': orderId,
      'amount': int.parse(amount) / 100.0,
      'transaction_id': transactionId,
      'error_message': isSuccess ? null : 'Ödeme başarısız',
    };
  }

  /// Taksit oranlarını sorgula
  Future<Map<String, dynamic>> getInstallmentRates() async {
    final request = {
      'CLIENT_CODE': _clientCode,
      'CLIENT_USERNAME': _clientUsername,
      'CLIENT_PASSWORD': _clientPassword,
      'REQUEST_TYPE': 'INSTALLMENT_INQUIRY',
    };

    // Mock taksit oranları
    return {
      'success': true,
      'installments': {
        '2': {'rate': 1.02, 'commission': 2.0},
        '3': {'rate': 1.03, 'commission': 3.0},
        '6': {'rate': 1.06, 'commission': 6.0},
        '9': {'rate': 1.09, 'commission': 9.0},
        '12': {'rate': 1.12, 'commission': 12.0},
      },
    };
  }

  /// Param konfigürasyon kontrolü
  static bool isConfigured(String clientCode, String clientUsername, String clientPassword) {
    return clientCode.isNotEmpty && 
           clientUsername.isNotEmpty && 
           clientPassword.isNotEmpty &&
           clientCode != 'your_param_client_code' &&
           clientUsername != 'your_param_username' &&
           clientPassword != 'your_param_password';
  }

  /// Test kartları
  static const Map<String, Map<String, String>> testCards = {
    'success': {
      'cardNumber': '5451030000000016',
      'expiryMonth': '12',
      'expiryYear': '26',
      'cvc': '000',
      'holderName': 'Test User',
    },
    'failure': {
      'cardNumber': '4355084355084358',
      'expiryMonth': '12',
      'expiryYear': '26',
      'cvc': '000',
      'holderName': 'Test User',
    },
    'insufficient_funds': {
      'cardNumber': '5451030000000024',
      'expiryMonth': '12',
      'expiryYear': '26',
      'cvc': '000',
      'holderName': 'Test User',
    },
  };

  /// Param desteklenen özellikler
  static const List<String> features = [
    'Kredi kartı ödemeleri',
    'QR kod ödemeleri',
    'Taksitli ödemeler',
    'İade işlemleri',
    'Düzenli ödemeler',
    'Sanal POS entegrasyonu',
    'Mobil ödeme',
    'API entegrasyonu',
    '3D Secure',
    'Fraud protection',
  ];

  /// Param komisyon oranları (örnek)
  static const Map<String, double> commissionRates = {
    'debit_card': 1.5,
    'credit_card': 2.5,
    'installment_2': 2.8,
    'installment_3': 3.1,
    'installment_6': 3.8,
    'installment_9': 4.2,
    'installment_12': 4.8,
    'qr_payment': 1.2,
  };
}

/// Param özel exception sınıfı
class ParamException implements Exception {
  final String message;
  final Map<String, dynamic> details;
  
  ParamException(this.message, this.details);
  
  @override
  String toString() => 'ParamException: $message - Details: $details';
}