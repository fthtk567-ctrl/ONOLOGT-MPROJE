
enum VehicleType {
  motorcycle,
  car,
  van,
  bicycle,
  truck,
}

enum CourierStatus {
  active,
  inactive,
  suspended,
  onVacation,
  onDelivery,
}

class Courier {
  final String id;
  String name;
  String email;
  String phone;
  String profileImage;
  VehicleType vehicleType;
  final double rating; // Performans puanı sistem tarafından hesaplandığı için final kalır
  final int totalDeliveries; // Teslimat sayısı sistem tarafından hesaplandığı için final kalır
  final double completionRate; // Tamamlama oranı sistem tarafından hesaplandığı için final kalır
  final DateTime joinDate; // Katılım tarihi değiştirilemez
  CourierStatus status;
  String accountNumber;
  String bankName;
  String identityNumber;

  Courier({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.vehicleType,
    required this.rating,
    required this.totalDeliveries,
    required this.completionRate,
    required this.joinDate,
    required this.status,
    required this.accountNumber,
    required this.bankName,
    required this.identityNumber,
  });

  // JSON dönüşümleri
  factory Courier.fromJson(Map<String, dynamic> json) {
    return Courier(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      vehicleType: VehicleType.values[json['vehicle_type']],
      rating: json['rating'].toDouble(),
      totalDeliveries: json['total_deliveries'],
      completionRate: json['completion_rate'].toDouble(),
      joinDate: DateTime.parse(json['join_date']),
      status: CourierStatus.values[json['status']],
      accountNumber: json['account_number'],
      bankName: json['bank_name'],
      identityNumber: json['identity_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'vehicle_type': vehicleType.index,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'completion_rate': completionRate,
      'join_date': joinDate.toIso8601String(),
      'status': status.index,
      'account_number': accountNumber,
      'bank_name': bankName,
      'identity_number': identityNumber,
    };
  }

  // Copyler kolay kopyalama için
  Courier copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    VehicleType? vehicleType,
    double? rating,
    int? totalDeliveries,
    double? completionRate,
    DateTime? joinDate,
    CourierStatus? status,
    String? accountNumber,
    String? bankName,
    String? identityNumber,
  }) {
    return Courier(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      vehicleType: vehicleType ?? this.vehicleType,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completionRate: completionRate ?? this.completionRate,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      identityNumber: identityNumber ?? this.identityNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Courier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Courier{id: $id, name: $name, status: $status}';
  }
}