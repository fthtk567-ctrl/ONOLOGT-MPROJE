/// Trendyol Go Yemek API - Sipariş Modeli
/// Model 1 (STORE) - Kendi kuryemizle teslimat
class TrendyolOrderModel {
  final String id; // packageId - 64 karakter
  final int supplierId;
  final String storeId;
  final String? orderCode;
  final bool storePickupSelected; // true = Gel-Al sipariş
  final String orderId;
  final String orderNumber; // Müşteriye gösterilen numara
  final int packageCreationDate; // Epoch milliseconds
  final int packageModificationDate;
  final int preparationTime; // Dakika
  final double totalPrice;
  final String callCenterPhone;
  final String deliveryType; // "STORE" veya "GO"
  final TrendyolCustomer customer;
  final TrendyolAddress address;
  final String packageStatus; // Created, Picking, Invoiced, Shipped, Delivered, Cancelled, UnSupplied, Returned
  final List<TrendyolOrderLine> lines; // Sipariş içeriği
  final TrendyolPayment payment;
  final String? customerNote;
  final int lastModifiedDate;
  final bool isCourierNearby; // Model 2 için kurye yakınlık durumu
  final TrendyolCancelInfo? cancelInfo;
  final String? eta; // Tahmini teslimat süresi (örn: "32 - 47 dk")
  final bool testPackage; // Test siparişi mi?
  final String pickupEtaState; // "SUCCESS", "FAILED", ""
  final int estimatedPickupTimeMin; // Epoch milliseconds
  final int estimatedPickupTimeMax;

  TrendyolOrderModel({
    required this.id,
    required this.supplierId,
    required this.storeId,
    this.orderCode,
    required this.storePickupSelected,
    required this.orderId,
    required this.orderNumber,
    required this.packageCreationDate,
    required this.packageModificationDate,
    required this.preparationTime,
    required this.totalPrice,
    required this.callCenterPhone,
    required this.deliveryType,
    required this.customer,
    required this.address,
    required this.packageStatus,
    required this.lines,
    required this.payment,
    this.customerNote,
    required this.lastModifiedDate,
    required this.isCourierNearby,
    this.cancelInfo,
    this.eta,
    required this.testPackage,
    required this.pickupEtaState,
    required this.estimatedPickupTimeMin,
    required this.estimatedPickupTimeMax,
  });

  factory TrendyolOrderModel.fromJson(Map<String, dynamic> json) {
    return TrendyolOrderModel(
      id: json['id'] as String,
      supplierId: json['supplierId'] as int,
      storeId: json['storeId'].toString(),
      orderCode: json['orderCode'] as String?,
      storePickupSelected: json['storePickupSelected'] as bool? ?? false,
      orderId: json['orderId'].toString(),
      orderNumber: json['orderNumber'].toString(),
      packageCreationDate: json['packageCreationDate'] as int,
      packageModificationDate: json['packageModificationDate'] as int,
      preparationTime: json['preparationTime'] as int? ?? 0,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      callCenterPhone: json['callCenterPhone'] as String? ?? '',
      deliveryType: json['deliveryType'] as String,
      customer: TrendyolCustomer.fromJson(json['customer'] as Map<String, dynamic>),
      address: TrendyolAddress.fromJson(json['address'] as Map<String, dynamic>),
      packageStatus: json['packageStatus'] as String,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => TrendyolOrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      payment: TrendyolPayment.fromJson(json['payment'] as Map<String, dynamic>),
      customerNote: json['customerNote'] as String?,
      lastModifiedDate: json['lastModifiedDate'] as int,
      isCourierNearby: json['isCourierNearby'] as bool? ?? false,
      cancelInfo: json['cancelInfo'] != null
          ? TrendyolCancelInfo.fromJson(json['cancelInfo'] as Map<String, dynamic>)
          : null,
      eta: json['eta'] as String?,
      testPackage: json['testPackage'] as bool? ?? false,
      pickupEtaState: json['pickupEtaState'] as String? ?? '',
      estimatedPickupTimeMin: json['estimatedPickupTimeMin'] as int? ?? 0,
      estimatedPickupTimeMax: json['estimatedPickupTimeMax'] as int? ?? 0,
    );
  }

  /// Model 1 (STORE) mi kontrol et
  bool get isModel1 => deliveryType == 'STORE';

  /// Model 2 (GO) mi kontrol et
  bool get isModel2 => deliveryType == 'GO';

  /// Gel-Al siparişi mi?
  bool get isPickup => storePickupSelected;

