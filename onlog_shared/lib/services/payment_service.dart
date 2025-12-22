import '../models/payment_models.dart';
import 'payment_gateway_manager.dart';
import 'supabase_service.dart';

/// Payment Processing Exception
class PaymentProcessingException implements Exception {
  final String message;
  final PaymentTransaction? transaction;

  PaymentProcessingException(this.message, [this.transaction]);

  @override
  String toString() => 'PaymentProcessingException: $message';
}

class PaymentService {
  static const String _transactionsTable = 'payment_transactions';
  static const String _walletsTable = 'merchant_wallets';
  static const String _commissionsTable = 'commission_configs';

  // ignore: unused_field
  final PaymentGatewayManager? _gatewayManager;
  final _supabase = SupabaseService.client;

  PaymentService({PaymentGatewayManager? gatewayManager})
    : _gatewayManager = gatewayManager;

  // ==================== PAYMENT TRANSACTIONS ====================

  /// Yeni ödeme işlemi oluştur
  Future<String> createPaymentTransaction(
    PaymentTransaction transaction,
  ) async {
    final data = transaction.toMap();
    data.remove('id'); // id'yi kaldır, Supabase otomatik oluşturacak

    final response = await _supabase
        .from(_transactionsTable)
        .insert(data)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Ödeme durumunu güncelle
  Future<void> updatePaymentStatus(
    String transactionId,
    PaymentStatus status, {
    String? gatewayReference,
    Map<String, dynamic>? gatewayResponse,
  }) async {
    final Map<String, dynamic> updates = {
      'status': status.toString().split('.').last,
      'processed_at': DateTime.now().toIso8601String(),
    };

    if (gatewayReference != null) {
      updates['gateway_reference'] = gatewayReference;
    }

    if (gatewayResponse != null) {
      updates['gateway_response'] = gatewayResponse;
    }

    if (status == PaymentStatus.completed) {
      updates['settled_at'] = DateTime.now().toIso8601String();
    }

    await _supabase
        .from(_transactionsTable)
        .update(updates)
        .eq('id', transactionId);
  }

  /// Merchant'ın ödemelerini getir
  Stream<List<PaymentTransaction>> getMerchantTransactions(
    String merchantId, {
    DateTime? startDate,
    DateTime? endDate,
    PaymentStatus? status,
    TransactionType? type,
  }) {
    var query = _supabase
        .from(_transactionsTable)
        .stream(primaryKey: ['id'])
        .eq('merchant_id', merchantId)
        .order('created_at', ascending: false);

    // Not: Supabase stream filtering yapısı farklıdır
    // Filtreler stream() sonrası .where() ile uygulanır
    return query.map((data) {
      var transactions = data
          .map(
            (item) => PaymentTransaction.fromMap({'id': item['id'], ...item}),
          )
          .toList();

      // Client-side filtering (gerekirse)
      if (startDate != null) {
        transactions = transactions
            .where(
              (t) =>
                  t.createdAt.isAfter(startDate) ||
                  t.createdAt.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        transactions = transactions
            .where(
              (t) =>
                  t.createdAt.isBefore(endDate) ||
                  t.createdAt.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      if (status != null) {
        transactions = transactions.where((t) => t.status == status).toList();
      }

      if (type != null) {
        transactions = transactions.where((t) => t.type == type).toList();
      }

      return transactions;
    });
  }

  /// Sipariş ödemesi işle - Otomatik komisyon hesaplama ve tahsilat
  Future<PaymentTransaction> processOrderPaymentWithAutoCollection({
    required String orderId,
    required String merchantId,
    required String? courierId,
    required String? customerId,
    required double orderAmount,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Merchant'ın komisyon konfigürasyonunu al
      final commissionConfig = await getCommissionConfig(merchantId);

      // Komisyon ve vergi hesapla
      final commissionAmount = _calculateCommission(
        orderAmount,
        commissionConfig,
      );
      final vatAmount = _calculateVAT(commissionAmount);

      // Merchant'a net kazanç
      final merchantEarning = orderAmount - commissionAmount - vatAmount;

      // Payment transaction oluştur
      final transaction = PaymentTransaction(
        id: '',
        orderId: orderId,
        merchantId: merchantId,
        courierId: courierId,
        customerId: customerId,
        amount: merchantEarning, // Merchant'ın alacağı miktar
        originalAmount: orderAmount,
        commissionAmount: commissionAmount,
        vatAmount: vatAmount,
        currency: 'TRY',
        paymentMethod: paymentMethod,
        status: PaymentStatus.completed,
        type: TransactionType.orderPayment,
        createdAt: DateTime.now(),
        processedAt: DateTime.now(),
        settledAt: DateTime.now(),
        gatewayReference: 'AUTO_${DateTime.now().millisecondsSinceEpoch}',
        gatewayProvider: 'ONLOG_AUTO',
        gatewayResponse: {},
        description: 'Sipariş #$orderId otomatik ödeme',
        metadata: {
          'auto_processed': true,
          'commission_rate': commissionConfig.defaultRate,
          'vat_rate': 0.18,
          ...?additionalData,
        },
      );

      // Transaction'ı kaydet
      final transactionId = await createPaymentTransaction(transaction);
      final savedTransaction = transaction.copyWith(id: transactionId);

      // Merchant wallet'ını güncelle
      await _updateMerchantWalletAfterPayment(
        merchantId: merchantId,
        amount: merchantEarning,
        commissionAmount: commissionAmount,
        transaction: savedTransaction,
      );

      // Kurye varsa kurye ödemesini hesapla
      if (courierId != null) {
        await _processCourierPayment(
          courierId: courierId,
          orderId: orderId,
          deliveryFee: _extractDeliveryFee(additionalData),
        );
      }

      return savedTransaction;
    } catch (e) {
      // Hata durumunda failed transaction oluştur
      final failedTransaction = PaymentTransaction(
        id: '',
        orderId: orderId,
        merchantId: merchantId,
        courierId: courierId,
        customerId: customerId,
        amount: 0,
        originalAmount: orderAmount,
        commissionAmount: 0,
        vatAmount: 0,
        currency: 'TRY',
        paymentMethod: paymentMethod,
        status: PaymentStatus.failed,
        type: TransactionType.orderPayment,
        createdAt: DateTime.now(),
        gatewayResponse: {'error': e.toString()},
        description: 'Ödeme işlemi hatası: $e',
        metadata: {'auto_processed': true, 'error': e.toString()},
      );

      final transactionId = await createPaymentTransaction(failedTransaction);
      throw PaymentProcessingException(
        'Sipariş ödemesi işlenemedi: $e',
        failedTransaction.copyWith(id: transactionId),
      );
    }
  }

  /// Komisyon hesapla
  double _calculateCommission(double amount, CommissionConfig config) {
    return amount * (config.defaultRate / 100);
  }

  /// KDV hesapla
  double _calculateVAT(double amount) {
    return amount * 0.18; // %18 KDV
  }

  /// Teslimat ücretini metadata'dan çıkar
  double _extractDeliveryFee(Map<String, dynamic>? metadata) {
    return (metadata?['delivery_fee'] as num?)?.toDouble() ?? 0.0;
  }

  /// Merchant wallet'ını ödeme sonrası güncelle
  Future<void> _updateMerchantWalletAfterPayment({
    required String merchantId,
    required double amount,
    required double commissionAmount,
    required PaymentTransaction transaction,
  }) async {
    // Supabase RPC fonksiyonu ile transaction-safe güncelleme
    await _supabase.rpc(
      'update_merchant_wallet_after_payment',
      params: {
        'p_merchant_id': merchantId,
        'p_amount': amount,
        'p_commission_amount': commissionAmount,
        'p_transaction_id': transaction.id,
      },
    );
  }

  /// Kurye ödemesini işle
  Future<void> _processCourierPayment({
    required String courierId,
    required String orderId,
    required double deliveryFee,
  }) async {
    if (deliveryFee <= 0) return;

    // Kurye için ayrı bir transaction oluştur
    final courierTransaction = PaymentTransaction(
      id: '',
      orderId: orderId,
      merchantId: null,
      courierId: courierId,
      customerId: null,
      amount: deliveryFee,
      originalAmount: deliveryFee,
      commissionAmount: 0,
      vatAmount: 0,
      currency: 'TRY',
      paymentMethod: PaymentMethod.wallet,
      status: PaymentStatus.completed,
      type: TransactionType.deliveryFee,
      createdAt: DateTime.now(),
      processedAt: DateTime.now(),
      settledAt: DateTime.now(),
      gatewayReference: 'DELIVERY_${DateTime.now().millisecondsSinceEpoch}',
      gatewayProvider: 'ONLOG_AUTO',
      gatewayResponse: {},
      description: 'Teslimat ücreti - Sipariş #$orderId',
      metadata: {'auto_processed': true, 'courier_payment': true},
    );

    await createPaymentTransaction(courierTransaction);

    // Kurye wallet'ını güncelle (benzer mantık)
    // Bu kısım kurye wallet modeli oluşturulduktan sonra implement edilecek
  }

  /// Sipariş ödemesi işle - Mevcut method
  Future<PaymentTransaction> processOrderPayment({
    required String orderId,
    required String merchantId,
    required String customerId,
    required double orderAmount,
    required PaymentMethod paymentMethod,
    String? gatewayProvider,
    Map<String, dynamic>? gatewayData,
  }) async {
    // Komisyon hesapla
    final commissionConfig = await getCommissionConfig(merchantId);
    final commissionAmount = commissionConfig.calculateCommission(orderAmount);
    final vatAmount = commissionAmount * 0.18; // KDV %18
    final merchantAmount = orderAmount - commissionAmount;

    final transaction = PaymentTransaction(
      id: '',
      orderId: orderId,
      merchantId: merchantId,
      customerId: customerId,
      amount: merchantAmount,
      originalAmount: orderAmount,
      commissionAmount: commissionAmount,
      vatAmount: vatAmount,
      currency: 'TRY',
      paymentMethod: paymentMethod,
      status: PaymentStatus.pending,
      type: TransactionType.orderPayment,
      createdAt: DateTime.now(),
      gatewayProvider: gatewayProvider,
      gatewayResponse: gatewayData ?? {},
      metadata: {
        'commissionConfigId': commissionConfig.id,
        'commissionRate': commissionConfig.commissionRate,
      },
    );

    final transactionId = await createPaymentTransaction(transaction);

    // Wallet güncelle (pending balance)
    await updateMerchantWallet(merchantId, pendingAmount: merchantAmount);

    return transaction.copyWith(id: transactionId);
  }

  // ==================== MERCHANT WALLETS ====================

  /// Merchant wallet'ı getir
  Future<MerchantWallet?> getMerchantWallet(String merchantId) async {
    final response = await _supabase
        .from(_walletsTable)
        .select()
        .eq('merchant_id', merchantId)
        .maybeSingle();

    if (response == null) return null;

    return MerchantWallet.fromMap({
      'merchantId': response['merchant_id'],
      ...response,
    });
  }

  /// Merchant wallet'ı oluştur veya güncelle
  Future<void> updateMerchantWallet(
    String merchantId, {
    double? balanceChange,
    double? pendingAmount,
    double? frozenAmount,
    double? commissionAmount,
  }) async {
    // Supabase RPC fonksiyonu ile transaction-safe güncelleme
    await _supabase.rpc(
      'update_merchant_wallet',
      params: {
        'p_merchant_id': merchantId,
        'p_balance_change': balanceChange ?? 0,
        'p_pending_amount': pendingAmount ?? 0,
        'p_frozen_amount': frozenAmount ?? 0,
        'p_commission_amount': commissionAmount ?? 0,
      },
    );
  }

  /// Pending balance'ı confirmed balance'a çevir
  Future<void> confirmPendingBalance(String merchantId, double amount) async {
    await updateMerchantWallet(
      merchantId,
      balanceChange: amount,
      pendingAmount: -amount,
    );
  }

  /// Para çekme işlemi
  Future<PaymentTransaction> withdrawMoney({
    required String merchantId,
    required double amount,
    required String bankAccount,
    String? description,
  }) async {
    final wallet = await getMerchantWallet(merchantId);
    if (wallet == null || wallet.availableBalance < amount) {
      throw Exception('Yetersiz bakiye');
    }

    // Günlük/aylık limit kontrolü
    final dailyLimit = wallet.limits['dailyWithdrawalLimit'] ?? 10000.0;
    if (amount > dailyLimit) {
      throw Exception('Günlük çekim limitini aştınız');
    }

    final transaction = PaymentTransaction(
      id: '',
      orderId: 'WITHDRAWAL_${DateTime.now().millisecondsSinceEpoch}',
      merchantId: merchantId,
      amount: -amount, // Negatif miktar
      originalAmount: amount,
      commissionAmount: 0,
      vatAmount: 0,
      currency: 'TRY',
      paymentMethod: PaymentMethod.bankTransfer,
      status: PaymentStatus.pending,
      type: TransactionType.withdrawal,
      createdAt: DateTime.now(),
      gatewayResponse: {},
      description: description ?? 'Para çekme',
      metadata: {
        'bankAccount': bankAccount,
        'withdrawalMethod': 'bank_transfer',
      },
    );

    final transactionId = await createPaymentTransaction(transaction);

    // Balance'dan düş
    await updateMerchantWallet(merchantId, balanceChange: -amount);

    return transaction.copyWith(id: transactionId);
  }

  // ==================== COMMISSION MANAGEMENT ====================

  /// Merchant için komisyon konfigürasyonu getir
  Future<CommissionConfig> getCommissionConfig(String merchantId) async {
    // Önce merchant'a özel konfigürasyon ara
    final merchantConfig = await _supabase
        .from(_commissionsTable)
        .select()
        .eq('merchant_id', merchantId)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (merchantConfig != null) {
      return CommissionConfig.fromMap({
        'id': merchantConfig['id'],
        ...merchantConfig,
      });
    }

    // Genel konfigürasyon getir
    final generalConfig = await _supabase
        .from(_commissionsTable)
        .select()
        .isFilter('merchant_id', null)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (generalConfig != null) {
      return CommissionConfig.fromMap({
        'id': generalConfig['id'],
        ...generalConfig,
      });
    }

    // Default komisyon
    return CommissionConfig(
      id: 'default',
      commissionRate: 15.0,
      fixedFee: 2.0,
      minimumCommission: 2.0,
      maximumCommission: 50.0,
      validFrom: DateTime.now(),
      isActive: true,
      conditions: {},
    );
  }

  /// Komisyon konfigürasyonu oluştur/güncelle
  Future<String> saveCommissionConfig(CommissionConfig config) async {
    final data = config.toMap();

    if (config.id.isEmpty || config.id == 'default') {
      data.remove('id');
      final response = await _supabase
          .from(_commissionsTable)
          .insert(data)
          .select('id')
          .single();
      return response['id'] as String;
    } else {
      await _supabase.from(_commissionsTable).update(data).eq('id', config.id);
      return config.id;
    }
  }

  // ==================== REPORTING ====================

  /// Merchant gelir raporu
  Future<Map<String, dynamic>> getMerchantEarningsReport(
    String merchantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final transactions = await _supabase
        .from(_transactionsTable)
        .select()
        .eq('merchant_id', merchantId)
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .eq('status', 'completed');

    double totalRevenue = 0;
    double totalCommissions = 0;
    double totalOrders = 0;
    Map<String, double> dailyRevenue = {};

    for (final data in transactions) {
      final transaction = PaymentTransaction.fromMap({
        'id': data['id'],
        ...data,
      });

      if (transaction.type == TransactionType.orderPayment) {
        totalRevenue += transaction.amount;
        totalCommissions += transaction.commissionAmount;
        totalOrders++;

        final dateKey = transaction.createdAt.toIso8601String().split('T')[0];

        dailyRevenue[dateKey] =
            (dailyRevenue[dateKey] ?? 0) + transaction.amount;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalCommissions': totalCommissions,
      'totalOrders': totalOrders,
      'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      'dailyRevenue': dailyRevenue,
      'period': {
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      },
    };
  }

  /// Payment gateway entegrasyonu için temel işlemler
  Future<Map<String, dynamic>> processGatewayPayment({
    required String provider, // 'iyzico', 'paytr', 'param'
    required Map<String, dynamic> paymentData,
  }) async {
    // Bu method'da gerçek gateway entegrasyonu yapılacak
    // Şimdilik mock response dönüyor

    return {
      'success': true,
      'gatewayReference': 'mock_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'completed',
      'message': 'Ödeme başarılı',
      'provider': provider,
    };
  }

  // ==================== RISK MANAGEMENT ====================

  /// Şüpheli işlem tespiti
  Future<bool> checkSuspiciousActivity(String merchantId, double amount) async {
    // Son 24 saat içindeki işlemler
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    final recentTransactions = await _supabase
        .from(_transactionsTable)
        .select()
        .eq('merchant_id', merchantId)
        .gte('created_at', yesterday.toIso8601String());

    double totalAmount = 0;
    int transactionCount = recentTransactions.length;

    for (final data in recentTransactions) {
      totalAmount += (data['amount'] ?? 0).toDouble();
    }

    // Risk kuralları
    const maxDailyAmount = 50000.0; // 50.000 TL
    const maxTransactionCount = 100;
    const maxSingleTransaction = 10000.0; // 10.000 TL

    return totalAmount > maxDailyAmount ||
        transactionCount > maxTransactionCount ||
        amount > maxSingleTransaction;
  }
}
