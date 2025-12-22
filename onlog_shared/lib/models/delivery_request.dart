/// Teslimat Talebi Modeli
/// 
/// delivery_requests tablosundaki verileri temsil eder.
/// Merchant'ların kurye çağırma taleplerini içerir.
class DeliveryRequest {
  final String id;
  final String merchantId;
  final String? courierId;
  final int packageCount;
  final double declaredAmount;
  final double merchantPaymentDue;
  final double courierPaymentDue;
  final double? systemCommission;
  final String status; // pending, assigned, picked_up, delivered, cancelled
  final Map<String, dynamic>? pickupLocation;
  final Map<String, dynamic>? deliveryLocation;
  final String? notes;
  final String? merchantName;
  
  // ⭐ YENİ ALANLAR - Yemek App Entegrasyonu
  final String? externalOrderId;  // Dış platform sipariş no (YO-4521, TR-1234)
  final String source;            // 'manual', 'yemek_app', 'trendyol', 'getir'
  
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const DeliveryRequest({
    required this.id,
    required this.merchantId,
    this.courierId,
    required this.packageCount,
    required this.declaredAmount,
    required this.merchantPaymentDue,
    required this.courierPaymentDue,
    this.systemCommission,
    required this.status,
    this.pickupLocation,
    this.deliveryLocation,
    this.notes,
    this.merchantName,
    
    // ⭐ YENİ PARAMETRELER
    this.externalOrderId,
    this.source = 'manual',  // Varsayılan değer
    
    required this.createdAt,
    this.updatedAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  /// JSON'dan model oluştur
  factory DeliveryRequest.fromJson(Map<String, dynamic> json) {
    return DeliveryRequest(
      id: json['id'] as String,
      merchantId: json['merchant_id'] as String,
      courierId: json['courier_id'] as String?,
      packageCount: json['package_count'] as int,
      declaredAmount: (json['declared_amount'] as num).toDouble(),
      merchantPaymentDue: (json['merchant_payment_due'] as num).toDouble(),
      courierPaymentDue: (json['courier_payment_due'] as num).toDouble(),
      systemCommission: json['system_commission'] != null 
          ? (json['system_commission'] as num).toDouble() 
          : null,
      status: json['status'] as String,
      pickupLocation: json['pickup_location'] as Map<String, dynamic>?,
      deliveryLocation: json['delivery_location'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      merchantName: json['merchant_name'] as String?,
      
      // ⭐ YENİ ALANLAR
      externalOrderId: json['external_order_id'] as String?,
      source: json['source'] as String? ?? 'manual',
      
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      assignedAt: json['assigned_at'] != null 
          ? DateTime.parse(json['assigned_at'] as String) 
          : null,
      pickedUpAt: json['picked_up_at'] != null 
          ? DateTime.parse(json['picked_up_at'] as String) 
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at'] as String) 
          : null,
    );
  }

  /// Model'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant_id': merchantId,
      'courier_id': courierId,
      'package_count': packageCount,
      'declared_amount': declaredAmount,
      'merchant_payment_due': merchantPaymentDue,
      'courier_payment_due': courierPaymentDue,
      'system_commission': systemCommission,
      'status': status,
      'pickup_location': pickupLocation,
      'delivery_location': deliveryLocation,
      'notes': notes,
      'merchant_name': merchantName,
      
      // ⭐ YENİ ALANLAR
      'external_order_id': externalOrderId,
      'source': source,
      
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  /// Kopya oluştur (immutable pattern)
  DeliveryRequest copyWith({
    String? id,
    String? merchantId,
    String? courierId,
    int? packageCount,
    double? declaredAmount,
    double? merchantPaymentDue,
    double? courierPaymentDue,
    double? systemCommission,
    String? status,
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? deliveryLocation,
    String? notes,
    String? merchantName,
    String? externalOrderId,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  }) {
    return DeliveryRequest(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      courierId: courierId ?? this.courierId,
      packageCount: packageCount ?? this.packageCount,
      declaredAmount: declaredAmount ?? this.declaredAmount,
      merchantPaymentDue: merchantPaymentDue ?? this.merchantPaymentDue,
      courierPaymentDue: courierPaymentDue ?? this.courierPaymentDue,
      systemCommission: systemCommission ?? this.systemCommission,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      notes: notes ?? this.notes,
      merchantName: merchantName ?? this.merchantName,
      externalOrderId: externalOrderId ?? this.externalOrderId,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  /// Durum gösterimi (Türkçe)
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'assigned':
        return 'Atandı';
      case 'picked_up':
        return 'Alındı';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  /// Kaynak gösterimi (Türkçe)
  String get sourceDisplayName {
    switch (source) {
      case 'manual':
        return 'Manuel';
      case 'yemek_app':
        return 'Yemek App';
      case 'trendyol':
        return 'Trendyol';
      case 'getir':
        return 'Getir';
      default:
        return source.toUpperCase();
    }
  }

  /// Platform siparişi mi kontrol et
  bool get isExternalOrder => source != 'manual';

  @override
  String toString() {
    return 'DeliveryRequest(id: $id, merchantId: $merchantId, '
        'status: $status, source: $source, externalOrderId: $externalOrderId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
