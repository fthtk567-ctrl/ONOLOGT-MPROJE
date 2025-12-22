import 'package:hive/hive.dart';

part 'cached_delivery.g.dart';

/// Offline çalışma için local cache'lenen teslimat
@HiveType(typeId: 0)
class CachedDelivery extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String merchantId;

  @HiveField(2)
  String merchantName;

  @HiveField(3)
  String merchantAddress;

  @HiveField(4)
  double? pickupLat;

  @HiveField(5)
  double? pickupLng;

  @HiveField(6)
  String deliveryAddress;

  @HiveField(7)
  double? deliveryLat;

  @HiveField(8)
  double? deliveryLng;

  @HiveField(9)
  double declaredAmount;

  @HiveField(10)
  int packageCount;

  @HiveField(11)
  String status; // pending, assigned, pickedUp, delivering, delivered, cancelled

  @HiveField(12)
  String? assignedCourierId;

  @HiveField(13)
  String? courierType;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime? assignedAt;

  @HiveField(16)
  DateTime? pickedUpAt;

  @HiveField(17)
  DateTime? deliveredAt;

  @HiveField(18)
  String? notes;

  @HiveField(19)
  String? customerPhone;

  @HiveField(20)
  String? customerName;

  @HiveField(21)
  bool isSynced; // Supabase ile senkronize mi?

  @HiveField(22)
  DateTime lastUpdated;

  CachedDelivery({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.merchantAddress,
    this.pickupLat,
    this.pickupLng,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.declaredAmount,
    required this.packageCount,
    required this.status,
    this.assignedCourierId,
    this.courierType,
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.notes,
    this.customerPhone,
    this.customerName,
    this.isSynced = true,
    required this.lastUpdated,
  });

  /// Supabase'den CachedDelivery oluştur
  factory CachedDelivery.fromSupabase(String id, Map<String, dynamic> data) {
    return CachedDelivery(
      id: id,
      merchantId: data['merchant_id'] ?? '',
      merchantName: data['merchant_name'] ?? '',
      merchantAddress: data['pickup_address'] ?? '',
      pickupLat: data['pickup_location']?['latitude']?.toDouble(),
      pickupLng: data['pickup_location']?['longitude']?.toDouble(),
      deliveryAddress: data['delivery_address'] ?? '',
      deliveryLat: data['delivery_location']?['latitude']?.toDouble(),
      deliveryLng: data['delivery_location']?['longitude']?.toDouble(),
      declaredAmount: (data['price'] ?? 0).toDouble(),
      packageCount: data['package_count'] ?? 1,
      status: data['status'] ?? 'pending',
      assignedCourierId: data['courier_id'],
      courierType: data['courier_type'],
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      assignedAt: data['assigned_at'] != null 
          ? DateTime.parse(data['assigned_at']) 
          : null,
      pickedUpAt: data['picked_up_at'] != null 
          ? DateTime.parse(data['picked_up_at']) 
          : null,
      deliveredAt: data['delivered_at'] != null 
          ? DateTime.parse(data['delivered_at']) 
          : null,
      notes: data['notes'],
      customerPhone: data['customer_phone'],
      customerName: data['customer_name'],
      isSynced: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Firestore'dan CachedDelivery oluştur (DEPRECATED - Backward compatibility only)
  /// Eski cache verilerini okumak için gerekli, YENİ veriler için fromSupabase() kullanın!
  @deprecated
  factory CachedDelivery.fromFirestore(String id, Map<String, dynamic> data) {
    return CachedDelivery(
      id: id,
      merchantId: data['merchantId'] ?? '',
      merchantName: data['merchantName'] ?? '',
      merchantAddress: data['merchantAddress'] ?? '',
      pickupLat: data['pickupLocation']?['latitude']?.toDouble(),
      pickupLng: data['pickupLocation']?['longitude']?.toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryLat: data['deliveryLocation']?['latitude']?.toDouble(),
      deliveryLng: data['deliveryLocation']?['longitude']?.toDouble(),
      declaredAmount: (data['declaredAmount'] ?? 0).toDouble(),
      packageCount: data['packageCount'] ?? 1,
      status: data['status'] ?? 'pending',
      assignedCourierId: data['assignedCourierId'],
      courierType: data['courierType'],
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      assignedAt: (data['assignedAt'] as dynamic)?.toDate(),
      pickedUpAt: (data['pickedUpAt'] as dynamic)?.toDate(),
      deliveredAt: (data['deliveredAt'] as dynamic)?.toDate(),
      notes: data['notes'],
      customerPhone: data['customerPhone'],
      customerName: data['customerName'],
      isSynced: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Supabase'e göndermek için Map'e çevir
  Map<String, dynamic> toSupabase() {
    return {
      'merchant_id': merchantId,
      'merchant_name': merchantName,
      'pickup_address': merchantAddress,
      'pickup_location': pickupLat != null && pickupLng != null
          ? {'latitude': pickupLat, 'longitude': pickupLng}
          : null,
      'delivery_address': deliveryAddress,
      'delivery_location': deliveryLat != null && deliveryLng != null
          ? {'latitude': deliveryLat, 'longitude': deliveryLng}
          : null,
      'price': declaredAmount,
      'package_count': packageCount,
      'status': status,
      'courier_id': assignedCourierId,
      'courier_type': courierType,
      'assigned_at': assignedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'notes': notes,
      'customer_phone': customerPhone,
      'customer_name': customerName,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Firestore'a göndermek için Map'e çevir (DEPRECATED - Backward compatibility only)
  /// Yeni kodlar için toSupabase() kullanın!
  @deprecated
  Map<String, dynamic> toFirestore() {
    return {
      'merchantId': merchantId,
      'merchantName': merchantName,
      'merchantAddress': merchantAddress,
      'pickupLocation': pickupLat != null && pickupLng != null
          ? {'latitude': pickupLat, 'longitude': pickupLng}
          : null,
      'deliveryAddress': deliveryAddress,
      'deliveryLocation': deliveryLat != null && deliveryLng != null
          ? {'latitude': deliveryLat, 'longitude': deliveryLng}
          : null,
      'declaredAmount': declaredAmount,
      'packageCount': packageCount,
      'status': status,
      'assignedCourierId': assignedCourierId,
      'courierType': courierType,
      'createdAt': createdAt,
      'assignedAt': assignedAt,
      'pickedUpAt': pickedUpAt,
      'deliveredAt': deliveredAt,
      'notes': notes,
      'customerPhone': customerPhone,
      'customerName': customerName,
    };
  }

  /// İki delivery aynı mı kontrol et
  bool isSameAs(CachedDelivery other) {
    return id == other.id &&
        status == other.status &&
        lastUpdated.isAtSameMomentAs(other.lastUpdated);
  }

  @override
  String toString() {
    return 'CachedDelivery(id: $id, status: $status, merchant: $merchantName, synced: $isSynced)';
  }
}
