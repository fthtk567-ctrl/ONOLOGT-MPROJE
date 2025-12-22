class MerchantIntegrationStatus {
  final String merchantId;
  final bool isLinked;
  final bool isActive;
  final String? yemekAppRestaurantId;
  final String? restaurantName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MerchantIntegrationStatus({
    required this.merchantId,
    required this.isLinked,
    required this.isActive,
    this.yemekAppRestaurantId,
    this.restaurantName,
    this.createdAt,
    this.updatedAt,
  });

  factory MerchantIntegrationStatus.unlinked({required String merchantId}) {
    return MerchantIntegrationStatus(
      merchantId: merchantId,
      isLinked: false,
      isActive: false,
    );
  }

  factory MerchantIntegrationStatus.fromSupabaseRow({
    required String merchantId,
    Map<String, dynamic>? row,
  }) {
    if (row == null) {
      return MerchantIntegrationStatus.unlinked(merchantId: merchantId);
    }

    return MerchantIntegrationStatus(
      merchantId: merchantId,
      isLinked: true,
      isActive: row['is_active'] == null ? false : row['is_active'] as bool,
      yemekAppRestaurantId: row['yemek_app_restaurant_id'] as String?,
      restaurantName: row['restaurant_name'] as String?,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String get statusLabel {
    if (!isLinked) return 'Bağlı Değil';
    return isActive ? 'Aktif' : 'Pasif';
  }

  bool get isPendingActivation => isLinked && !isActive;
}
