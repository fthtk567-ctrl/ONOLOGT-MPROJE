/// Esnaf Kurye Ödeme Ayarları Modeli
/// Her esnaf kendi komisyon/ödeme şeklini seçer
library;

enum PaymentType {
  percentage('Yüzde Komisyon'),
  perPackage('Paket Başı Sabit'),
  hybrid('Karma (Min + Komisyon)');

  final String displayName;
  const PaymentType(this.displayName);
}

enum PaymentCycle {
  every10Days('10 Günde Bir'),
  weekly('Haftalık'),
  biweekly('İki Haftada Bir'),
  monthly('Aylık');

  final String displayName;
  const PaymentCycle(this.displayName);
}

enum PaymentMethod {
  bankTransfer('Banka Havalesi'),
  cash('Nakit'),
  crypto('Kripto');

  final String displayName;
  const PaymentMethod(this.displayName);
}

class PaymentSettings {
  // Ödeme Tipi
  final PaymentType type;
  
  // Yüzde Komisyon İçin (type = percentage veya hybrid)
  final double? commissionRate; // %18, %15, %20 vb
  
  // Paket Başı Sabit İçin (type = perPackage)
  final double? perPackageRate; // 50₺, 40₺, 60₺ vb
  
  // Karma Sistem İçin (type = hybrid)
  final double? minimumGuarantee; // Min garanti (örn: 300₺)
  final double? commissionRateAboveMin; // Min üzeri komisyon
  
  // Ödeme Döngüsü
  final PaymentCycle paymentCycle;
  final int paymentStartDay; // 1-11-21, 2-12-22, 3-13-23 vb
  
  // Ödeme Yöntemi
  final PaymentMethod? paymentMethod;
  
  // Banka Bilgileri
  final BankInfo? bankInfo;

  PaymentSettings({
    required this.type,
    this.commissionRate,
    this.perPackageRate,
    this.minimumGuarantee,
    this.commissionRateAboveMin,
    required this.paymentCycle,
    required this.paymentStartDay,
    this.paymentMethod,
    this.bankInfo,
  });

  /// Siparişten esnafın kazancını hesapla
  double calculateEarnings(double orderTotal) {
    switch (type) {
      case PaymentType.percentage:
        // Sipariş toplamının %X'i
        return orderTotal * (commissionRate! / 100);
      
      case PaymentType.perPackage:
        // Paket başı sabit ücret
        return perPackageRate!;
      
      case PaymentType.hybrid:
        // Karma: Min garanti + üzeri komisyon
        final commission = orderTotal * (commissionRateAboveMin! / 100);
        return commission > minimumGuarantee! 
            ? commission 
            : minimumGuarantee!;
    }
  }

  /// Sonraki ödeme tarihini hesapla
  DateTime getNextPaymentDate(DateTime lastPaymentDate) {
    switch (paymentCycle) {
      case PaymentCycle.every10Days:
        // 10 günde bir: paymentStartDay bazlı (1-11-21, 2-12-22...)
        final now = DateTime.now();
        final currentMonth = now.month;
        final currentYear = now.year;
        
        // Bu aydaki ödeme günleri
        final dates = [
          DateTime(currentYear, currentMonth, paymentStartDay),
          DateTime(currentYear, currentMonth, paymentStartDay + 10),
          DateTime(currentYear, currentMonth, paymentStartDay + 20),
        ];
        
        // Gelecekteki en yakın tarihi bul
        for (var date in dates) {
          if (date.isAfter(now)) return date;
        }
        
        // Yoksa gelecek ayın ilk ödeme günü
        return DateTime(currentYear, currentMonth + 1, paymentStartDay);
      
      case PaymentCycle.weekly:
        return lastPaymentDate.add(Duration(days: 7));
      
      case PaymentCycle.biweekly:
        return lastPaymentDate.add(Duration(days: 14));
      
      case PaymentCycle.monthly:
        return DateTime(
          lastPaymentDate.year,
          lastPaymentDate.month + 1,
          paymentStartDay,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'commissionRate': commissionRate,
      'perPackageRate': perPackageRate,
      'minimumGuarantee': minimumGuarantee,
      'commissionRateAboveMin': commissionRateAboveMin,
      'paymentCycle': paymentCycle.name,
      'paymentStartDay': paymentStartDay,
      'paymentMethod': paymentMethod?.name,
      'bankInfo': bankInfo?.toMap(),
    };
  }

  factory PaymentSettings.fromMap(Map<String, dynamic> map) {
    return PaymentSettings(
      type: PaymentType.values.firstWhere((e) => e.name == map['type']),
      commissionRate: map['commissionRate']?.toDouble(),
      perPackageRate: map['perPackageRate']?.toDouble(),
      minimumGuarantee: map['minimumGuarantee']?.toDouble(),
      commissionRateAboveMin: map['commissionRateAboveMin']?.toDouble(),
      paymentCycle: PaymentCycle.values.firstWhere((e) => e.name == map['paymentCycle']),
      paymentStartDay: map['paymentStartDay'],
      paymentMethod: map['paymentMethod'] != null 
          ? PaymentMethod.values.firstWhere((e) => e.name == map['paymentMethod'])
          : null,
      bankInfo: map['bankInfo'] != null 
          ? BankInfo.fromMap(map['bankInfo'])
          : null,
    );
  }
}

class BankInfo {
  final String bankName;
  final String iban;
  final String accountHolder;

  BankInfo({
    required this.bankName,
    required this.iban,
    required this.accountHolder,
  });

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'iban': iban,
      'accountHolder': accountHolder,
    };
  }

  factory BankInfo.fromMap(Map<String, dynamic> map) {
    return BankInfo(
      bankName: map['bankName'],
      iban: map['iban'],
      accountHolder: map['accountHolder'],
    );
  }
}

class EarningsSummary {
  final double currentPeriod;   // Bu dönem kazanç
  final double lastPayment;     // Son ödeme
  final double totalEarned;     // Toplam kazanç
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;

  EarningsSummary({
    required this.currentPeriod,
    required this.lastPayment,
    required this.totalEarned,
    this.lastPaymentDate,
    this.nextPaymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentPeriod': currentPeriod,
      'lastPayment': lastPayment,
      'totalEarned': totalEarned,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'nextPaymentDate': nextPaymentDate?.toIso8601String(),
    };
  }

  factory EarningsSummary.fromMap(Map<String, dynamic> map) {
    return EarningsSummary(
      currentPeriod: map['currentPeriod']?.toDouble() ?? 0.0,
      lastPayment: map['lastPayment']?.toDouble() ?? 0.0,
      totalEarned: map['totalEarned']?.toDouble() ?? 0.0,
      lastPaymentDate: map['lastPaymentDate'] != null 
          ? DateTime.parse(map['lastPaymentDate'])
          : null,
      nextPaymentDate: map['nextPaymentDate'] != null 
          ? DateTime.parse(map['nextPaymentDate'])
          : null,
    );
  }
}
