
class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final String orderId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final TransactionStatus status;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.orderId,
    this.description,
    this.metadata,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      amount: json['amount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      orderId: json['orderId'],
      description: json['description'],
      metadata: json['metadata'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'orderId': orderId,
      'description': description,
      'metadata': metadata,
      'status': status.toString().split('.').last,
    };
  }
}

enum TransactionType {
  delivery,     // Teslimat ücreti
  bonus,        // Bonus ödemesi
  tip,          // Bahşiş
  commission,   // Komisyon
  penalty,      // Ceza
  adjustment,   // Düzeltme
  withdrawal,   // Para çekme
  deposit,      // Para yatırma
}

enum TransactionStatus {
  pending,    // Beklemede
  completed,  // Tamamlandı
  failed,     // Başarısız
  cancelled,  // İptal edildi
}

class EarningsSummary {
  final double totalEarnings;
  final double deliveryEarnings;
  final double bonusEarnings;
  final double tipEarnings;
  final double commissionTotal;
  final double penaltyTotal;
  final int totalDeliveries;
  final Map<String, double> earningsByPlatform;
  final Map<String, int> deliveriesByPlatform;
  final List<Transaction> recentTransactions;

  const EarningsSummary({
    required this.totalEarnings,
    required this.deliveryEarnings,
    required this.bonusEarnings,
    required this.tipEarnings,
    required this.commissionTotal,
    required this.penaltyTotal,
    required this.totalDeliveries,
    required this.earningsByPlatform,
    required this.deliveriesByPlatform,
    required this.recentTransactions,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: json['totalEarnings'].toDouble(),
      deliveryEarnings: json['deliveryEarnings'].toDouble(),
      bonusEarnings: json['bonusEarnings'].toDouble(),
      tipEarnings: json['tipEarnings'].toDouble(),
      commissionTotal: json['commissionTotal'].toDouble(),
      penaltyTotal: json['penaltyTotal'].toDouble(),
      totalDeliveries: json['totalDeliveries'],
      earningsByPlatform: Map<String, double>.from(json['earningsByPlatform']),
      deliveriesByPlatform: Map<String, int>.from(json['deliveriesByPlatform']),
      recentTransactions: (json['recentTransactions'] as List)
          .map((tx) => Transaction.fromJson(tx))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'deliveryEarnings': deliveryEarnings,
      'bonusEarnings': bonusEarnings,
      'tipEarnings': tipEarnings,
      'commissionTotal': commissionTotal,
      'penaltyTotal': penaltyTotal,
      'totalDeliveries': totalDeliveries,
      'earningsByPlatform': earningsByPlatform,
      'deliveriesByPlatform': deliveriesByPlatform,
      'recentTransactions': recentTransactions.map((tx) => tx.toJson()).toList(),
    };
  }
}

class PaymentAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String? iban;
  final AccountType type;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const PaymentAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.iban,
    required this.type,
    required this.status,
    required this.createdAt,
    this.lastUsed,
  });

  factory PaymentAccount.fromJson(Map<String, dynamic> json) {
    return PaymentAccount(
      id: json['id'],
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      accountHolder: json['accountHolder'],
      iban: json['iban'],
      type: AccountType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      status: AccountStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: json['lastUsed'] != null 
          ? DateTime.parse(json['lastUsed'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
      'iban': iban,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }
}

enum AccountType {
  bank,     // Banka hesabı
  wallet,   // Dijital cüzdan
  card,     // Banka/Kredi kartı
}

enum AccountStatus {
  active,     // Aktif
  inactive,   // Pasif
  suspended,  // Askıya alınmış
  closed,     // Kapatılmış
}

class WithdrawalRequest {
  final String id;
  final double amount;
  final PaymentAccount account;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final WithdrawalStatus status;
  final String? notes;

  const WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.account,
    required this.requestedAt,
    this.processedAt,
    required this.status,
    this.notes,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'],
      amount: json['amount'].toDouble(),
      account: PaymentAccount.fromJson(json['account']),
      requestedAt: DateTime.parse(json['requestedAt']),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt'])
          : null,
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'account': account.toJson(),
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }
}

enum WithdrawalStatus {
  pending,    // Beklemede
  processing, // İşleniyor
  completed,  // Tamamlandı
  failed,     // Başarısız
  cancelled,  // İptal edildi
}

class BonusScheme {
  final String id;
  final String name;
  final BonusType type;
  final double amount;
  final String? description;
  final Map<String, dynamic> conditions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  const BonusScheme({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.description,
    required this.conditions,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory BonusScheme.fromJson(Map<String, dynamic> json) {
    return BonusScheme(
      id: json['id'],
      name: json['name'],
      type: BonusType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      amount: json['amount'].toDouble(),
      description: json['description'],
      conditions: json['conditions'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'])
          : null,
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'conditions': conditions,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

enum BonusType {
  deliveryCount,    // Teslimat sayısına göre
  dailyTarget,      // Günlük hedefe göre
  weeklyTarget,     // Haftalık hedefe göre
  monthlyTarget,    // Aylık hedefe göre
  specialEvent,     // Özel etkinlik
  referral,         // Referans bonusu
  rating,           // Değerlendirme bonusu
}
