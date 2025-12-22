import 'package:onlog_shared/onlog_shared.dart';
import '../models/trendyol_order_model.dart';

/// Trendyol siparişlerini ONLOG Order modeline çevirir
class TrendyolOrderConverter {
  /// TrendyolOrderModel -> Order dönüşümü
  static Order convertToOrder(TrendyolOrderModel trendyolOrder) {
    // Sipariş durumunu map et
    final status = _mapOrderStatus(trendyolOrder.packageStatus);
    
    // Sipariş ürünlerini dönüştür
    final items = trendyolOrder.lines.map((line) {
      return OrderItem(
        name: line.name,
        quantity: line.items.length, // items listesinin uzunluğu = adet
        price: line.price,
      );
    }).toList();
    
    // Müşteri bilgisi
    final trendyolAddr = trendyolOrder.address;
    final customer = Customer(
      name: '${trendyolAddr.firstName} ${trendyolAddr.lastName}',
      phone: trendyolAddr.phone,
      address: Address(
        fullAddress: _buildFullAddress(trendyolAddr),
        district: trendyolAddr.district,
        city: trendyolAddr.city,
        buildingNo: trendyolAddr.apartmentNumber,
        floor: trendyolAddr.floor,
        latitude: _parseCoordinate(trendyolAddr.latitude),
        longitude: _parseCoordinate(trendyolAddr.longitude),
      ),
    );
    
    // Toplam tutar
    final totalAmount = trendyolOrder.totalPrice;
    
    // Sipariş oluşturma zamanı (epoch milliseconds -> DateTime)
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      trendyolOrder.packageCreationDate,
    );
    
    return Order(
      id: trendyolOrder.orderNumber,
      platform: OrderPlatform.trendyol,
      status: status,
      customer: customer,
      items: items,
      totalAmount: totalAmount,
      orderTime: createdAt,
      courierName: null, // Henüz atanmadı
      specialNote: trendyolOrder.customerNote ?? '',
      deliveryLatitude: _parseCoordinate(trendyolAddr.latitude),
      deliveryLongitude: _parseCoordinate(trendyolAddr.longitude),
      deliveryLocation: _buildFullAddress(trendyolAddr),
      deliveryDistrict: trendyolAddr.district,
    );
  }
  
  /// Trendyol sipariş durumunu ONLOG durumuna çevir
  static OrderStatus _mapOrderStatus(String trendyolStatus) {
    switch (trendyolStatus.toUpperCase()) {
      case 'CREATED':
        return OrderStatus.pending;
      case 'PREPARING':
      case 'PICKING':
        return OrderStatus.preparing;
      case 'READY':
      case 'INVOICED':
        return OrderStatus.ready;
      case 'SHIPPED':
        return OrderStatus.pickedUp;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
      case 'UNSUPPLIED':
      case 'RETURNED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
  
  /// String koordinatı double'a çevir (Trendyol bazen "Trendyol Yemek" gibi text gönderebiliyor)
  static double? _parseCoordinate(String? coordinate) {
    if (coordinate == null || coordinate.isEmpty) return null;
    try {
      return double.parse(coordinate);
    } catch (e) {
      return null; // Parse edilemezse null dön
    }
  }
  
  /// Tam adresi oluştur
  static String _buildFullAddress(TrendyolAddress address) {
    final parts = <String>[];
    
    if (address.address1.isNotEmpty) parts.add(address.address1);
    if (address.address2.isNotEmpty) parts.add(address.address2);
    if (address.neighborhood.isNotEmpty) parts.add(address.neighborhood);
    if (address.district.isNotEmpty) parts.add(address.district);
    if (address.city.isNotEmpty) parts.add(address.city);
    if (address.postalCode.isNotEmpty) parts.add(address.postalCode);
    
    return parts.join(', ');
  }
  
  /// Birden fazla Trendyol siparişini dönüştür
  static List<Order> convertMultiple(List<TrendyolOrderModel> trendyolOrders) {
    return trendyolOrders.map((order) => convertToOrder(order)).toList();
  }
}
