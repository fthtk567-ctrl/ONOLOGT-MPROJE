enum OrderStatus {
  pending,     // Yeni sipariş - kurye bekliyor
  assigned,    // Kurye atandı
  preparing,   // Hazırlanıyor
  ready,       // Hazır - kurye alabilir
  pickedUp,    // Kurye aldı
  delivered,   // Teslim edildi
  cancelled,   // İptal edildi
}

enum OrderPlatform {
  trendyol,
  yemeksepeti,
  getir,
  bitaksi,
  manuel,
}

enum OrderType {
  food,        // Yemek
  market,      // Market alışverişi
  package,     // Paket/kargo
  document,    // Evrak
  other,       // Diğer
}

enum OrderPriority {
  low,         // Düşük öncelik
  normal,      // Normal öncelik
  high,        // Yüksek öncelik
  urgent,      // Acil
}

class Address {
  final String fullAddress;
  final String district;
  final String city;
  final String? buildingNo;
  final String? apartment;
  final String? floor;
  final double? latitude;
  final double? longitude;

  const Address({
    required this.fullAddress,
    required this.district,
    required this.city,
    this.buildingNo,
    this.apartment,
    this.floor,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      fullAddress: json['fullAddress'],
      district: json['district'],
      city: json['city'],
      buildingNo: json['buildingNo'],
      apartment: json['apartment'],
      floor: json['floor'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullAddress': fullAddress,
      'district': district,
      'city': city,
      'buildingNo': buildingNo,
      'apartment': apartment,
      'floor': floor,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Customer {
  final String name;
  final String phone;
  final Address address;

  const Customer({
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'],
      phone: json['phone'],
      address: Address.fromJson(json['address']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address.toJson(),
    };
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? note;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.note,
  });

  double get totalPrice => quantity * price;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'note': note,
    };
  }
}

class Order {
  final String id;
  final OrderPlatform platform;
  final Customer customer;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderTime;
  final String? courierName;
  final String? courierPhone;
  final String? specialNote;
  final OrderType type;
  final OrderPriority priority;
  final DateTime? estimatedDeliveryTime;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryLocation;
  final String? deliveryDistrict;

  const Order({
    required this.id,
    required this.platform,
    required this.customer,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderTime,
    this.courierName,
    this.courierPhone,
    this.specialNote,
    this.type = OrderType.food,
    this.priority = OrderPriority.normal,
    this.estimatedDeliveryTime,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryLocation,
    this.deliveryDistrict,
  });

  String get platformDisplayName {
    switch (platform) {
      case OrderPlatform.trendyol:
        return 'Trendyol';
      case OrderPlatform.yemeksepeti:
        return 'Yemeksepeti';
      case OrderPlatform.getir:
        return 'Getir';
      case OrderPlatform.bitaksi:
        return 'BiTaksi';
      case OrderPlatform.manuel:
        return 'Manuel';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Kurye Bekliyor';
      case OrderStatus.assigned:
        return 'Kurye Atandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.ready:
        return 'Hazır';
      case OrderStatus.pickedUp:
        return 'Kurye Aldı';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  // Delivery convenience getters
  double get deliveryLat => deliveryLatitude ?? customer.address.latitude ?? 0.0;
  double get deliveryLng => deliveryLongitude ?? customer.address.longitude ?? 0.0;
  String get fullDeliveryLocation => deliveryLocation ?? customer.address.fullAddress;
  String get district => deliveryDistrict ?? customer.address.district;

  Order copyWith({
    String? id,
    OrderPlatform? platform,
    Customer? customer,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? orderTime,
    String? courierName,
    String? courierPhone,
    String? specialNote,
    OrderType? type,
    OrderPriority? priority,
    DateTime? estimatedDeliveryTime,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryLocation,
    String? deliveryDistrict,
  }) {
    return Order(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderTime: orderTime ?? this.orderTime,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      specialNote: specialNote ?? this.specialNote,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      deliveryDistrict: deliveryDistrict ?? this.deliveryDistrict,
    );
  }

  // JSON Serialization
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      platform: OrderPlatform.values.firstWhere(
        (e) => e.toString().split('.').last == json['platform'],
        orElse: () => OrderPlatform.manuel,
      ),
      customer: Customer.fromJson(json['customer']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      orderTime: DateTime.parse(json['orderTime']),
      courierName: json['courierName'],
      courierPhone: json['courierPhone'],
      specialNote: json['specialNote'],
      type: OrderType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => OrderType.food,
      ),
      priority: OrderPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => OrderPriority.normal,
      ),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null 
          ? DateTime.parse(json['estimatedDeliveryTime'])
          : null,
      deliveryLatitude: json['deliveryLatitude']?.toDouble(),
      deliveryLongitude: json['deliveryLongitude']?.toDouble(),
      deliveryLocation: json['deliveryLocation'],
      deliveryDistrict: json['deliveryDistrict'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.toString().split('.').last,
      'customer': customer.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'orderTime': orderTime.toIso8601String(),
      'courierName': courierName,
      'courierPhone': courierPhone,
      'specialNote': specialNote,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'deliveryLocation': deliveryLocation,
      'deliveryDistrict': deliveryDistrict,
    };
  }
}
