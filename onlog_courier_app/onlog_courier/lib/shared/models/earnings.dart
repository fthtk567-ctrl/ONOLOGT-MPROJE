class DeliveryEarning {
  final String id;
  final double amount;
  final DateTime timestamp;
  final String description;
  final double tip;
  final double bonus;

  DeliveryEarning({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.description,
    this.tip = 0.0,
    this.bonus = 0.0,
  });

  // Toplam kazancı hesapla (teslimat ücreti + bahşiş + bonus)
  double get totalAmount => amount + tip + bonus;
  
  // Bahşiş veya bonus var mı?
  bool get hasTipOrBonus => tip > 0 || bonus > 0;
  
  // JSON dönüşümleri
  factory DeliveryEarning.fromJson(Map<String, dynamic> json) {
    return DeliveryEarning(
      id: json['id'],
      amount: json['amount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
      tip: json['tip']?.toDouble() ?? 0.0,
      bonus: json['bonus']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'tip': tip,
      'bonus': bonus,
    };
  }
}

class DailyEarnings {
  final DateTime date;
  final double totalEarnings;
  final int deliveryCount;
  final double tipAmount;
  final double bonusAmount;
  final List<DeliveryEarning> deliveries;

  DailyEarnings({
    required this.date,
    required this.totalEarnings,
    required this.deliveryCount,
    required this.tipAmount,
    required this.bonusAmount,
    required this.deliveries,
  });

  // JSON dönüşümleri
  factory DailyEarnings.fromJson(Map<String, dynamic> json) {
    return DailyEarnings(
      date: DateTime.parse(json['date']),
      totalEarnings: json['total_earnings'].toDouble(),
      deliveryCount: json['delivery_count'],
      tipAmount: json['tip_amount'].toDouble(),
      bonusAmount: json['bonus_amount'].toDouble(),
      deliveries: (json['deliveries'] as List)
          .map((e) => DeliveryEarning.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'total_earnings': totalEarnings,
      'delivery_count': deliveryCount,
      'tip_amount': tipAmount,
      'bonus_amount': bonusAmount,
      'deliveries': deliveries.map((e) => e.toJson()).toList(),
    };
  }
}

class WeeklyEarnings {
  final DateTime startDate;
  final DateTime endDate;
  final double totalEarnings;
  final int deliveryCount;
  final double tipAmount;
  final double bonusAmount;
  final List<DailyEarnings> dailyEarnings;

  WeeklyEarnings({
    required this.startDate,
    required this.endDate,
    required this.totalEarnings,
    required this.deliveryCount,
    required this.tipAmount,
    required this.bonusAmount,
    required this.dailyEarnings,
  });

  // En yüksek günlük kazancı hesapla
  double get maxDailyEarning {
    if (dailyEarnings.isEmpty) return 0;
    return dailyEarnings
        .map((daily) => daily.totalEarnings)
        .reduce((value, element) => value > element ? value : element);
  }

  // JSON dönüşümleri
  factory WeeklyEarnings.fromJson(Map<String, dynamic> json) {
    return WeeklyEarnings(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalEarnings: json['total_earnings'].toDouble(),
      deliveryCount: json['delivery_count'],
      tipAmount: json['tip_amount'].toDouble(),
      bonusAmount: json['bonus_amount'].toDouble(),
      dailyEarnings: (json['daily_earnings'] as List)
          .map((e) => DailyEarnings.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_earnings': totalEarnings,
      'delivery_count': deliveryCount,
      'tip_amount': tipAmount,
      'bonus_amount': bonusAmount,
      'daily_earnings': dailyEarnings.map((e) => e.toJson()).toList(),
    };
  }
}

class MonthlyEarnings {
  final int month;
  final int year;
  final double totalEarnings;
  final int deliveryCount;
  final double tipAmount;
  final double bonusAmount;
  final List<WeeklyEarnings> weeklyEarnings;
  final double? totalHours;
  final double? totalDistance;

  MonthlyEarnings({
    required this.month,
    required this.year,
    required this.totalEarnings,
    required this.deliveryCount,
    required this.tipAmount,
    required this.bonusAmount,
    required this.weeklyEarnings,
    this.totalHours,
    this.totalDistance,
  });

  // JSON dönüşümleri
  factory MonthlyEarnings.fromJson(Map<String, dynamic> json) {
    return MonthlyEarnings(
      month: json['month'],
      year: json['year'],
      totalEarnings: json['total_earnings'].toDouble(),
      deliveryCount: json['delivery_count'],
      tipAmount: json['tip_amount'].toDouble(),
      bonusAmount: json['bonus_amount'].toDouble(),
      weeklyEarnings: (json['weekly_earnings'] as List)
          .map((e) => WeeklyEarnings.fromJson(e))
          .toList(),
      totalHours: json['total_hours']?.toDouble(),
      totalDistance: json['total_distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'total_earnings': totalEarnings,
      'delivery_count': deliveryCount,
      'tip_amount': tipAmount,
      'bonus_amount': bonusAmount,
      'weekly_earnings': weeklyEarnings.map((e) => e.toJson()).toList(),
      'total_hours': totalHours,
      'total_distance': totalDistance,
    };
  }
}