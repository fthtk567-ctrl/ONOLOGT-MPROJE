class Merchant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String address;
  final String? taxNumber;
  final DateTime createdAt;
  final String subscriptionPlan; // free, basic, pro
  final List<String> connectedPlatforms; // trendyol, getir, etc.
  final bool isActive;
  
  // İstatistikler
  final int totalOrders;
  final int monthlyOrders;
  final double totalRevenue;
  final double monthlyRevenue;

  const Merchant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.address,
    this.taxNumber,
    required this.createdAt,
    this.subscriptionPlan = 'free',
    this.connectedPlatforms = const [],
    this.isActive = true,
    this.totalOrders = 0,
    this.monthlyOrders = 0,
    this.totalRevenue = 0.0,
    this.monthlyRevenue = 0.0,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      businessName: json['businessName'],
      address: json['address'],
      taxNumber: json['taxNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      subscriptionPlan: json['subscriptionPlan'] ?? 'free',
      connectedPlatforms: List<String>.from(json['connectedPlatforms'] ?? []),
      isActive: json['isActive'] ?? true,
      totalOrders: json['totalOrders'] ?? 0,
      monthlyOrders: json['monthlyOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'address': address,
      'taxNumber': taxNumber,
      'createdAt': createdAt.toIso8601String(),
      'subscriptionPlan': subscriptionPlan,
      'connectedPlatforms': connectedPlatforms,
      'isActive': isActive,
      'totalOrders': totalOrders,
      'monthlyOrders': monthlyOrders,
      'totalRevenue': totalRevenue,
      'monthlyRevenue': monthlyRevenue,
    };
  }

  Merchant copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? businessName,
    String? address,
    String? taxNumber,
    DateTime? createdAt,
    String? subscriptionPlan,
    List<String>? connectedPlatforms,
    bool? isActive,
    int? totalOrders,
    int? monthlyOrders,
    double? totalRevenue,
    double? monthlyRevenue,
  }) {
    return Merchant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      createdAt: createdAt ?? this.createdAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      connectedPlatforms: connectedPlatforms ?? this.connectedPlatforms,
      isActive: isActive ?? this.isActive,
      totalOrders: totalOrders ?? this.totalOrders,
      monthlyOrders: monthlyOrders ?? this.monthlyOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
    );
  }
}
