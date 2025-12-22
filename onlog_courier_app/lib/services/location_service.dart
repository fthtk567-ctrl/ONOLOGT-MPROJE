import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:onlog_shared/onlog_shared.dart'; // Order modeli

class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;
  static final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  
  // Persistent Timer sistemi
  static Timer? _locationUpdateTimer;
  static bool _isServiceRunning = false;
  static String? _activeCourierId;
  static bool _isDutyActive = false;
  
  // Konum stream'i
  static Stream<Position> get locationStream => _locationController.stream;
  
  // Son bilinen konum
  static Position? _lastKnownPosition;
  static Position? get lastKnownPosition => _lastKnownPosition;
  
  // Servis durumu
  static bool get isServiceRunning => _isServiceRunning;
  static bool get isDutyActive => _isDutyActive;
  
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
  
  /// Global persistent konum servisini başlat
  static Future<bool> startPersistentLocationService(String courierId) async {
    debugPrint('🚀 startPersistentLocationService çağırıldı - Kurye: $courierId');
    
    if (_isServiceRunning) {
      debugPrint('🔄 Konum servisi zaten çalışıyor - Kurye: $_activeCourierId');
      return true;
    }

    bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) { 
      debugPrint('❌ Konum izni yok - servis başlatılamadı');
      return false; 
    }

    _activeCourierId = courierId;
    _isServiceRunning = true;
    _isDutyActive = true;
    
    debugPrint('✅ Service değişkenleri set edildi - isRunning: $_isServiceRunning, isDutyActive: $_isDutyActive');

    // 30 saniyede bir konum güncelleme Timer'ı
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      debugPrint('⏰ Timer tetiklendi - ${DateTime.now().toString().substring(11, 19)}');
      await _performLocationUpdate();
    });

    debugPrint('✅ Timer başlatıldı - 30 saniyede bir çalışacak');

    // İlk konumu hemen al
    debugPrint('📍 İlk konum güncellenmesi başlatılıyor...');
    await _performLocationUpdate();

    debugPrint('🚀 Global konum servisi başlatıldı - Kurye: $courierId, isRunning: $_isServiceRunning, isDutyActive: $_isDutyActive');
    return true;
  }

  /// Konum güncelleme işlemini gerçekleştir
  static Future<void> _performLocationUpdate() async {
    if (!_isDutyActive || _activeCourierId == null) {
      debugPrint('⏸️ Mesai kapalı veya kurye ID yok - konum güncellenmedi');
      return;
    }

    try {
      debugPrint('📍 Konum alınıyor...');
      
      Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('⚠️ Konum alma timeout');
          throw TimeoutException('Konum alma zaman aşımı', const Duration(seconds: 20));
        },
      );

      _lastKnownPosition = position;
      _locationController.add(position);

      // Supabase'e güncelle
      await updateCourierLocation(_activeCourierId!, position);

      debugPrint('✅ Konum güncellendi: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (Accuracy: ${position.accuracy.toStringAsFixed(1)}m)');
      
    } catch (e) {
      debugPrint('❌ Konum güncelleme hatası: $e');
    }
  }

  /// Mesai durumunu değiştir (konum güncellemelerini durdurur/başlatır)
  static void setDutyStatus(bool isActive) {
    _isDutyActive = isActive;
    debugPrint('🔄 Mesai durumu değiştirildi: ${isActive ? "AKTİF" : "PASİF"} - Service running: $_isServiceRunning');
  }

  /// Sürekli konum takibi başlat (eski method - deprecated)
  static Future<bool> startLocationTracking() async {
    debugPrint('⚠️ startLocationTracking deprecated - startPersistentLocationService kullanın');
    return false;
  }
  
  /// Konum takibini durdur
  static void stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isServiceRunning = false;
    _isDutyActive = false;
    _activeCourierId = null;
    debugPrint('🛑 Global konum servisi durduruldu');
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
      debugPrint('📍 Kurye $courierId konumu güncelleniyor: ${position.latitude}, ${position.longitude}');
      
      // Supabase'e konum gönder - JSON formatında (Merchant panel bunu okuyor)
      await SupabaseService.client
        .from('users')
        .update({
          'current_location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', courierId);
      
      debugPrint('✅ Kurye konumu Supabase\'e kaydedildi');
    } catch (e) {
      debugPrint('❌ Kurye konum güncelleme hatası: $e');
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
  
  /// Servisi tamamen temizle (uygulama kapatılırken)
  static void dispose() {
    stopLocationTracking();
    if (!_locationController.isClosed) {
      _locationController.close();
    }
    debugPrint('🧹 LocationService tamamen temizlendi');
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




