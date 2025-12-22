import 'dart:math';
import 'package:onlog_shared/onlog_shared.dart'; // Order modeli
// import 'order_service_new.dart'; // TODO: Gerekirse eklenecek

class CourierService {
  static bool isDemoMode = true; // Demo mode flag
  
  static final List<Map<String, dynamic>> _demoCouriers = [
    {
      'name': 'Ali Kaya',
      'phone': '+90 536 111 2222',
      'latitude': 40.9759, // Kadıköy yakını
      'longitude': 29.0276,
      'isAvailable': true,
      'rating': 4.8,
      'totalDeliveries': 245,
    },
    {
      'name': 'Mustafa Yıldız',
      'phone': '+90 538 777 8888',
      'latitude': 40.9605, // Maltepe yakını
      'longitude': 29.1264,
      'isAvailable': true,
      'rating': 4.6,
      'totalDeliveries': 189,
    },
    {
      'name': 'Emre Çelik',
      'phone': '+90 535 555 6666',
      'latitude': 40.9923, // Üsküdar yakını
      'longitude': 29.0200,
      'isAvailable': true,
      'rating': 4.9,
      'totalDeliveries': 312,
    },
    {
      'name': 'Burak Şahin',
      'phone': '+90 537 999 1111',
      'latitude': 40.9850, // Bostancı yakını
      'longitude': 29.1050,
      'isAvailable': false, // Meşgul
      'rating': 4.7,
      'totalDeliveries': 156,
    },
    {
      'name': 'Oğuz Demirci',
      'phone': '+90 534 222 3333',
      'latitude': 40.9695, // Kozyatağı yakını
      'longitude': 29.0850,
      'isAvailable': true,
      'rating': 4.5,
      'totalDeliveries': 203,
    },
  ];

  // Demo moduna göre kurye listesini getir
  static List<Map<String, dynamic>> get _couriers {
    if (isDemoMode) {
      return _demoCouriers;
    } else {
      // Canlı modda boş liste döndür (gerçek kuryeler API'den gelecek)
      return [];
    }
  }

  // Mevcut kuryeler listesi (geriye uyumluluk için)
  static List<Map<String, String>> getAvailableCouriers() {
    return _couriers
        .where((courier) => courier['isAvailable'] == true)
        .map((courier) => {
              'name': courier['name'] as String,
              'phone': courier['phone'] as String,
            })
        .toList();
  }

  // Detaylı kurye bilgileri
  static List<Map<String, dynamic>> getDetailedCouriers() {
    return _couriers.where((courier) => courier['isAvailable'] == true).toList();
  }

  // İki nokta arası mesafe hesaplama (Haversine formülü)
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // En yakın kurye bulma
  static Map<String, dynamic>? findNearestCourier(Order order) {
    // Sipariş adresinin koordinatları (örnek koordinatlar)
    double orderLat = _getOrderLatitude(order);
    double orderLon = _getOrderLongitude(order);

    List<Map<String, dynamic>> availableCouriers = getDetailedCouriers();
    
    if (availableCouriers.isEmpty) { return null; }

    Map<String, dynamic>? nearestCourier;
    double nearestDistance = double.infinity;

    for (var courier in availableCouriers) {
      double distance = calculateDistance(
        orderLat,
        orderLon,
        courier['latitude'],
        courier['longitude'],
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestCourier = {...courier, 'distance': distance};
      }
    }

    return nearestCourier;
  }

  // Sipariş konumuna göre koordinat döndürme (basit mapping)
  static double _getOrderLatitude(Order order) {
    String district = order.customer.address.district.toLowerCase();
    switch (district) {
      case 'kadıköy':
        return 40.9759;
      case 'maltepe':
        return 40.9605;
      case 'üsküdar':
        return 40.9923;
      case 'kozyatağı':
        return 40.9695;
      default:
        return 40.9759; // Varsayılan Kadıköy
    }
  }

  static double _getOrderLongitude(Order order) {
    String district = order.customer.address.district.toLowerCase();
    switch (district) {
      case 'kadıköy':
        return 29.0276;
      case 'maltepe':
        return 29.1264;
      case 'üsküdar':
        return 29.0200;
      case 'kozyatağı':
        return 29.0850;
      default:
        return 29.0276; // Varsayılan Kadıköy
    }
  }

  // Kurye durumunu güncelle
  static void setCourierAvailability(String courierName, bool isAvailable) {
    for (var courier in _couriers) {
      if (courier['name'] == courierName) {
        courier['isAvailable'] = isAvailable;
        break;
      }
    }
  }

  // En yakın 3 kurye getir (manuel seçim için)
  static List<Map<String, dynamic>> getNearestCouriers(Order order, {int limit = 3}) {
    double orderLat = _getOrderLatitude(order);
    double orderLon = _getOrderLongitude(order);

    List<Map<String, dynamic>> availableCouriers = getDetailedCouriers()
        .map((courier) => {
              ...courier,
              'distance': calculateDistance(
                orderLat,
                orderLon,
                courier['latitude'],
                courier['longitude'],
              ),
            })
        .toList();

    // Mesafeye göre sırala
    availableCouriers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return availableCouriers.take(limit).toList();
  }
}




