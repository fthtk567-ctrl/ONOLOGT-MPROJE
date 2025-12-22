import 'package:uuid/uuid.dart';

/// Restaurant/Market model with unique ID
class Restaurant {
  final String id; // Unique restaurant ID (Firebase UID veya UUID)
  final String name;
  final String address;
  final String phone;
  final String email;
  final String ownerName;
  final String ownerId; // Restaurant owner's user ID
  final RestaurantType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Platform integrations
  final Map<String, PlatformIntegration> platformIntegrations;
  
  // Statistics
  final int totalOrders;
  final double totalRevenue;
  final double rating;
  
  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.ownerName,
    required this.ownerId,
    required this.type,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.platformIntegrations = const {},
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    this.rating = 0.0,
  });

  /// Generate new restaurant with UUID
  factory Restaurant.create({
    required String name,
    required String address,
    required String phone,
    required String email,
    required String ownerName,
    required String ownerId,
    required RestaurantType type,
  }) {
    const uuid = Uuid();
    return Restaurant(
      id: uuid.v4(), // Generate unique UUID
      name: name,
      address: address,
      phone: phone,
      email: email,
      ownerName: ownerName,
      ownerId: ownerId,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'ownerName': ownerName,
        'ownerId': ownerId,
        'type': type.name,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'platformIntegrations': platformIntegrations.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'rating': rating,
      };

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        ownerName: json['ownerName'] as String,
        ownerId: json['ownerId'] as String,
        type: RestaurantType.values.byName(json['type'] as String),
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        platformIntegrations: (json['platformIntegrations'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(
                      key,
                      PlatformIntegration.fromJson(value as Map<String, dynamic>),
                    )) ??
            {},
        totalOrders: json['totalOrders'] as int? ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      );

  Restaurant copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? ownerName,
    bool? isActive,
    Map<String, PlatformIntegration>? platformIntegrations,
    int? totalOrders,
    double? totalRevenue,
    double? rating,
  }) {
    return Restaurant(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ownerName: ownerName ?? this.ownerName,
      ownerId: ownerId,
      type: type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      platformIntegrations: platformIntegrations ?? this.platformIntegrations,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      rating: rating ?? this.rating,
    );
  }
}

enum RestaurantType {
  restaurant, // Normal restoran
  fastFood, // Fast food
  cafe, // Kafe
  market, // Market/bakkal
}

/// Platform integration details
class PlatformIntegration {
  final String platformName; // 'trendyol', 'getir', 'yemeksepeti'
  final String apiKey;
  final String storeId;
  final String webhookUrl;
  final bool isActive;
  final DateTime? lastSync;

  PlatformIntegration({
    required this.platformName,
    required this.apiKey,
    required this.storeId,
    required this.webhookUrl,
    this.isActive = true,
    this.lastSync,
  });

  Map<String, dynamic> toJson() => {
        'platformName': platformName,
        'apiKey': apiKey,
        'storeId': storeId,
        'webhookUrl': webhookUrl,
        'isActive': isActive,
        'lastSync': lastSync?.toIso8601String(),
      };

  factory PlatformIntegration.fromJson(Map<String, dynamic> json) =>
      PlatformIntegration(
        platformName: json['platformName'] as String,
        apiKey: json['apiKey'] as String,
        storeId: json['storeId'] as String,
        webhookUrl: json['webhookUrl'] as String,
        isActive: json['isActive'] as bool? ?? true,
        lastSync: json['lastSync'] != null
            ? DateTime.parse(json['lastSync'] as String)
            : null,
      );
}
