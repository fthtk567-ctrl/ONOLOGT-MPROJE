enum DeliveryStatus {
  pending,    // Beklemede
  assigned,   // Atandı
  pickedUp,   // Alındı
  delivered,  // Teslim edildi
  cancelled,  // İptal edildi
  returned    // İade edildi
}

class DeliveryTask {
  final String id;
  final String pickupAddress;
  final String deliveryAddress;
  final String customerName;
  final String customerPhone;
  final DeliveryStatus status;
  final DateTime createdAt;
  final double price;
  final double? distance;
  final double? weight;
  final String? notes;
  final String? deliveryCode;

  DeliveryTask({
    required this.id,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.createdAt,
    required this.price,
    this.distance,
    this.weight,
    this.notes,
    this.deliveryCode,
  });

  // API'den gelen JSON verisini DeliveryTask nesnesine dönüştürmek için factory
  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    return DeliveryTask(
      id: json['id'] as String,
      pickupAddress: json['pickup_address'] as String,
      deliveryAddress: json['delivery_address'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      price: (json['price'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      deliveryCode: json['delivery_code'] as String?,
    );
  }

  // String status değerini DeliveryStatus enum'a dönüştürmek için yardımcı metod
  static DeliveryStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'assigned':
        return DeliveryStatus.assigned;
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      case 'returned':
        return DeliveryStatus.returned;
      default:
        return DeliveryStatus.pending;
    }
  }

  // DeliveryTask nesnesini JSON formatına dönüştürmek için
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'price': price,
      'distance': distance,
      'weight': weight,
      'notes': notes,
      'delivery_code': deliveryCode,
    };
  }

  // DeliveryStatus enum değerini String'e dönüştürmek için yardımcı metod
  static String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.assigned:
        return 'assigned';
      case DeliveryStatus.pickedUp:
        return 'picked_up';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
      case DeliveryStatus.returned:
        return 'returned';
    }
  }
}