  /// Müşteri konumu var mı? (Model 2'de olmayabilir)
  bool get hasCustomerLocation {
    if (isModel2) return false; // Model 2'de konum gizli
    return address.latitude != null &&
        address.longitude != null &&
        address.latitude != 'Trendyol Yemek' &&
        address.longitude != 'Trendyol Yemek';
  }

  /// Sipariş oluşturulma tarihi (DateTime)
  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(packageCreationDate);

  /// Son güncellenme tarihi (DateTime)
  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(lastModifiedDate);
}

/// Müşteri Bilgisi
class TrendyolCustomer {
  final int id;
  final String firstName;
  final String lastName;

  TrendyolCustomer({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory TrendyolCustomer.fromJson(Map<String, dynamic> json) {
    return TrendyolCustomer(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

/// Adres Bilgisi
class TrendyolAddress {
  final String firstName;
  final String lastName;
  final String? company;
  final String address1;
  final String address2;
  final String city;
  final int cityCode;
  final int cityId;
  final String district;
  final int districtId;
  final int neighborhoodId;
  final String neighborhood;
  final String apartmentNumber;
  final String floor;
  final String doorNumber;
  final String? addressDescription;
  final String postalCode;
  final String countryCode;
  final String? latitude; // Model 2'de "Trendyol Yemek" olabilir
  final String? longitude; // Model 2'de "Trendyol Yemek" olabilir
  final String phone; // Proxy numara

  TrendyolAddress({
    required this.firstName,
    required this.lastName,
    this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.cityCode,
    required this.cityId,
    required this.district,
    required this.districtId,
    required this.neighborhoodId,
    required this.neighborhood,
    required this.apartmentNumber,
    required this.floor,
    required this.doorNumber,
    this.addressDescription,
    required this.postalCode,
    required this.countryCode,
    this.latitude,
    this.longitude,
    required this.phone,
  });

  factory TrendyolAddress.fromJson(Map<String, dynamic> json) {
    return TrendyolAddress(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      company: json['company'] as String?,
      address1: json['address1'] as String? ?? '',
      address2: json['address2'] as String? ?? '',
      city: json['city'] as String? ?? '',
      cityCode: json['cityCode'] as int? ?? 0,
      cityId: json['cityId'] as int? ?? 0,
      district: json['district'] as String? ?? '',
      districtId: json['districtId'] as int? ?? 0,
      neighborhoodId: json['neighborhoodId'] as int? ?? 0,
      neighborhood: json['neighborhood'] as String? ?? '',
      apartmentNumber: json['apartmentNumber'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      doorNumber: json['doorNumber'] as String? ?? '',
      addressDescription: json['addressDescription'] as String?,
      postalCode: json['postalCode'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'TR',
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      phone: json['phone'] as String? ?? '',
    );
  }

  /// Tam adres metni
  String get fullAddress {
    final parts = <String>[
      if (address1.isNotEmpty) address1,
      if (address2.isNotEmpty) address2,
      if (apartmentNumber.isNotEmpty) 'No: $apartmentNumber',
      if (floor.isNotEmpty) 'Kat: $floor',
      if (doorNumber.isNotEmpty) 'Daire: $doorNumber',
      '$neighborhood, $district',
      city,
    ];
    return parts.join(', ');
  }

  /// Koordinat var mı? (Model 1 için)
  bool get hasCoordinates {
    return latitude != null &&
        longitude != null &&
        latitude != 'Trendyol Yemek' &&
        longitude != 'Trendyol Yemek';
  }

  /// Double koordinatlar (harita için)
  double? get lat {
    if (!hasCoordinates) return null;
    return double.tryParse(latitude!);
  }

  double? get lng {
    if (!hasCoordinates) return null;
    return double.tryParse(longitude!);
  }
}

/// Sipariş Satırı (Ürün)
class TrendyolOrderLine {
  final double price;
  final double unitSellingPrice;
  final int productId;
  final String name;
  final List<TrendyolOrderItem> items;
  final List<TrendyolModifierProduct> modifierProducts;
  final List<TrendyolIngredient> extraIngredients;
  final List<TrendyolIngredient> removedIngredients;

  TrendyolOrderLine({
    required this.price,
    required this.unitSellingPrice,
    required this.productId,
    required this.name,
    required this.items,
    required this.modifierProducts,
    required this.extraIngredients,
    required this.removedIngredients,
  });

  factory TrendyolOrderLine.fromJson(Map<String, dynamic> json) {
    return TrendyolOrderLine(
      price: (json['price'] as num).toDouble(),
      unitSellingPrice: (json['unitSellingPrice'] as num).toDouble(),
      productId: json['productId'] as int,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => TrendyolOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      modifierProducts: (json['modifierProducts'] as List<dynamic>? ?? [])
          .map((e) => TrendyolModifierProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      extraIngredients: (json['extraIngredients'] as List<dynamic>? ?? [])
          .map((e) => TrendyolIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      removedIngredients: (json['removedIngredients'] as List<dynamic>? ?? [])
          .map((e) => TrendyolIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Sipariş Item (Paket detayı)
class TrendyolOrderItem {
  final String packageItemId; // UnSupplied servisinde kullanılacak
  final int lineItemId;
  final bool isCancelled;
  final List<TrendyolPromotion> promotions;
  final TrendyolCoupon? coupon;

  TrendyolOrderItem({
    required this.packageItemId,
    required this.lineItemId,
    required this.isCancelled,
    required this.promotions,
    this.coupon,
  });

  factory TrendyolOrderItem.fromJson(Map<String, dynamic> json) {
    return TrendyolOrderItem(
      packageItemId: json['packageItemId'] as String,
      lineItemId: json['lineItemId'] as int,
      isCancelled: json['isCancelled'] as bool? ?? false,
      promotions: (json['promotions'] as List<dynamic>? ?? [])
          .map((e) => TrendyolPromotion.fromJson(e as Map<String, dynamic>))
          .toList(),
      coupon: json['coupon'] != null
          ? TrendyolCoupon.fromJson(json['coupon'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Promosyon
class TrendyolPromotion {
  final int promotionId;
  final String description;
  final String discountType;
  final double sellerCoverageRatio;
  final TrendyolAmount amount;

  TrendyolPromotion({
    required this.promotionId,
    required this.description,
    required this.discountType,
    required this.sellerCoverageRatio,
    required this.amount,
  });

  factory TrendyolPromotion.fromJson(Map<String, dynamic> json) {
    return TrendyolPromotion(
      promotionId: json['promotionId'] as int,
      description: json['description'] as String? ?? '',
      discountType: json['discountType'] as String? ?? '',
      sellerCoverageRatio: (json['sellerCoverageRatio'] as num?)?.toDouble() ?? 0.0,
      amount: TrendyolAmount.fromJson(json['amount'] as Map<String, dynamic>),
    );
  }
}

/// Kupon
class TrendyolCoupon {
  final String couponId;
  final String description;
  final double sellerCoverageRatio;
  final TrendyolAmount amount;

  TrendyolCoupon({
    required this.couponId,
    required this.description,
    required this.sellerCoverageRatio,
    required this.amount,
  });

  factory TrendyolCoupon.fromJson(Map<String, dynamic> json) {
    return TrendyolCoupon(
      couponId: json['couponId'] as String,
      description: json['description'] as String? ?? '',
      sellerCoverageRatio: (json['sellerCoverageRatio'] as num?)?.toDouble() ?? 0.0,
      amount: TrendyolAmount.fromJson(json['amount'] as Map<String, dynamic>),
    );
  }
}

/// İndirim Tutarı
class TrendyolAmount {
  final double seller;

  TrendyolAmount({required this.seller});

  factory TrendyolAmount.fromJson(Map<String, dynamic> json) {
    return TrendyolAmount(
      seller: (json['seller'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Modifier Product (Ekstra seçenekler)
class TrendyolModifierProduct {
  final String name;
  final double price;
  final int productId;
  final int modifierGroupId;
  final List<TrendyolModifierProduct> modifierProducts;
  final List<TrendyolIngredient> extraIngredients;
  final List<TrendyolIngredient> removedIngredients;

  TrendyolModifierProduct({
    required this.name,
    required this.price,
    required this.productId,
    required this.modifierGroupId,
    required this.modifierProducts,
    required this.extraIngredients,
    required this.removedIngredients,
  });

  factory TrendyolModifierProduct.fromJson(Map<String, dynamic> json) {
    return TrendyolModifierProduct(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      productId: json['productId'] as int,
      modifierGroupId: json['modifierGroupId'] as int,
      modifierProducts: (json['modifierProducts'] as List<dynamic>? ?? [])
          .map((e) => TrendyolModifierProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      extraIngredients: (json['extraIngredients'] as List<dynamic>? ?? [])
          .map((e) => TrendyolIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      removedIngredients: (json['removedIngredients'] as List<dynamic>? ?? [])
          .map((e) => TrendyolIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Malzeme (Ekstra/Çıkarılan)
class TrendyolIngredient {
  final int id;
  final String name;
  final double? price;

  TrendyolIngredient({
    required this.id,
    required this.name,
    this.price,
  });

  factory TrendyolIngredient.fromJson(Map<String, dynamic> json) {
    return TrendyolIngredient(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

/// Ödeme Bilgisi
class TrendyolPayment {
  final String paymentType; // PAY_WITH_CARD, PAY_WITH_MEAL_CARD, PAY_WITH_ON_DELIVERY
  final TrendyolMealCard? mealCard;
  final TrendyolOnDelivery? onDelivery;

  TrendyolPayment({
    required this.paymentType,
    this.mealCard,
    this.onDelivery,
  });

  factory TrendyolPayment.fromJson(Map<String, dynamic> json) {
    return TrendyolPayment(
      paymentType: json['paymentType'] as String,
      mealCard: json['mealCard'] != null
          ? TrendyolMealCard.fromJson(json['mealCard'] as Map<String, dynamic>)
          : null,
      onDelivery: json['onDelivery'] != null
          ? TrendyolOnDelivery.fromJson(json['onDelivery'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Ödeme tipi metni
  String get paymentTypeText {
    switch (paymentType) {
      case 'PAY_WITH_CARD':
        return 'Kredi Kartı (Online)';
      case 'PAY_WITH_MEAL_CARD':
        return 'Yemek Kartı (${mealCard?.cardSourceType ?? 'Bilinmeyen'})';
      case 'PAY_WITH_ON_DELIVERY':
        return 'Kapıda Ödeme (${onDelivery?.paymentTypeText ?? 'Bilinmeyen'})';
      default:
        return 'Bilinmeyen';
    }
  }
}

/// Yemek Kartı Bilgisi
class TrendyolMealCard {
  final String cardSourceType; // "PLUXEE - ONLINE", "MULTINET - ONLINE", etc.

  TrendyolMealCard({required this.cardSourceType});

  factory TrendyolMealCard.fromJson(Map<String, dynamic> json) {
    return TrendyolMealCard(
      cardSourceType: json['cardSourceType'] as String? ?? '',
    );
  }
}

/// Kapıda Ödeme Bilgisi
class TrendyolOnDelivery {
  final String paymentType; // CASH, CARD, SODEXO_CARD, etc.

  TrendyolOnDelivery({required this.paymentType});

  factory TrendyolOnDelivery.fromJson(Map<String, dynamic> json) {
    return TrendyolOnDelivery(
      paymentType: json['paymentType'] as String,
    );
  }

  String get paymentTypeText {
    switch (paymentType) {
      case 'CASH':
        return 'Nakit';
      case 'CARD':
        return 'Kredi Kartı';
      case 'SODEXO_CARD':
        return 'Pluxee Kart';
      case 'MULTINET_CARD':
        return 'Multinet Kart';
      case 'EDENRED_CARD':
        return 'Edenred Kart';
      default:
        return paymentType.replaceAll('_', ' ');
    }
  }
}

/// İptal Bilgisi
class TrendyolCancelInfo {
  final int reasonCode;

  TrendyolCancelInfo({required this.reasonCode});

  factory TrendyolCancelInfo.fromJson(Map<String, dynamic> json) {
    return TrendyolCancelInfo(
      reasonCode: json['reasonCode'] as int,
    );
  }

  /// İptal nedeni metni
  String get reasonText {
    switch (reasonCode) {
      case 621:
        return 'Tedarik problemi';
      case 622:
        return 'Mağaza kapalı';
      case 623:
        return 'Mağaza sipariş hazırlayamıyor';
      case 624:
        return 'Yüksek yoğunluk / Kurye yok';
      case 626:
        return 'Alan Dışı';
      case 627:
        return 'Sipariş karışıklığı';
      default:
        return 'Diğer ($reasonCode)';
    }
  }
}

/// API Response (Pagination)
class TrendyolOrderResponse {
  final int page;
  final int size;
  final int totalPages;
  final int totalCount;
  final List<TrendyolOrderModel> content;

  TrendyolOrderResponse({
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalCount,
    required this.content,
  });

  factory TrendyolOrderResponse.fromJson(Map<String, dynamic> json) {
    return TrendyolOrderResponse(
      page: json['page'] as int,
      size: json['size'] as int,
      totalPages: json['totalPages'] as int,
      totalCount: json['totalCount'] as int,
      content: (json['content'] as List<dynamic>)
          .map((e) => TrendyolOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasMore => page < totalPages - 1;
}
