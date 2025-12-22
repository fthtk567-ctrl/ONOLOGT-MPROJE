import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Yasal Belgeler Servisi
/// Firebase LegalService'in Supabase versiyonu
class SupabaseLegalService {
  static final _supabase = Supabase.instance.client;

  // ============================================
  // YASAL BELGELER
  // ============================================

  /// Aktif yasal belgeleri getir
  static Future<List<Map<String, dynamic>>> getActiveDocuments() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_LEGAL_DOCUMENTS)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Yasal belge getirme hatası: $e');
      return [];
    }
  }

  /// Belirli tip için aktif belgeyi getir
  static Future<Map<String, dynamic>?> getDocumentByType(String type) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_LEGAL_DOCUMENTS)
          .select()
          .eq('document_type', type)
          .eq('is_active', true)
          .single();
      
      return response;
    } catch (e) {
      print('❌ Belge getirme hatası ($type): $e');
      return null;
    }
  }

  /// Yeni yasal belge oluştur
  static Future<Map<String, dynamic>?> createDocument({
    required String documentType,
    required String title,
    required String content,
    String version = '1.0',
    List<String>? requiredForRoles,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_LEGAL_DOCUMENTS)
          .insert({
            'document_type': documentType,
            'title': title,
            'content': content,
            'version': version,
            'required_for_roles': requiredForRoles ?? ['merchant', 'courier'],
            'is_active': true,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('❌ Belge oluşturma hatası: $e');
      return null;
    }
  }

  // ============================================
  // KULLANICI ONAYLARI
  // ============================================

  /// Kullanıcının onaylarını getir
  static Future<List<Map<String, dynamic>>> getUserConsents(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_USER_CONSENTS)
          .select('''
            *,
            document:legal_documents(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Kullanıcı onayları getirme hatası: $e');
      return [];
    }
  }

  /// Kullanıcı onayı kaydet
  static Future<bool> recordConsent({
    required String userId,
    required String documentId,
    bool consentGiven = true,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.TABLE_USER_CONSENTS).insert({
        'user_id': userId,
        'document_id': documentId,
        'consent_given': consentGiven,
        'consent_date': DateTime.now().toIso8601String(),
        'ip_address': ipAddress,
        'user_agent': userAgent,
      });
      
      print('✅ Kullanıcı onayı kaydedildi');
      return true;
    } catch (e) {
      print('❌ Onay kaydetme hatası: $e');
      return false;
    }
  }

  /// Kullanıcının tüm gerekli belgeleri onayladı mı?
  static Future<bool> hasAllRequiredConsents(String userId, String userRole) async {
    try {
      // Rol için gerekli belgeleri getir
      final requiredDocs = await _supabase
          .from(SupabaseConfig.TABLE_LEGAL_DOCUMENTS)
          .select()
          .contains('required_for_roles', [userRole])
          .eq('is_active', true);

      if (requiredDocs.isEmpty) return true;

      // Kullanıcının onaylarını getir
      final consents = await _supabase
          .from(SupabaseConfig.TABLE_USER_CONSENTS)
          .select('document_id, consent_given')
          .eq('user_id', userId)
          .eq('consent_given', true);

      final consentedDocIds = consents.map((c) => c['document_id']).toSet();

      // Tüm gerekli belgeler onaylanmış mı?
      for (var doc in requiredDocs) {
        if (!consentedDocIds.contains(doc['id'])) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Onay kontrolü hatası: $e');
      return false;
    }
  }

  // ============================================
  // YASAL BELGE YÖNETİMİ (Admin)
  // ============================================

  /// Belgeyi güncelle
  static Future<bool> updateDocument(String documentId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_LEGAL_DOCUMENTS)
          .update(updates)
          .eq('id', documentId);
      
      return true;
    } catch (e) {
      print('❌ Belge güncelleme hatası: $e');
      return false;
    }
  }

  /// Belgeyi devre dışı bırak
  static Future<bool> deactivateDocument(String documentId) async {
    return await updateDocument(documentId, {'is_active': false});
  }
}
