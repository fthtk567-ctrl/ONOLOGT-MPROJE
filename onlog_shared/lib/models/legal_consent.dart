import 'legal_document.dart';

class LegalConsent {
  final String id;
  final String userId;
  final String documentId;
  final String documentVersion;
  final LegalDocumentType documentType;
  final DateTime consentDate;
  final String? ipAddress;
  final String? userAgent;
  final ConsentStatus status;
  final DateTime? withdrawnAt;
  final String? withdrawalReason;
  final Map<String, dynamic> metadata;

  const LegalConsent({
    required this.id,
    required this.userId,
    required this.documentId,
    required this.documentVersion,
    required this.documentType,
    required this.consentDate,
    this.ipAddress,
    this.userAgent,
    required this.status,
    this.withdrawnAt,
    this.withdrawalReason,
    required this.metadata,
  });

  factory LegalConsent.fromMap(Map<String, dynamic> map) {
    return LegalConsent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      documentId: map['documentId'] ?? '',
      documentVersion: map['documentVersion'] ?? '',
      documentType: LegalDocumentType.values.firstWhere(
        (e) => e.toString() == 'LegalDocumentType.${map['documentType']}',
        orElse: () => LegalDocumentType.other,
      ),
      consentDate: DateTime.fromMillisecondsSinceEpoch(map['consentDate']),
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      status: ConsentStatus.values.firstWhere(
        (e) => e.toString() == 'ConsentStatus.${map['status']}',
        orElse: () => ConsentStatus.given,
      ),
      withdrawnAt: map['withdrawnAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['withdrawnAt'])
          : null,
      withdrawalReason: map['withdrawalReason'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'documentId': documentId,
      'documentVersion': documentVersion,
      'documentType': documentType.toString().split('.').last,
      'consentDate': consentDate.millisecondsSinceEpoch,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'status': status.toString().split('.').last,
      'withdrawnAt': withdrawnAt?.millisecondsSinceEpoch,
      'withdrawalReason': withdrawalReason,
      'metadata': metadata,
    };
  }

  LegalConsent copyWith({
    String? id,
    String? userId,
    String? documentId,
    String? documentVersion,
    LegalDocumentType? documentType,
    DateTime? consentDate,
    String? ipAddress,
    String? userAgent,
    ConsentStatus? status,
    DateTime? withdrawnAt,
    String? withdrawalReason,
    Map<String, dynamic>? metadata,
  }) {
    return LegalConsent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      documentId: documentId ?? this.documentId,
      documentVersion: documentVersion ?? this.documentVersion,
      documentType: documentType ?? this.documentType,
      consentDate: consentDate ?? this.consentDate,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      status: status ?? this.status,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      withdrawalReason: withdrawalReason ?? this.withdrawalReason,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isActive => status == ConsentStatus.given;
  bool get isWithdrawn => status == ConsentStatus.withdrawn;
}

enum ConsentStatus {
  given,     // Onay verildi
  withdrawn, // Onay geri çekildi
  expired,   // Onay süresi doldu
  invalid,   // Geçersiz onay
}

extension ConsentStatusExtension on ConsentStatus {
  String get displayName {
    switch (this) {
      case ConsentStatus.given:
        return 'Onaylandı';
      case ConsentStatus.withdrawn:
        return 'Geri Çekildi';
      case ConsentStatus.expired:
        return 'Süresi Doldu';
      case ConsentStatus.invalid:
        return 'Geçersiz';
    }
  }
}

class LegalConsentSummary {
  final String userId;
  final List<LegalConsent> consents;
  final List<LegalDocument> pendingDocuments;
  final DateTime lastChecked;

  const LegalConsentSummary({
    required this.userId,
    required this.consents,
    required this.pendingDocuments,
    required this.lastChecked,
  });

  bool get hasAllRequiredConsents {
    final requiredTypes = LegalDocumentType.values.where((type) => type.isRequired);
    return requiredTypes.every((type) => hasConsentForType(type));
  }

  bool hasConsentForType(LegalDocumentType type) {
    return consents.any((consent) => 
        consent.documentType == type && 
        consent.isActive
    );
  }

  List<LegalDocument> get missingRequiredDocuments {
    final requiredTypes = LegalDocumentType.values.where((type) => type.isRequired);
    return pendingDocuments.where((doc) => 
        requiredTypes.contains(doc.type) && 
        !hasConsentForType(doc.type)
    ).toList();
  }
}