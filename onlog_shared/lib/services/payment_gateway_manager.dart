import 'iyzico_payment_service.dart';
import 'paytr_payment_service.dart';
import 'param_payment_service.dart';

/// Unified Payment Gateway Manager
/// Tüm ödeme gateway'lerini tek bir interface üzerinden yönetir
class PaymentGatewayManager {
  final IyzicoPaymentService? _iyzicoService;
  final PayTRPaymentService? _paytrService;
  final ParamPaymentService? _paramService;
  
  // Varsayılan gateway
  PaymentGateway _defaultGateway = PaymentGateway.iyzico;
  
  PaymentGatewayManager({
    IyzicoPaymentService? iyzicoService,
    PayTRPaymentService? paytrService,
    ParamPaymentService? paramService,
    PaymentGateway defaultGateway = PaymentGateway.iyzico,
  }) : _iyzicoService = iyzicoService,
       _paytrService = paytrService,
       _paramService = paramService,
       _defaultGateway = defaultGateway;

  /// Ödeme gateway'ini değiştir
  void setDefaultGateway(PaymentGateway gateway) {
    _defaultGateway = gateway;
  }

  /// Aktif gateway'i al
  PaymentGateway get defaultGateway => _defaultGateway;

  /// Kullanılabilir gateway'leri listele
  List<PaymentGateway> getAvailableGateways() {
    final gateways = <PaymentGateway>[];
    
    if (_iyzicoService != null) gateways.add(PaymentGateway.iyzico);
    if (_paytrService != null) gateways.add(PaymentGateway.paytr);
    if (_paramService != null) gateways.add(PaymentGateway.param);
    
    return gateways;
  }

  /// Ödeme isteği oluştur
  Future<PaymentResult> createPayment({
    required String orderId,
    required double amount,
    required String currency,
    required String merchantId,
    required Map<String, dynamic> customerInfo,
    required List<Map<String, dynamic>> basketItems,
    PaymentGateway? gateway,
    Map<String, dynamic>? options,
  }) async {
    final selectedGateway = gateway ?? _defaultGateway;
    
    try {
      switch (selectedGateway) {
        case PaymentGateway.iyzico:
          if (_iyzicoService == null) {
            throw PaymentException('İyzico servis konfigüre edilmemiş');
          }
          
          final result = await _iyzicoService.createPayment(
            orderId: orderId,
            amount: amount,
            currency: currency,
            merchantId: merchantId,
            customerInfo: customerInfo,
            addressInfo: customerInfo['address'] ?? {},
            basketItems: basketItems,
          );
          
          return PaymentResult(
            success: result['status'] == 'success',
            gateway: selectedGateway,
            paymentUrl: result['checkoutFormContent'],
            orderId: orderId,
            transactionId: result['paymentId'],
            message: result['errorMessage'],
          );

        case PaymentGateway.paytr:
          if (_paytrService == null) {
            throw PaymentException('PayTR servis konfigüre edilmemiş');
          }
          
          final result = await _paytrService.createPayment(
            orderId: orderId,
            amount: amount,
            currency: currency,
            merchantId: merchantId,
            customerInfo: customerInfo,
            basketItems: basketItems,
          );
          
          return PaymentResult(
            success: result['status'] == 'success',
            gateway: selectedGateway,
            paymentUrl: result['payment_url'],
            orderId: orderId,
            formData: result['form_data'],
            message: 'PayTR ödeme formu hazır',
          );

        case PaymentGateway.param:
          if (_paramService == null) {
            throw PaymentException('Param servis konfigüre edilmemiş');
          }
          
          final result = await _paramService.createPayment(
            orderId: orderId,
            amount: amount,
            currency: currency,
            merchantId: merchantId,
            customerInfo: customerInfo,
            basketItems: basketItems,
          );
          
          return PaymentResult(
            success: result['status'] == 'success',
            gateway: selectedGateway,
            paymentUrl: result['payment_url'],
            orderId: orderId,
            formData: result['form_data'],
            message: 'Param ödeme formu hazır',
          );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        gateway: selectedGateway,
        orderId: orderId,
        message: 'Ödeme hatası: $e',
      );
    }
  }

