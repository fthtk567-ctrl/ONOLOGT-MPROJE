import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:onlog_shared/onlog_shared.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;
  static final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  
  // Konum stream'i
  static Stream<Position> get locationStream => _locationController.stream;
  
  // Son bilinen konum
  static Position? _lastKnownPosition;
  static Position? get lastKnownPosition => _lastKnownPosition;
  
  /// Konum izinlerini kontrol et ve iste
  static Future<bool> checkAndRequestPermissions() async {
    // Uygulama seviyesinde izin kontrolü
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Konum izni reddedildi');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Konum izni kalıcı olarak reddedildi');
      return false;
    }
    
    // Sistem seviyesinde konum servisini kontrol et
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Konum servisleri kapalı');
      return false;
    }
    
    return true;
  }
  
  /// Mevcut konumu tek seferlik al
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) { return null; }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Konum alma hatası: $e');
      return null;
    }
  }
  
  /// Sürekli konum takibi başlat
  static Future<bool> startLocationTracking() async {
    try {
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) { return false; }
      
      // Eğer zaten tracking aktifse, durdur
      stopLocationTracking();
      
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 metre değişiklikle güncelle
        timeLimit: Duration(seconds: 30), // 30 saniye timeout
      );
      
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _locationController.add(position);
          debugPrint('Konum güncellendi: ${position.latitude}, ${position.longitude}');
        },
        onError: (error) {
          debugPrint('Konum tracking hatası: $error');
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Konum tracking başlatma hatası: $e');
      return false;
    }
  }
  
  /// Konum takibini durdur
  static void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    debugPrint('Konum tracking durduruldu');
  }
  
  /// İki konum arası mesafe hesapla (metre cinsinden)
  static double calculateDistanceInMeters(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  /// İki konum arası mesafe hesapla (kilometre cinsinden)
  static double calculateDistanceInKm(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return calculateDistanceInMeters(lat1, lon1, lat2, lon2) / 1000;
  }
  
  /// Kurye ile müşteri arası tahmini varış süresi (dakika)
  static int calculateEstimatedArrivalTime(
    double courierLat, double courierLon,
    double customerLat, double customerLon, {
    double averageSpeedKmh = 30, // Ortalama hız (km/saat)
  }) {
    double distanceKm = calculateDistanceInKm(
      courierLat, courierLon,
      customerLat, customerLon,
    );
    
    // Süre = Mesafe / Hız (saat cinsinden)
    double timeInHours = distanceKm / averageSpeedKmh;
    
    // Dakikaya çevir ve yuvarla
    int timeInMinutes = (timeInHours * 60).round();
    
    // Minimum 5 dakika
    return timeInMinutes < 5 ? 5 : timeInMinutes;
  }
  
  /// Kurye konumunu güncelle (Supabase'e gönder)
  static Future<void> updateCourierLocation(
    String courierId,
    Position position,
  ) async {
    try {
      // TODO: Supabase users.current_location güncelleme
      debugPrint('Kurye $courierId konumu güncellendi: ${position.latitude}, ${position.longitude}');
      
      // Şu anda local olarak saklıyoruz, gerçek uygulamada Supabase'e gönderilecek
      // await SupabaseService.client
      //   .from('users')
      //   .update({
      //     'current_location': {
      //       'latitude': position.latitude,
      //       'longitude': position.longitude,
      //       'timestamp': DateTime.now().toIso8601String(),
      //     }
      //   })
      //   .eq('id', courierId);
    } catch (e) {
      debugPrint('Kurye konum güncelleme hatası: $e');
    }
  }
  
  /// Sipariş konumuna göre koordinat getir (örnek implementasyon)
  static Map<String, double> getOrderCoordinates(Order order) {
    // Gerçek uygulamada bu veriler order içinde gelecek
    // Şimdilik örnek koordinatlar dönüyoruz
    
    // İstanbul bölgesi örnek koordinatları
    Map<String, Map<String, double>> sampleLocations = {
      'Kadıköy': {'lat': 40.9833, 'lng': 29.0333},
      'Beşiktaş': {'lat': 41.0422, 'lng': 29.0078},
      'Şişli': {'lat': 41.0602, 'lng': 28.9787},
      'Üsküdar': {'lat': 41.0214, 'lng': 29.0078},
      'Bakırköy': {'lat': 40.9763, 'lng': 28.8739},
      'Maltepe': {'lat': 40.9363, 'lng': 29.1372},
      'Ataşehir': {'lat': 40.9833, 'lng': 29.1167},
      'Pendik': {'lat': 40.8785, 'lng': 29.2333},
    };
    
    // Sipariş adresine göre koordinat bulmaya çalış
    String district = order.customer.address.district;
    
    if (sampleLocations.containsKey(district)) {
      var location = sampleLocations[district]!;
      return {
        'latitude': location['lat']!,
        'longitude': location['lng']!,
      };
    }
    
    // Varsayılan konum (Taksim)
    return {
      'latitude': 41.0370,
      'longitude': 28.9849,
    };
  }
  
  /// Adres string'ini koordinata çevir (Geocoding)
  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      // Bu özellik daha sonra implement edilecek
      // Şimdilik null dönüyor
      return null;
    } catch (e) {
      debugPrint('Adres koordinat çevirme hatası: $e');
      return null;
    }
  }
  
  /// Servisi temizle
  static void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}

// Kurye konum modeli
class CourierLocation {
  final String courierId;
  final String courierName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isActive;
  final String? orderId; // Hangi siparişi taşıyor
  
  const CourierLocation({
    required this.courierId,
    required this.courierName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isActive = true,
    this.orderId,
  });
  
  factory CourierLocation.fromJson(Map<String, dynamic> json) {
    return CourierLocation(
      courierId: json['courierId'],
      courierName: json['courierName'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      isActive: json['isActive'] ?? true,
      orderId: json['orderId'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'courierId': courierId,
      'courierName': courierName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
      'orderId': orderId,
    };
  }
  
  // Kuryenin müşteriye uzaklığını hesapla
  double distanceToCustomer(double customerLat, double customerLng) {
    return LocationService.calculateDistanceInKm(
      latitude, longitude,
      customerLat, customerLng,
    );
  }
  
  // Tahmini varış süresi
  int estimatedArrivalTime(double customerLat, double customerLng) {
    return LocationService.calculateEstimatedArrivalTime(
      latitude, longitude,
      customerLat, customerLng,
    );
  }
}




