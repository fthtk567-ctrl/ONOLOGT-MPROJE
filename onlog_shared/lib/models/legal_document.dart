class LegalDocument {
  final String id;
  final String title;
  final String content;
  final LegalDocumentType type;
  final String version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final bool isActive;
  final bool requiresAcceptance;
  final Map<String, dynamic> metadata;

  const LegalDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    required this.isActive,
    required this.requiresAcceptance,
    required this.metadata,
  });

  factory LegalDocument.fromMap(Map<String, dynamic> map) {
    return LegalDocument(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: LegalDocumentType.values.firstWhere(
        (e) => e.toString() == 'LegalDocumentType.${map['type']}',
        orElse: () => LegalDocumentType.other,
      ),
      version: map['version'] ?? '1.0',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      publishedAt: map['publishedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['publishedAt'])
          : null,
      isActive: map['isActive'] ?? false,
      requiresAcceptance: map['requiresAcceptance'] ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'version': version,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'publishedAt': publishedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
      'requiresAcceptance': requiresAcceptance,
      'metadata': metadata,
    };
  }

  LegalDocument copyWith({
    String? id,
    String? title,
    String? content,
    LegalDocumentType? type,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool? isActive,
    bool? requiresAcceptance,
    Map<String, dynamic>? metadata,
  }) {
    return LegalDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      isActive: isActive ?? this.isActive,
      requiresAcceptance: requiresAcceptance ?? this.requiresAcceptance,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum LegalDocumentType {
  kvkk,              // KVKK Aydınlatma Metni
  privacyPolicy,     // Gizlilik Politikası
  termsOfService,    // Hizmet Şartları
  userAgreement,     // Kullanıcı Sözleşmesi
  courierAgreement,  // Kurye Sözleşmesi
  merchantAgreement, // İşyeri Sözleşmesi
  cargoRegulation,   // Kargo Yönetmeliği
  deliveryTerms,     // Teslimat Koşulları
  refundPolicy,      // İade Politikası
  cookiePolicy,      // Çerez Politikası
  dataProcessing,    // Veri İşleme Politikası
  other,
}

extension LegalDocumentTypeExtension on LegalDocumentType {
  String get displayName {
    switch (this) {
      case LegalDocumentType.kvkk:
        return 'KVKK Aydınlatma Metni';
      case LegalDocumentType.privacyPolicy:
        return 'Gizlilik Politikası';
      case LegalDocumentType.termsOfService:
        return 'Hizmet Şartları';
      case LegalDocumentType.userAgreement:
        return 'Kullanıcı Sözleşmesi';
      case LegalDocumentType.courierAgreement:
        return 'Kurye Sözleşmesi';
      case LegalDocumentType.merchantAgreement:
        return 'İşyeri Sözleşmesi';
      case LegalDocumentType.cargoRegulation:
        return 'Kargo Yönetmeliği';
      case LegalDocumentType.deliveryTerms:
        return 'Teslimat Koşulları';
      case LegalDocumentType.refundPolicy:
        return 'İade Politikası';
      case LegalDocumentType.cookiePolicy:
        return 'Çerez Politikası';
      case LegalDocumentType.dataProcessing:
        return 'Veri İşleme Politikası';
      case LegalDocumentType.other:
        return 'Diğer';
    }
  }

  String get description {
    switch (this) {
      case LegalDocumentType.kvkk:
        return '6698 sayılı Kişisel Verilerin Korunması Kanunu gereği bilgilendirme';
      case LegalDocumentType.privacyPolicy:
        return 'Kullanıcı verilerinin nasıl toplandığı ve kullanıldığı';
      case LegalDocumentType.termsOfService:
        return 'Platform kullanım koşulları ve kuralları';
      case LegalDocumentType.userAgreement:
        return 'Kullanıcı ile platform arasındaki sözleşme';
      case LegalDocumentType.courierAgreement:
        return 'Kurye ile platform arasındaki iş sözleşmesi';
      case LegalDocumentType.merchantAgreement:
        return 'İşyeri ile platform arasındaki iş sözleşmesi';
      case LegalDocumentType.cargoRegulation:
        return 'Kargo ve kargoya aracılık hizmetleri yönetmeliği';
      case LegalDocumentType.deliveryTerms:
        return 'Teslimat süreçleri ve sorumluluklar';
      case LegalDocumentType.refundPolicy:
        return 'İade ve iptal koşulları';
      case LegalDocumentType.cookiePolicy:
        return 'Web sitesi çerez kullanım politikası';
      case LegalDocumentType.dataProcessing:
        return 'Kişisel veri işleme süreçleri';
      case LegalDocumentType.other:
        return 'Diğer yasal belgeler';
    }
  }

  bool get isRequired {
    switch (this) {
      case LegalDocumentType.kvkk:
      case LegalDocumentType.privacyPolicy:
      case LegalDocumentType.userAgreement:
      case LegalDocumentType.courierAgreement:
      case LegalDocumentType.merchantAgreement:
        return true;
      default:
        return false;
    }
  }
}