  /// QR kod ödemesi oluştur (sadece Param destekler)
  Future<QRPaymentResult> createQRPayment({
    required String orderId,
    required double amount,
    required String merchantId,
    int? expireMinutes,
  }) async {
    if (_paramService == null) {
      throw PaymentException('QR ödeme için Param servis gerekli');
    }

    try {
      final result = await _paramService.createQRPayment(
        orderId: orderId,
        amount: amount,
        merchantId: merchantId,
        expireMinutes: expireMinutes,
      );

      return QRPaymentResult(
        success: result['success'],
        qrCode: result['qr_code'],
        qrUrl: result['qr_url'],
        orderId: orderId,
        expireTime: result['expire_time'],
      );
    } catch (e) {
      return QRPaymentResult(
        success: false,
        orderId: orderId,
        message: 'QR ödeme hatası: $e',
      );
    }
  }

  /// Ödeme durumunu sorgula
  Future<PaymentVerificationResult> verifyPayment({
    required String orderId,
    PaymentGateway? gateway,
    Map<String, dynamic>? postData,
  }) async {
    final selectedGateway = gateway ?? _defaultGateway;
    
    try {
      switch (selectedGateway) {
        case PaymentGateway.iyzico:
          if (_iyzicoService == null) {
            throw PaymentException('İyzico servis konfigüre edilmemiş');
          }
          
          final result = await _iyzicoService.retrievePayment(orderId);
          
          return PaymentVerificationResult(
            success: result['status'] == 'success',
            gateway: selectedGateway,
            orderId: orderId,
            status: result['paymentStatus'],
            amount: double.tryParse(result['paidPrice']?.toString() ?? '0') ?? 0,
            transactionId: result['paymentId'],
          );

        case PaymentGateway.paytr:
          if (_paytrService == null || postData == null) {
            throw PaymentException('PayTR servis konfigüre edilmemiş veya postData eksik');
          }
          
          final result = await _paytrService.verifyPayment(postData);
          
          return PaymentVerificationResult(
            success: result['success'],
            gateway: selectedGateway,
            orderId: result['order_id'],
            status: result['status'],
            amount: result['amount'],
            transactionId: result['transaction_id'],
            message: result['error_message'],
          );

        case PaymentGateway.param:
          if (_paramService == null) {
            throw PaymentException('Param servis konfigüre edilmemiş');
          }
          
          if (postData != null) {
            // Callback verifikasyonu
            final result = _paramService.verifyPayment(postData);
            
            return PaymentVerificationResult(
              success: result['success'],
              gateway: selectedGateway,
              orderId: result['order_id'],
              status: result['status'],
              amount: result['amount'],
              transactionId: result['transaction_id'],
              message: result['error_message'],
            );
          } else {
            // Durum sorgulama
            final result = await _paramService.queryPayment(orderId);
            
            return PaymentVerificationResult(
              success: result['success'],
              gateway: selectedGateway,
              orderId: orderId,
              status: result['payment_status'] == '1' ? 'completed' : 'failed',
              amount: int.parse(result['amount']) / 100.0,
              transactionId: result['transaction_id'],
            );
          }
      }
    } catch (e) {
      return PaymentVerificationResult(
        success: false,
        gateway: selectedGateway,
        orderId: orderId,
        message: 'Doğrulama hatası: $e',
      );
    }
  }

