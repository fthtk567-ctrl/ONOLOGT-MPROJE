import 'dart:math';
import 'package:onlog_shared/services/supabase_service.dart';

/// Otomatik kurye atama servisi
/// Merchant'ın konumuna en yakın, online ve müsait kuryeleri bulur
class CourierAssignmentService {
  
  /// En uygun courier'ı otomatik seç
  /// 
  /// Öncelik sırası:
  /// 1. Aynı merchant'tan daha önce sipariş alan kurye (öncelik)
  /// 2. Online (is_available = true)
  /// 3. Aktif durumda (status = 'active')
  /// 4. Eli boş (is_busy = false)
  /// 5. 50 km yarıçap içinde (proximity filter)
  /// 6. En yakın mesafede (current_location)
  /// 7. En yüksek rating
  static Future<String?> findBestCourier({
    required Map<String, dynamic> merchantLocation,
    String? merchantId, // 🆕 Merchant ID ekledik
    String? source, // ⭐ YENİ - Platform kaynağı (yemek_app, trendyol, vs.)
    double maxDistanceKm = 50.0,
  }) async {
    try {
      print('🔍 OTOMATIK KURYE ARAMA BAŞLADI:');
      print('   Merchant Location: $merchantLocation');
      print('   Merchant ID: $merchantId');
      
      // 🆕 ADIM 0: Bu merchant'ın son siparişini kim teslim etti?
      String? lastCourierId;
      if (merchantId != null) {
        final lastOrder = await SupabaseService.client
            .from('delivery_requests')
            .select('courier_id')
            .eq('merchant_id', merchantId)
            .eq('status', 'delivered')
            .order('delivered_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (lastOrder != null) {
          lastCourierId = lastOrder['courier_id'] as String?;
          print('📦 Bu merchant\'ın son kurye: $lastCourierId');
          
          // Son kurye müsait mi kontrol et
          if (lastCourierId != null) {
            final courierCheck = await SupabaseService.client
                .from('users')
                .select('id, owner_name, is_available, is_busy')
                .eq('id', lastCourierId)
                .eq('is_active', true)
                .eq('status', 'approved')
                .maybeSingle();
            
            if (courierCheck != null && 
                courierCheck['is_available'] == true) {
              // ✅ Aynı kurye müsait! Öncelik ver
              print('✅ Aynı kurye müsait: ${courierCheck['owner_name']} (is_busy: ${courierCheck['is_busy']})');
              // Not: Meşgulse bile aynı merchant'a verebiliriz (tanıyor çünkü)
              return lastCourierId;
            }
          }
        }
      }
      
      // ADIM 1: Önce ELİ BOŞ kuryeleri dene
      var response = await SupabaseService.client
          .from('users')
          .select('id, owner_name, current_location, average_rating, total_ratings')
          .eq('role', 'courier')
          .eq('is_active', true) // ✅ Hesabı aktif olanlar
          .eq('is_available', true) // 🟢 Mesaide olan kuryeleri çek
          .eq('is_busy', false) // 🆕 ELİ BOŞ olanlar (paket taşımayan)
          .eq('status', 'approved') // ✅ 'approved' olmalı
          .order('average_rating', ascending: false); // Rating'e göre sırala
      
      // ADIM 2: Eğer eli boş kurye yoksa, MEŞGUL kuryelere bak
      if (response.isEmpty) {
        print('⚠️ Eli boş kurye yok! Meşgul kuryelere bakılıyor...');
        
        response = await SupabaseService.client
            .from('users')
            .select('id, owner_name, current_location, average_rating, total_ratings')
            .eq('role', 'courier')
            .eq('is_active', true)
            .eq('is_available', true)
            .eq('is_busy', true) // 🔴 MEŞGUL olanlar (zaten paket taşıyan)
            .eq('status', 'approved')
            .order('average_rating', ascending: false);
        
        if (response.isEmpty) {
          print('❌ Hiç müsait kurye yok!');
          print('⚠️ Not: Kuryelerin "Mesaiye Başla" butonuna basması gerekiyor!');
          return null;
        }
        
        print('⚠️ ${response.length} meşgul kurye bulundu (is_busy=true) - En yakınına atanacak');
      } else {
        print('✅ ${response.length} eli boş kurye bulundu (is_busy=false)');
      }
      
      // 🔴 FIX: Key isimleri 'lat' ve 'lng' (call_courier_screen'den gelen format)
      final merchantLat = (merchantLocation['lat'] as num?)?.toDouble();
      final merchantLon = (merchantLocation['lng'] as num?)?.toDouble();
      
      if (merchantLat == null || merchantLon == null) {
        // Konum yoksa en yüksek rating'li courier'ı seç
        print('⚠️ Merchant konumu yok, en yüksek rating\'li seçildi');
        return response.first['id'] as String;
      }
      
      // Her courier için mesafe hesapla
      List<Map<String, dynamic>> couriersWithDistance = [];
      
      for (var courier in response) {
        final courierLocation = courier['current_location'] as Map<String, dynamic>?;
        
        if (courierLocation != null) {
          final courierLat = (courierLocation['latitude'] as num?)?.toDouble();
          final courierLon = (courierLocation['longitude'] as num?)?.toDouble();
          
          if (courierLat != null && courierLon != null) {
            final distance = _calculateDistance(
              merchantLat, merchantLon,
              courierLat, courierLon,
            );
            
            // 🔥 YAKINLIK FİLTRESİ: Sadece 50 km içindekileri al
            if (distance <= maxDistanceKm) {
              couriersWithDistance.add({
                'id': courier['id'],
                'name': courier['owner_name'],
                'distance': distance,
                'rating': courier['average_rating'] ?? 0.0,
                'total_ratings': courier['total_ratings'] ?? 0,
              });
              
              print('   ✓ ${courier['owner_name']}: ${distance.toStringAsFixed(2)} km');
            } else {
              print('   ✗ ${courier['owner_name']}: ${distance.toStringAsFixed(2)} km (çok uzak)');
            }
          }
        }
      }
      
      if (couriersWithDistance.isEmpty) {
        // $maxDistanceKm km içinde kimse yok
        print('❌ $maxDistanceKm km içinde müsait kurye bulunamadı!');
        return null;
      }
      
      // SKORLAMA ALGORİTMASI:
      // Score = (1 / distance_km) * 0.7 + (rating / 5) * 0.3
      // Mesafe %70, Rating %30 önemli
      
      for (var courier in couriersWithDistance) {
        final distanceKm = courier['distance'] as double;
        final rating = courier['rating'] as double;
        
        // Mesafe skoru: Yakın olana yüksek puan (max 10 km için)
        final distanceScore = distanceKm > 0 ? (1 / distanceKm) : 10.0;
        
        // Rating skoru: 0-5 arası normalize et (0-1)
        final ratingScore = rating / 5.0;
        
        // Toplam skor
        final totalScore = (distanceScore * 0.7) + (ratingScore * 0.3);
        
        courier['score'] = totalScore;
      }
      
      // En yüksek skora göre sırala
      couriersWithDistance.sort((a, b) =>
        (b['score'] as double).compareTo(a['score'] as double)
      );
      
      final bestCourier = couriersWithDistance.first;
      
      print('🏆 EN UYGUN KURYE SEÇİLDİ:');
      print('   ID: ${bestCourier['id']}');
      print('   İsim: ${bestCourier['name']}');
      print('   Mesafe: ${bestCourier['distance'].toStringAsFixed(2)} km');
      print('   Rating: ${bestCourier['rating']} ⭐ (${bestCourier['total_ratings']} değerlendirme)');
      print('   Skor: ${bestCourier['score'].toStringAsFixed(4)}');
      
      return bestCourier['id'] as String;
      
    } catch (e) {
      print('❌ KURYE ARAMA HATASI: $e');
      return null;
    }
  }
  
  /// İki GPS koordinatı arasındaki mesafeyi hesapla (Haversine formula)
  /// Sonuç: kilometre
  static double _calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const R = 6371.0; // Dünya yarıçapı (km)
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }
  
  static double _toRadians(double degrees) => degrees * pi / 180.0;
  
  /// Mesafe kontrolü: Courier çok uzaksa uyarı
  static bool isCourierTooFar(double distanceKm, {double maxDistanceKm = 25.0}) {
    return distanceKm > maxDistanceKm;
  }
  
  /// Birden fazla online courier var mı kontrol et
  static Future<int> getAvailableCourierCount() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('role', 'courier')
          .eq('is_available', true)
          .eq('status', 'approved'); // ✅ 'approved' olmalı
      
      return response.length;
    } catch (e) {
      print('❌ Müsait kurye sayısı alınamadı: $e');
      return 0;
    }
  }
}
