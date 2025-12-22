import 'package:uuid/uuid.dart';

/// User model (Restaurant owner, Admin, etc.)
class User {
  final String id; // Firebase Auth UID veya UUID
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String? restaurantId; // Eğer restoran sahibiyse
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.restaurantId,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Generate new user with UUID
  factory User.create({
    required String email,
    required String name,
    required String phone,
    required UserRole role,
    String? restaurantId,
  }) {
    const uuid = Uuid();
    return User(
      id: uuid.v4(),
      email: email,
      name: name,
      phone: phone,
      role: role,
      restaurantId: restaurantId,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role.name,
        'restaurantId': restaurantId,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        role: UserRole.values.byName(json['role'] as String),
        restaurantId: json['restaurantId'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.parse(json['lastLoginAt'] as String)
            : null,
      );

  User copyWith({
    String? email,
    String? name,
    String? phone,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role,
      restaurantId: restaurantId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

enum UserRole {
  superAdmin, // Tüm sisteme erişim
  admin, // Admin panel erişimi
  restaurantOwner, // Restoran paneli erişimi
  restaurantStaff, // Restoran çalışanı
  courier, // Kurye uygulaması erişimi
}