  /// İade işlemi
  Future<RefundResult> refundPayment({
    required String orderId,
    required double refundAmount,
    required String currency,
    PaymentGateway? gateway,
    String? transactionId,
    String? reason,
  }) async {
    final selectedGateway = gateway ?? _defaultGateway;
    
    try {
      switch (selectedGateway) {
        case PaymentGateway.iyzico:
          if (_iyzicoService == null) {
            throw PaymentException('İyzico servis konfigüre edilmemiş');
          }
          
          final result = await _iyzicoService.refundPayment(
            paymentTransactionId: transactionId ?? orderId,
            refundAmount: refundAmount,
            currency: currency,
            description: reason,
          );
          
          return RefundResult(
            success: result['status'] == 'success',
            gateway: selectedGateway,
            orderId: orderId,
            refundAmount: refundAmount,
            refundId: result['paymentTransactionId'],
            message: result['errorMessage'],
          );

        case PaymentGateway.paytr:
          if (_paytrService == null) {
            throw PaymentException('PayTR servis konfigüre edilmemiş');
          }
          
          final result = await _paytrService.refundPayment(
            orderId: orderId,
            refundAmount: refundAmount,
            reason: reason,
          );
          
          return RefundResult(
            success: result['success'],
            gateway: selectedGateway,
            orderId: orderId,
            refundAmount: refundAmount,
            message: result['message'],
          );

        case PaymentGateway.param:
          if (_paramService == null) {
            throw PaymentException('Param servis konfigüre edilmemiş');
          }
          
          final result = await _paramService.refundPayment(
            orderId: orderId,
            transactionId: transactionId ?? orderId,
            refundAmount: refundAmount,
            reason: reason,
          );
          
          return RefundResult(
            success: result['success'],
            gateway: selectedGateway,
            orderId: orderId,
            refundAmount: refundAmount,
            refundId: result['refund_id'],
            message: result['message'],
          );
      }
    } catch (e) {
      return RefundResult(
        success: false,
        gateway: selectedGateway,
        orderId: orderId,
        refundAmount: refundAmount,
        message: 'İade hatası: $e',
      );
    }
  }

  /// Gateway durumunu kontrol et
  Map<PaymentGateway, bool> getGatewayStatus() {
    return {
      PaymentGateway.iyzico: _iyzicoService != null,
      PaymentGateway.paytr: _paytrService != null,
      PaymentGateway.param: _paramService != null,
    };
  }

  /// Gateway komisyon oranlarını al
  Map<PaymentGateway, Map<String, double>> getCommissionRates() {
    return {
      PaymentGateway.iyzico: {
        'debit_card': 2.9,
        'credit_card': 2.9,
        'installment_2': 3.2,
        'installment_3': 3.5,
        'installment_6': 4.2,
        'installment_9': 4.8,
        'installment_12': 5.5,
      },
      PaymentGateway.paytr: {
        'debit_card': 2.8,
        'credit_card': 2.8,
        'installment_2': 3.1,
        'installment_3': 3.4,
        'installment_6': 4.0,
        'installment_9': 4.5,
        'installment_12': 5.2,
      },
      PaymentGateway.param: ParamPaymentService.commissionRates,
    };
  }
}

/// Payment gateway enum'u
enum PaymentGateway {
  iyzico,
  paytr,
  param,
}

/// Ödeme sonuç sınıfları
class PaymentResult {
  final bool success;
  final PaymentGateway gateway;
  final String? paymentUrl;
  final String orderId;
  final String? transactionId;
  final Map<String, dynamic>? formData;
  final String? message;

  PaymentResult({
    required this.success,
    required this.gateway,
    this.paymentUrl,
    required this.orderId,
    this.transactionId,
    this.formData,
    this.message,
  });
}

class QRPaymentResult {
  final bool success;
  final String? qrCode;
  final String? qrUrl;
  final String orderId;
  final DateTime? expireTime;
  final String? message;

  QRPaymentResult({
    required this.success,
    this.qrCode,
    this.qrUrl,
    required this.orderId,
    this.expireTime,
    this.message,
  });
}

class PaymentVerificationResult {
  final bool success;
  final PaymentGateway gateway;
  final String orderId;
  final String? status;
  final double? amount;
  final String? transactionId;
  final String? message;

  PaymentVerificationResult({
    required this.success,
    required this.gateway,
    required this.orderId,
    this.status,
    this.amount,
    this.transactionId,
    this.message,
  });
}

class RefundResult {
  final bool success;
  final PaymentGateway gateway;
  final String orderId;
  final double refundAmount;
  final String? refundId;
  final String? message;

  RefundResult({
    required this.success,
    required this.gateway,
    required this.orderId,
    required this.refundAmount,
    this.refundId,
    this.message,
  });
}

/// Payment exception
class PaymentException implements Exception {
  final String message;
  
  PaymentException(this.message);
  
  @override
  String toString() => 'PaymentException: $message';
}