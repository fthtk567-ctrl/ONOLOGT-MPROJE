import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Kullanıcı Servisi
/// User profil ve yönetim işlemleri
class SupabaseUserService {
  static final _supabase = Supabase.instance.client;

  // ============================================
  // KULLANICI SORGULAMA
  // ============================================

  /// Kullanıcı bilgilerini getir
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('❌ Kullanıcı getirme hatası: $e');
      return null;
    }
  }

  /// Email ile kullanıcı bul
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .select()
          .eq('email', email)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Email ile kullanıcı bulma hatası: $e');
      return null;
    }
  }

  /// Mevcut kullanıcıyı getir
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      return await getUser(user.id);
    } catch (e) {
      print('❌ Mevcut kullanıcı getirme hatası: $e');
      return null;
    }
  }

  /// Role göre kullanıcıları getir
  static Future<List<Map<String, dynamic>>> getUsersByRole({
    required String role, // 'merchant', 'courier', 'superAdmin'
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .select()
          .eq('role', role);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Role göre kullanıcı getirme hatası: $e');
      return [];
    }
  }

  /// Tüm kuryeleri getir
  static Future<List<Map<String, dynamic>>> getAvailableCouriers() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .select()
          .eq('role', 'courier')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Kurye listesi getirme hatası: $e');
      return [];
    }
  }

  // ============================================
  // KULLANICI GÜNCELLEME
  // ============================================

  /// Kullanıcı bilgilerini güncelle
  static Future<bool> updateUser({
    required String userId,
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    Map<String, dynamic>? businessLocation,
    String? bankAccountNumber,
    String? bankAccountName,
    String? bankName,
    double? commissionRate,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (businessName != null) updateData['business_name'] = businessName;
      if (businessPhone != null) updateData['business_phone'] = businessPhone;
      if (businessAddress != null) updateData['business_address'] = businessAddress;
      if (businessLocation != null) updateData['business_location'] = businessLocation;
      if (bankAccountNumber != null) updateData['bank_account_number'] = bankAccountNumber;
      if (bankAccountName != null) updateData['bank_account_name'] = bankAccountName;
      if (bankName != null) updateData['bank_name'] = bankName;
      if (commissionRate != null) updateData['commission_rate'] = commissionRate;
      if (isActive != null) updateData['is_active'] = isActive;

      await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .update(updateData)
          .eq('id', userId);

      print('✅ Kullanıcı güncellendi');
      return true;
    } catch (e) {
      print('❌ Kullanıcı güncelleme hatası: $e');
      return false;
    }
  }

  /// Kullanıcı aktiflik durumunu değiştir
  static Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('✅ Kullanıcı durumu güncellendi: $isActive');
      return true;
    } catch (e) {
      print('❌ Durum güncelleme hatası: $e');
      return false;
    }
  }

  // ============================================
  // KURYE İŞLEMLERİ
  // ============================================

  /// Kurye konum güncelle
  static Future<bool> updateCourierLocation({
    required String courierId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .update({
            'current_location': {
              'latitude': latitude,
              'longitude': longitude,
              'updated_at': DateTime.now().toIso8601String(),
            },
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', courierId);

      return true;
    } catch (e) {
      print('❌ Konum güncelleme hatası: $e');
      return false;
    }
  }

  /// Kurye müsaitlik durumu
  static Future<bool> updateCourierAvailability({
    required String courierId,
    required bool isAvailable,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', courierId);

      print('✅ Müsaitlik durumu: $isAvailable');
      return true;
    } catch (e) {
      print('❌ Müsaitlik güncelleme hatası: $e');
      return false;
    }
  }

  // ============================================
  // İSTATİSTİKLER
  // ============================================

  /// Kullanıcı istatistikleri
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final users = await _supabase
          .from(SupabaseConfig.TABLE_USERS)
          .select();

      int merchantCount = 0;
      int courierCount = 0;
      int adminCount = 0;
      int activeCount = 0;

      for (var user in users) {
        if (user['is_active'] == true) activeCount++;

        switch (user['role']) {
          case 'merchant':
            merchantCount++;
            break;
          case 'courier':
            courierCount++;
            break;
          case 'superAdmin':
            adminCount++;
            break;
        }
      }

      return {
        'total_users': users.length,
        'active_users': activeCount,
        'merchants': merchantCount,
        'couriers': courierCount,
        'admins': adminCount,
      };
    } catch (e) {
      print('❌ İstatistik hatası: $e');
      return {
        'total_users': 0,
        'active_users': 0,
        'merchants': 0,
        'couriers': 0,
        'admins': 0,
      };
    }
  }

  // ============================================
  // REALTIME STREAMS
  // ============================================

  /// Kullanıcı değişikliklerini dinle
  static Stream<Map<String, dynamic>> streamUser(String userId) {
    return _supabase
        .from(SupabaseConfig.TABLE_USERS)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((list) => list.isNotEmpty ? list.first : {});
  }

  /// Kuryeleri realtime dinle
  static Stream<List<Map<String, dynamic>>> streamCouriers() {
    return _supabase
        .from(SupabaseConfig.TABLE_USERS)
        .stream(primaryKey: ['id'])
        .map((list) => list.where((user) => 
          user['role'] == 'courier' && user['is_active'] == true).toList());
  }
}
