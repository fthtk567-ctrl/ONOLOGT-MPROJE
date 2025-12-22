import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/merchant_integration_status.dart';

class SupabaseMerchantIntegrationService {
  static final _supabase = Supabase.instance.client;

  static Future<MerchantIntegrationStatus> getStatusForCurrentMerchant() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    return getStatusByMerchantId(user.id);
  }

  static Future<MerchantIntegrationStatus> getStatusByMerchantId(String merchantId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_ONLOG_MERCHANT_MAPPING)
          .select()
          .eq('onlog_merchant_id', merchantId)
          .order('updated_at', ascending: false)
          .maybeSingle();

      return MerchantIntegrationStatus.fromSupabaseRow(
        merchantId: merchantId,
        row: response,
      );
    } catch (e) {
      print('❌ Merchant integration status fetch error: $e');
      return MerchantIntegrationStatus.unlinked(merchantId: merchantId);
    }
  }

  static Stream<MerchantIntegrationStatus> streamStatus(String merchantId) {
    return _supabase
        .from(SupabaseConfig.TABLE_ONLOG_MERCHANT_MAPPING)
        .stream(primaryKey: ['id'])
        .eq('onlog_merchant_id', merchantId)
        .map((rows) {
          final row = rows.isEmpty ? null : rows.first;
          return MerchantIntegrationStatus.fromSupabaseRow(
            merchantId: merchantId,
            row: row,
          );
        });
  }

  // ============================================
  // ADMIN FONKSİYONLARI
  // ============================================

  /// Tüm bağlantı isteklerini getir (admin için)
  static Future<List<Map<String, dynamic>>> getAllMappings({
    bool? pendingOnly,
  }) async {
    try {
      print('🔍 getAllMappings çağrıldı - pendingOnly: $pendingOnly');
      
      var query = _supabase
          .from(SupabaseConfig.TABLE_ONLOG_MERCHANT_MAPPING)
          .select();

      if (pendingOnly == true) {
        query = query.eq('is_active', false);
        print('🔎 Sadece bekleyen kayıtlar filtrelendi (is_active = false)');
      }

      print('📡 Supabase sorgusu gönderiliyor...');
      final response = await query.order('created_at', ascending: false);

      print('✅ getAllMappings sonuç: ${response.length} kayıt');
      if (response.isNotEmpty) {
        print('📝 İlk kayıt: ${response[0]}');
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      print('❌ Admin mappings fetch error: $e');
      print('📤 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Bağlantıyı onayla (admin)
  static Future<bool> approveMerchantMapping(String mappingId) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_ONLOG_MERCHANT_MAPPING)
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mappingId);

      print('✅ Merchant mapping onaylandı: $mappingId');
      return true;
    } catch (e) {
      print('❌ Mapping onaylama hatası: $e');
      return false;
    }
  }

  /// Bağlantıyı reddet/pasif et (admin)
  static Future<bool> rejectMerchantMapping(String mappingId) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_ONLOG_MERCHANT_MAPPING)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mappingId);

      print('✅ Merchant mapping reddedildi: $mappingId');
      return true;
    } catch (e) {
      print('❌ Mapping reddetme hatası: $e');
      return false;
    }
  }

  /// Bağlantıyı tamamen sil (admin)
  static Future<bool> deleteMerchantMapping(String mappingId) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_ONLOG_MERCHANT_MAPPING)
          .delete()
          .eq('id', mappingId);

      print('✅ Merchant mapping silindi: $mappingId');
      return true;
    } catch (e) {
      print('❌ Mapping silme hatası: $e');
      return false;
    }
  }

  /// Bekleyen bağlantıları realtime dinle (admin)
  static Stream<List<Map<String, dynamic>>> streamPendingMappings() {
    return _supabase
        .from(SupabaseConfig.TABLE_ONLOG_MERCHANT_MAPPING)
        .stream(primaryKey: ['id'])
        .eq('is_active', false)
        .order('created_at', ascending: false);
  }
}
