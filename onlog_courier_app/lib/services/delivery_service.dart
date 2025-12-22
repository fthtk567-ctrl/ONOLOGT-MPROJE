import 'dart:math';
import 'package:onlog_shared/onlog_shared.dart';

// TODO: ManualDelivery modeli gerekli, onlog_shared'a eklenecek
// Şimdilik bu servis temel mesafe hesaplama fonksiyonları içeriyor

class DeliveryService {
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

  // Fiyat hesaplama (basit versiyon)
  static double calculatePrice({
    required double distance,
    required double weight,
    required VehicleType vehicleType,
  }) {
    double basePricePerKm = vehicleType == VehicleType.motorcycle ? 2.5 : 4.0;
    double weightMultiplier = vehicleType == VehicleType.motorcycle ? 1.2 : 0.8;
    const double minimumPrice = 15.0;
    const double fuelSurcharge = 1.15;

    double basePrice = distance * basePricePerKm;
    double weightSurcharge = weight * weightMultiplier;
    double totalPrice = (basePrice + weightSurcharge) * fuelSurcharge;

    return totalPrice < minimumPrice ? minimumPrice : totalPrice;
  }
}



