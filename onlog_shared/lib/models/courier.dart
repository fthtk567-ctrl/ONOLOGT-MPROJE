enum VehicleType {
  motorcycle,
  bicycle,
  car,
  van
}

enum CourierStatus {
  active,
  inactive,
  onDelivery,
  onBreak,
  offline
}

class Courier {
  final String id;
  final String name;
  final String phone;
  final String email;
  final VehicleType vehicleType;
  final double rating;
  final double completionRate;
  final int totalDeliveries;
  final int dailyDeliveries;
  final DateTime joinDate;
  final CourierStatus status;
  
  // Konum bilgisi
  final double latitude;
  final double longitude;
  final DateTime lastLocationUpdate;
  
  // Tercihler
  final List<String> preferredDistricts;
  final List<String> preferredOrderTypes;
  final Map<String, List<int>> preferredHours; // Gün: [başlangıç saati, bitiş saati]
  
  // İstatistikler
  final Map<String, double> averageDeliveryTimes; // Bölge bazlı ortalama teslimat süreleri
  final Map<String, int> deliveriesByDistrict; // Bölge bazlı teslimat sayıları
  
  const Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.rating,
    required this.completionRate,
    required this.totalDeliveries,
    required this.dailyDeliveries,
    required this.joinDate,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.lastLocationUpdate,
    required this.preferredDistricts,
    required this.preferredOrderTypes,
    required this.preferredHours,
    required this.averageDeliveryTimes,
    required this.deliveriesByDistrict,
  });

  // Tercih edilen çalışma saatinde mi kontrol et
  bool isPreferredWorkingHour(DateTime time) {
    String dayKey = _getDayKey(time.weekday);
    if (!preferredHours.containsKey(dayKey)) return false;
    
    var hours = preferredHours[dayKey]!;
    return time.hour >= hours[0] && time.hour <= hours[1];
  }
  
  // Haftanın günü anahtarını al
  String _getDayKey(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  // Bölge bazlı performans puanı hesapla
  double getDistrictPerformanceScore(String district) {
    double deliveryScore = (deliveriesByDistrict[district] ?? 0) / 100; // Max 1.0
    double timeScore = averageDeliveryTimes[district] ?? 30; // Dakika
    
    // Süre puanını normalize et (20dk=1.0, 40dk=0.5, 60dk=0.0)
    double normalizedTimeScore = (60 - timeScore) / 40;
    
    return (deliveryScore + normalizedTimeScore) / 2 * 100;
  }

  // JSON dönüşümleri
  factory Courier.fromJson(Map<String, dynamic> json) {
    return Courier(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.toString() == 'VehicleType.${json['vehicleType']}',
      ),
      rating: json['rating'].toDouble(),
      completionRate: json['completionRate'].toDouble(),
      totalDeliveries: json['totalDeliveries'],
      dailyDeliveries: json['dailyDeliveries'],
      joinDate: DateTime.parse(json['joinDate']),
      status: CourierStatus.values.firstWhere(
        (e) => e.toString() == 'CourierStatus.${json['status']}',
      ),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      lastLocationUpdate: DateTime.parse(json['lastLocationUpdate']),
      preferredDistricts: List<String>.from(json['preferredDistricts']),
      preferredOrderTypes: List<String>.from(json['preferredOrderTypes']),
      preferredHours: Map<String, List<int>>.from(json['preferredHours'].map(
        (key, value) => MapEntry(key, List<int>.from(value))
      )),
      averageDeliveryTimes: Map<String, double>.from(json['averageDeliveryTimes']),
      deliveriesByDistrict: Map<String, int>.from(json['deliveriesByDistrict']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'vehicleType': vehicleType.toString().split('.').last,
      'rating': rating,
      'completionRate': completionRate,
      'totalDeliveries': totalDeliveries,
      'dailyDeliveries': dailyDeliveries,
      'joinDate': joinDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'lastLocationUpdate': lastLocationUpdate.toIso8601String(),
      'preferredDistricts': preferredDistricts,
      'preferredOrderTypes': preferredOrderTypes,
      'preferredHours': preferredHours,
      'averageDeliveryTimes': averageDeliveryTimes,
      'deliveriesByDistrict': deliveriesByDistrict,
    };
  }
}
