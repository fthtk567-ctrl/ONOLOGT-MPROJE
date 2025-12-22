enum ManualDeliveryVehicleType {
  motorcycle,
  truck,
}

enum ManualDeliveryStatus {
  pending,
  assigned,
  pickedUp,
  delivered,
  cancelled,
}

class ManualDelivery {
  final String id;
  final String fromAddress;
  final String toAddress;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
  final double weight; // kg
  final ManualDeliveryVehicleType vehicleType;
  final double distance; // km
  final double price; // TL
  final DateTime requestTime;
  final String customerName;
  final String customerPhone;
  final String? notes;
  final ManualDeliveryStatus status;

  const ManualDelivery({
    required this.id,
    required this.fromAddress,
    required this.toAddress,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    required this.weight,
    required this.vehicleType,
    required this.distance,
    required this.price,
    required this.requestTime,
    required this.customerName,
    required this.customerPhone,
    this.notes,
    required this.status,
  });

  String get vehicleDisplayName {
    switch (vehicleType) {
      case ManualDeliveryVehicleType.motorcycle:
        return 'Motokurye';
      case ManualDeliveryVehicleType.truck:
        return 'Kamyon';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ManualDeliveryStatus.pending:
        return 'Beklemede';
      case ManualDeliveryStatus.assigned:
        return 'Araç Atandı';
      case ManualDeliveryStatus.pickedUp:
        return 'Yolda';
      case ManualDeliveryStatus.delivered:
        return 'Teslim Edildi';
      case ManualDeliveryStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  ManualDelivery copyWith({
    String? id,
    String? fromAddress,
    String? toAddress,
    double? fromLatitude,
    double? fromLongitude,
    double? toLatitude,
    double? toLongitude,
    double? weight,
    ManualDeliveryVehicleType? vehicleType,
    double? distance,
    double? price,
    DateTime? requestTime,
    String? customerName,
    String? customerPhone,
    String? notes,
    ManualDeliveryStatus? status,
  }) {
    return ManualDelivery(
      id: id ?? this.id,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      fromLatitude: fromLatitude ?? this.fromLatitude,
      fromLongitude: fromLongitude ?? this.fromLongitude,
      toLatitude: toLatitude ?? this.toLatitude,
      toLongitude: toLongitude ?? this.toLongitude,
      weight: weight ?? this.weight,
      vehicleType: vehicleType ?? this.vehicleType,
      distance: distance ?? this.distance,
      price: price ?? this.price,
      requestTime: requestTime ?? this.requestTime,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
