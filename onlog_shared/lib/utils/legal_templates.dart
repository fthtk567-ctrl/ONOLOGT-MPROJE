import '../models/legal_document.dart';

// Yasal belge şablonları ve varsayılan içerikler
class LegalTemplates {
  static const String kvkkTemplate = '''
KİŞİSEL VERİLERİN KORUNMASI KANUNU AYDINLATMA METNİ

Bu aydınlatma metni, 6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") kapsamında hazırlanmıştır.

VERİ SORUMLUSU
ONLOG Teknoloji A.Ş.
Adres: [Şirket Adresi]
Telefon: [Telefon Numarası]
E-posta: [E-posta Adresi]

İŞLENEN KİŞİSEL VERİLER
• Kimlik Bilgileri: Ad, soyad, T.C. kimlik numarası, doğum tarihi
• İletişim Bilgileri: Telefon numarası, e-posta adresi, adres bilgileri
• Lokasyon Bilgileri: GPS koordinatları, konum verileri
• Finansal Bilgiler: Banka hesap bilgileri, ödeme geçmişi
• Teknik Veriler: IP adresi, cihaz bilgileri, kullanım logları

VERİ İŞLEME AMAÇLARI
• Teslimat hizmetlerinin yürütülmesi
• Müşteri ilişkileri yönetimi
• Yasal yükümlülüklerin yerine getirilmesi
• Hizmet kalitesinin artırılması
• Güvenlik önlemlerinin alınması

VERİ İŞLEME HUKUKI SEBEPLERİ
• Sözleşmenin kurulması ve ifası
• Yasal yükümlülüklerin yerine getirilmesi
• Meşru menfaatler
• Açık rıza (gerekli durumlarda)

VERİ AKTARIM YERLERİ
• İş ortaklarımız (teslimat süreçleri için)
• Teknoloji sağlayıcıları (bulut hizmetleri)
• Yasal merciler (yasal zorunluluk halinde)

VERİ SAKLAMA SÜRESİ
Kişisel verileriniz, işleme amacının gerektirdiği süre kadar ve yasal saklama yükümlülüklerimiz çerçevesinde saklanmaktadır.

HAKLARINIZ
KVKK kapsamında sahip olduğunuz haklar:
• Kişisel verilerinizin işlenip işlenmediğini öğrenme
• İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme
• Yurt içinde/dışında aktarıldığı üçüncü kişileri bilme
• Eksik/yanlış işlenmiş kişisel verilerin düzeltilmesini isteme
• Yasal koşulların oluşması halinde silinmesini isteme
• Otomatik sistemlerle analiz edilmesi sonucu aleyhte sonuç doğması halinde itiraz etme
• Kanuna aykırı işlenmesi sebebiyle zarara uğramanız halinde zararın giderilmesini isteme

BAŞVURU YÖNTEMLERİ
Haklarınızı kullanmak için:
• E-posta: kvkk@onlog.com.tr
• Posta: [Şirket Adresi]
• Başvuru formu: [Web sitesi adresi]

Son güncelleme: [Tarih]
''';

  static const String privacyPolicyTemplate = '''
GİZLİLİK POLİTİKASI

ONLOG olarak kişisel bilgilerinizin gizliliğini korumayı taahhüt ediyoruz.

BİLGİ TOPLAMA
• Hesap oluştururken verdiğiniz bilgiler
• Uygulama kullanımı sırasında toplanan teknik veriler
• Lokasyon bilgileri (teslimat hizmetleri için)
• İletişim geçmişi ve müşteri destek kayıtları

BİLGİ KULLANIMI
Topladığımız bilgileri şu amaçlarla kullanırız:
• Hizmetlerimizi sağlamak ve geliştirmek
• Müşteri desteği sunmak
• Güvenlik önlemleri almak
• Yasal yükümlülükleri yerine getirmek

BİLGİ PAYLAŞIMI
Kişisel bilgilerinizi üçüncü taraflarla paylaşmayız, ancak şu durumlar istisnadır:
• Yasal zorunluluklar
• Hizmet sağlayıcıları (sınırlı amaçlarla)
• İş ortaklarımız (teslimat süreçleri için)

GÜVENLİK
Bilgilerinizi korumak için endüstri standardı güvenlik önlemleri kullanıyoruz:
• SSL şifrelemesi
• Güvenli veri merkezleri
• Erişim kontrolü
• Düzenli güvenlik denetimleri

ÇEREZLER
Web sitemizde kullanıcı deneyimini iyileştirmek için çerezler kullanıyoruz.

DEĞİŞİKLİKLER
Bu politikada yapılan değişiklikler web sitemizde yayımlanacaktır.

İLETİŞİM
Sorularınız için: privacy@onlog.com.tr
''';

  static const String termsOfServiceTemplate = '''
HİZMET ŞARTLARI

Bu şartlar ONLOG platform kullanımını düzenler.

TARAFLAR
• ONLOG Teknoloji A.Ş. (Platform Sağlayıcısı)
• Platform Kullanıcısı

HİZMET TANIMI
ONLOG, teslimat hizmetlerini kolaylaştıran bir teknoloji platformudur.

KULLANICI YÜKÜMLÜLÜKLER
• Doğru bilgi verme
• Platform kurallarına uyma
• Yasalara aykırı davranmama
• Diğer kullanıcıları rahatsız etmeme

PLATFORM SORUMLULUKLARI
• Hizmet kalitesini sağlama
• Kullanıcı verilerini koruma
• Teknik destek sunma
• Güvenli platform ortamı

ÖDEME KOŞULLARI
• Komisyon oranları
• Ödeme zamanları
• İade koşulları

SORUMLULUK SINIRLAMALARI
Platform, dolaylı zararlardan sorumlu değildir.

FESİH KOŞULLARI
• Kullanıcı istifa etme hakkı
• Platform fesih koşulları
• Veri silme işlemleri

UYGULANACAK HUKUK
Türkiye Cumhuriyeti hukuku uygulanır.

UYUŞMAZLIK ÇÖZÜMÜ
İstanbul mahkemeleri yetkilidir.
''';

