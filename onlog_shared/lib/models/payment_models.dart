enum PaymentMethod {
  creditCard,
  debitCard,
  bankTransfer,
  cash,
  wallet,
  installment,
}

enum PaymentStatus {
  pending,        // Beklemede
  processing,     // İşleniyor
  completed,      // Tamamlandı
  failed,         // Başarısız
  refunded,       // İade edildi
  partial,        // Kısmi ödeme
  cancelled,      // İptal edildi
}

enum TransactionType {
  orderPayment,      // Sipariş ödemesi
  deliveryFee,       // Teslimat ücreti
  commission,        // Komisyon kesintisi
  refund,           // İade
  penalty,          // Ceza
  bonus,            // Bonus ödemesi
  withdrawal,       // Para çekme
  topup,            // Bakiye yükleme
}

class PaymentTransaction {
  final String id;
  final String orderId;
  final String? merchantId;
  final String? courierId;
  final String? customerId;
  
  final double amount;
  final double originalAmount;
  final double commissionAmount;
  final double vatAmount;
  final String currency;
  
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final TransactionType type;
  
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? settledAt;
  
  final String? gatewayReference;
  final String? gatewayProvider; // iyzico, paytr, param
  final Map<String, dynamic> gatewayResponse;
  
  final String? description;
  final Map<String, dynamic> metadata;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    this.merchantId,
    this.courierId,
    this.customerId,
    required this.amount,
    required this.originalAmount,
    required this.commissionAmount,
    required this.vatAmount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.type,
    required this.createdAt,
    this.processedAt,
    this.settledAt,
    this.gatewayReference,
    this.gatewayProvider,
    required this.gatewayResponse,
    this.description,
    required this.metadata,
  });

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      merchantId: map['merchantId'],
      courierId: map['courierId'],
      customerId: map['customerId'],
      amount: (map['amount'] ?? 0).toDouble(),
      originalAmount: (map['originalAmount'] ?? 0).toDouble(),
      commissionAmount: (map['commissionAmount'] ?? 0).toDouble(),
      vatAmount: (map['vatAmount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'TRY',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${map['paymentMethod']}',
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${map['type']}',
        orElse: () => TransactionType.orderPayment,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      processedAt: map['processedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['processedAt'])
          : null,
      settledAt: map['settledAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['settledAt'])
          : null,
      gatewayReference: map['gatewayReference'],
      gatewayProvider: map['gatewayProvider'],
      gatewayResponse: Map<String, dynamic>.from(map['gatewayResponse'] ?? {}),
      description: map['description'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'merchantId': merchantId,
      'courierId': courierId,
      'customerId': customerId,
      'amount': amount,
      'originalAmount': originalAmount,
      'commissionAmount': commissionAmount,
      'vatAmount': vatAmount,
      'currency': currency,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'processedAt': processedAt?.millisecondsSinceEpoch,
      'settledAt': settledAt?.millisecondsSinceEpoch,
      'gatewayReference': gatewayReference,
      'gatewayProvider': gatewayProvider,
      'gatewayResponse': gatewayResponse,
      'description': description,
      'metadata': metadata,
    };
  }

  PaymentTransaction copyWith({
    String? id,
    String? orderId,
    String? merchantId,
    String? courierId,
    String? customerId,
    double? amount,
    double? originalAmount,
    double? commissionAmount,
    double? vatAmount,
    String? currency,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    TransactionType? type,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? settledAt,
    String? gatewayReference,
    String? gatewayProvider,
    Map<String, dynamic>? gatewayResponse,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      merchantId: merchantId ?? this.merchantId,
      courierId: courierId ?? this.courierId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      vatAmount: vatAmount ?? this.vatAmount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      settledAt: settledAt ?? this.settledAt,
      gatewayReference: gatewayReference ?? this.gatewayReference,
      gatewayProvider: gatewayProvider ?? this.gatewayProvider,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isRefunded => status == PaymentStatus.refunded;
}

// Merchant wallet/bakiye sistemi
class MerchantWallet {
  final String merchantId;
  final double balance;              // Mevcut bakiye
  final double pendingBalance;       // Bekleyen bakiye
  final double frozenBalance;        // Dondurulmuş bakiye (risk/ceza)
  final double totalEarnings;        // Toplam kazanç
  final double totalWithdrawals;     // Toplam çekimler
  final double totalCommissions;     // Toplam komisyon
  final String currency;
  final DateTime lastUpdated;
  final Map<String, dynamic> limits; // Çekim limitleri

  const MerchantWallet({
    required this.merchantId,
    required this.balance,
    required this.pendingBalance,
    required this.frozenBalance,
    required this.totalEarnings,
    required this.totalWithdrawals,
    required this.totalCommissions,
    required this.currency,
    required this.lastUpdated,
    required this.limits,
  });

  factory MerchantWallet.fromMap(Map<String, dynamic> map) {
    return MerchantWallet(
      merchantId: map['merchantId'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
      pendingBalance: (map['pendingBalance'] ?? 0).toDouble(),
      frozenBalance: (map['frozenBalance'] ?? 0).toDouble(),
      totalEarnings: (map['totalEarnings'] ?? 0).toDouble(),
      totalWithdrawals: (map['totalWithdrawals'] ?? 0).toDouble(),
      totalCommissions: (map['totalCommissions'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'TRY',
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      limits: Map<String, dynamic>.from(map['limits'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'balance': balance,
      'pendingBalance': pendingBalance,
      'frozenBalance': frozenBalance,
      'totalEarnings': totalEarnings,
      'totalWithdrawals': totalWithdrawals,
      'totalCommissions': totalCommissions,
      'currency': currency,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'limits': limits,
    };
  }

  MerchantWallet copyWith({
    String? merchantId,
    double? balance,
    double? pendingBalance,
    double? frozenBalance,
    double? totalEarnings,
    double? totalWithdrawals,
    double? totalCommissions,
    String? currency,
    DateTime? lastUpdated,
    Map<String, dynamic>? limits,
  }) {
    return MerchantWallet(
      merchantId: merchantId ?? this.merchantId,
      balance: balance ?? this.balance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      frozenBalance: frozenBalance ?? this.frozenBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      totalCommissions: totalCommissions ?? this.totalCommissions,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      limits: limits ?? this.limits,
    );
  }

  double get availableBalance => balance - frozenBalance;
  bool get canWithdraw => availableBalance > 0;
}

// Komisyon konfigürasyonu
class CommissionConfig {
  final String id;
  final String? merchantId;        // null ise genel ayar
  final String? categoryId;        // Restoran kategorisi
  final double commissionRate;     // % olarak (15.5 = %15.5)
  final double fixedFee;          // Sabit ücret
  final double minimumCommission; // Minimum komisyon
  final double maximumCommission; // Maximum komisyon
  final DateTime validFrom;
  final DateTime? validTo;
  final bool isActive;
  final Map<String, dynamic> conditions; // Özel koşullar

  const CommissionConfig({
    required this.id,
    this.merchantId,
    this.categoryId,
    required this.commissionRate,
    required this.fixedFee,
    required this.minimumCommission,
    required this.maximumCommission,
    required this.validFrom,
    this.validTo,
    required this.isActive,
    required this.conditions,
  });

  /// Varsayılan komisyon oranı (geriye uyumluluk için)
  double get defaultRate => commissionRate;

  factory CommissionConfig.fromMap(Map<String, dynamic> map) {
    return CommissionConfig(
      id: map['id'] ?? '',
      merchantId: map['merchantId'],
      categoryId: map['categoryId'],
      commissionRate: (map['commissionRate'] ?? 0).toDouble(),
      fixedFee: (map['fixedFee'] ?? 0).toDouble(),
      minimumCommission: (map['minimumCommission'] ?? 0).toDouble(),
      maximumCommission: (map['maximumCommission'] ?? 0).toDouble(),
      validFrom: DateTime.fromMillisecondsSinceEpoch(map['validFrom']),
      validTo: map['validTo'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['validTo'])
          : null,
      isActive: map['isActive'] ?? false,
      conditions: Map<String, dynamic>.from(map['conditions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantId': merchantId,
      'categoryId': categoryId,
      'commissionRate': commissionRate,
      'fixedFee': fixedFee,
      'minimumCommission': minimumCommission,
      'maximumCommission': maximumCommission,
      'validFrom': validFrom.millisecondsSinceEpoch,
      'validTo': validTo?.millisecondsSinceEpoch,
      'isActive': isActive,
      'conditions': conditions,
    };
  }

  double calculateCommission(double orderAmount) {
    // Komisyon hesaplama
    double commission = (orderAmount * commissionRate / 100) + fixedFee;
    
    // Min/max kontrolleri
    if (commission < minimumCommission) commission = minimumCommission;
    if (commission > maximumCommission) commission = maximumCommission;
    
    return commission;
  }
}