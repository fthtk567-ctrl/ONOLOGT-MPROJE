import 'package:flutter/foundation.dart';

/// Legal service for managing legal documents and user consents
/// This is a placeholder - actual implementation in supabase_legal_service.dart
class LegalService {
  Future<Map<String, dynamic>> getUserConsentSummary(String userId) async {
    debugPrint('⚠️ LegalService.getUserConsentSummary called (placeholder)');
    return {
      'totalRequired': 0,
      'totalAccepted': 0,
      'pendingDocuments': [],
    };
  }

  Future<List<Map<String, dynamic>>> getRequiredDocumentsForUserType(String userType) async {
    debugPrint('⚠️ LegalService.getRequiredDocumentsForUserType called (placeholder)');
    return [];
  }

  Future<void> saveConsent({
    required String userId,
    required String documentId,
    required bool accepted,
    String? ipAddress,
  }) async {
    debugPrint('⚠️ LegalService.saveConsent called (placeholder)');
  }
}