  static const String courierAgreementTemplate = '''
KURYE SÖZLEŞMESİ

Bu sözleşme ONLOG platformu ile kurye arasında imzalanmıştır.

TARAFLAR
• ONLOG Teknoloji A.Ş.
• Kurye

ÇALIŞMA KOŞULLARI
• Esnek çalışma saatleri
• Kendi aracı ile çalışma
• Performans bazlı ücretlendirme

KURYE YÜKÜMLÜLÜKLERİ
• Teslimatları zamanında yapmak
• Müşterilere nazik davranmak
• Platform kurallarına uymak
• Kargo güvenliğini sağlamak
• Belgeli teslimat yapmak

PLATFORM YÜKÜMLÜLÜKLERİ
• Sipariş yönlendirmesi
• Ödeme güvencesi
• Teknik destek
• Eğitim desteği

ÜCRETLENDIRME
• Teslimat başına ücret
• Performans bonusları
• Haftalık ödeme
• Yakıt desteği

SİGORTA
• İş kazası sigortası
• Kasko desteği (belirli koşullarda)

SORUMLULUKLAR
• Kargo kaybı/hasarı
• Müşteri şikayetleri
• Trafik cezaları

FESİH KOŞULLARI
• 15 gün önceden bildirim
• Derhal fesih koşulları
• Veri silme prosedürü
''';

  static const String merchantAgreementTemplate = '''
İŞYERİ SÖZLEŞMESİ

Bu sözleşme ONLOG platformu ile işyeri arasında imzalanmıştır.

TARAFLAR
• ONLOG Teknoloji A.Ş.
• İşyeri

HİZMET KAPSAMI
• Teslimat hizmeti sağlama
• Müşteri yönetimi
• Ödeme kolaylığı
• Raporlama hizmetleri

İŞYERİ YÜKÜMLÜLÜKLERİ
• Doğru ürün bilgileri
• Zamanında hazırlık
• Kaliteli ambalajlama
• Kurye ile işbirliği

PLATFORM YÜKÜMLÜLÜKLERİ
• Kurye temin etme
• Ödeme güvencesi
• Müşteri desteği
• Teknoloji altyapısı

KOMİSYON ORANLARI
• Standart komisyon: %15
• Özel anlaşmalar
• Performans indirimleri

ÖDEME KOŞULLARI
• Haftalık ödeme
• Kesintiler
• Vergi düzenlemeleri

SORUMLULUKLAR
• Ürün kalitesi
• Müşteri memnuniyeti
• Hijyen kuralları

FESİH KOŞULLARI
• 30 gün önceden bildirim
• Derhal fesih durumları
• Kapanış işlemleri
''';

  static const String cargoRegulationTemplate = '''
KARGO YÖNETMELİĞİ BİLGİLENDİRMESİ

Bu bilgilendirme "Kargo ve Kargoya Aracılık Hizmetleri Yönetmeliği" kapsamında hazırlanmıştır.

GEÇERLİ MEVZUAT
• Posta Kanunu
• Kargo Yönetmeliği
• Tüketici Koruma Kanunu

HİZMET STANDARTLARI
• Teslimat süreleri
• Hasar/kayıp limitleri
• Sigorta kapsamı
• Müşteri bilgilendirme

KURYE SORUMLULUKLARI
• Kimlik doğrulama
• Teslimat belgeleri
• Hasar tespiti
• Güvenli taşıma

İŞYERİ SORUMLULUKLARI
• Ambalajlama
• Ürün beyanı
• Yasaklı maddeler
• Belgelendirme

MÜŞTERİ HAKLARI
• Teslimat garantisi
• Hasar tazminatı
• Şikayet hakkı
• İade hakkı

YASAKLI MADDELER
• Tehlikeli kimyasallar
• Yanıcı maddeler
• Patlayıcı maddeler
• Yasal olmayan ürünler

ŞİKAYET MEKANİZMASI
• İç şikayet sistemi
• BTK başvurusu
• Tüketici hakları
''';

  static const Map<LegalDocumentType, String> defaultContents = {
    LegalDocumentType.kvkk: kvkkTemplate,
    LegalDocumentType.privacyPolicy: privacyPolicyTemplate,
    LegalDocumentType.termsOfService: termsOfServiceTemplate,
    LegalDocumentType.courierAgreement: courierAgreementTemplate,
    LegalDocumentType.merchantAgreement: merchantAgreementTemplate,
    LegalDocumentType.cargoRegulation: cargoRegulationTemplate,
  };

  static String getDefaultContent(LegalDocumentType type) {
    return defaultContents[type] ?? 'Bu belge için henüz içerik oluşturulmamış.';
  }

  static String getDefaultTitle(LegalDocumentType type) {
    switch (type) {
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
        return 'Kargo Yönetmeliği Bilgilendirmesi';
      case LegalDocumentType.deliveryTerms:
        return 'Teslimat Koşulları';
      case LegalDocumentType.refundPolicy:
        return 'İade Politikası';
      case LegalDocumentType.cookiePolicy:
        return 'Çerez Politikası';
      case LegalDocumentType.dataProcessing:
        return 'Veri İşleme Politikası';
      default:
        return 'Yasal Belge';
    }
  }
}