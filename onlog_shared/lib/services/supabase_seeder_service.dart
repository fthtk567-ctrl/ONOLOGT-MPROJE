import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'supabase_payment_service.dart';
import 'supabase_legal_service.dart';

/// Otomatik Test Verisi Servisi
/// Manuel SQL yerine kod ile veri oluşturma
class SupabaseSeederService {
  static final _supabase = Supabase.instance.client;

  // ============================================
  // ANA SEED FONKSİYONU
  // ============================================

  /// Tüm test verisini oluştur
  static Future<void> seedAll() async {
    print('🌱 Test verisi oluşturuluyor...');
    
    try {
      await seedLegalDocuments();
      await seedTestUsers();
      await seedTestRestaurants();
      await seedTestOrders();
      await seedCommissionConfig();
      await seedAppSettings();
      
      print('✅ Tüm test verisi oluşturuldu!');
    } catch (e) {
      print('❌ Seed hatası: $e');
    }
  }

  // ============================================
  // YASAL DÖKÜMANLAR
  // ============================================

  static Future<void> seedLegalDocuments() async {
    print('📄 Yasal dökümanlar oluşturuluyor...');

    final docs = [
      {
        'document_type': 'privacy_policy',
        'title': 'Gizlilik Politikası',
        'content': '''
# Gizlilik Politikası

ONLOG olarak kişisel verilerinizin güvenliğini önemsiyoruz.

## Toplanan Veriler
- Ad, soyad, e-posta
- Telefon numarası
- Teslimat adresi
- Konum bilgileri (kurye uygulaması)

## Kullanım Amaçları
- Sipariş yönetimi
- Teslimat hizmetleri
- İletişim

## Veri Güvenliği
Tüm verileriniz şifreli olarak saklanır.
        ''',
        'version': '1.0',
        'is_active': true,
        'required_for_roles': ['merchant', 'courier', 'customer'],
      },
      {
        'document_type': 'terms_of_service',
        'title': 'Kullanım Koşulları',
        'content': '''
# Kullanım Koşulları

ONLOG platformunu kullanarak aşağıdaki koşulları kabul etmiş olursunuz.

## Genel Kurallar
- Platform sadece yasal amaçlarla kullanılabilir
- Sahte bilgi girişi yasaktır
- Hesap güvenliği kullanıcının sorumluluğundadır

## Ödeme Koşulları
- Ödemeler güvenli ödeme sistemleri ile alınır
- İade politikası restoranlar tarafından belirlenir

## Sorumluluklar
Kullanıcılar girdiği bilgilerin doğruluğundan sorumludur.
        ''',
        'version': '1.0',
        'is_active': true,
        'required_for_roles': ['merchant', 'courier'],
      },
      {
        'document_type': 'kvkk',
        'title': 'KVKK Aydınlatma Metni',
        'content': '''
# KVKK Aydınlatma Metni

6698 sayılı Kişisel Verilerin Korunması Kanunu uyarınca:

## Veri Sorumlusu
ONLOG A.Ş.

## İşlenen Veriler
- Kimlik bilgileri
- İletişim bilgileri
- Konum verileri
- İşlem güvenliği verileri

## İşleme Amaçları
- Hizmet sunumu
- Yasal yükümlülükler
- Güvenlik

## Haklarınız
- Bilgi talep etme
- Düzeltme isteme
- Silme talep etme
        ''',
        'version': '1.0',
        'is_active': true,
        'required_for_roles': ['merchant', 'courier', 'customer'],
      },
    ];

    for (var doc in docs) {
      try {
        await SupabaseLegalService.createDocument(
          documentType: doc['document_type'] as String,
          title: doc['title'] as String,
          content: doc['content'] as String,
          version: doc['version'] as String,
          requiredForRoles: List<String>.from(doc['required_for_roles'] as List),
        );
      } catch (e) {
        print('⚠️ Döküman zaten var: ${doc['title']}');
      }
    }

    print('✅ Yasal dökümanlar hazır');
  }

  // ============================================
  // KULLANICILAR
  // ============================================

  static Future<void> seedTestUsers() async {
    print('👥 Test kullanıcıları oluşturuluyor...');

    final users = [
      {
        'email': 'admin@onlog.com',
        'role': 'superAdmin',
        'business_name': 'ONLOG Admin',
      },
      {
        'email': 'merchant1@test.com',
        'role': 'merchant',
        'business_name': 'Burger Palace',
        'business_phone': '05551234567',
        'business_address': 'Kadıköy, İstanbul',
      },
      {
        'email': 'merchant2@test.com',
        'role': 'merchant',
        'business_name': 'Pizza World',
        'business_phone': '05551234568',
        'business_address': 'Beşiktaş, İstanbul',
      },
      {
        'email': 'courier1@test.com',
        'role': 'courier',
        'business_name': 'Ahmet Kurye',
        'business_phone': '05551234569',
      },
      {
        'email': 'courier2@test.com',
        'role': 'courier',
        'business_name': 'Mehmet Kurye',
        'business_phone': '05551234570',
      },
    ];

    for (var user in users) {
      try {
        // Check if exists
        final existing = await _supabase
            .from(SupabaseConfig.TABLE_USERS)
            .select()
            .eq('email', user['email'] as String)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from(SupabaseConfig.TABLE_USERS).insert(user);
          print('✅ Kullanıcı oluşturuldu: ${user['email']}');
        } else {
          print('⚠️ Kullanıcı zaten var: ${user['email']}');
        }
      } catch (e) {
        print('❌ Kullanıcı oluşturma hatası: ${user['email']} - $e');
      }
    }
  }

  // ============================================
  // RESTORANLAR (Merchant Details)
  // ============================================

  static Future<void> seedTestRestaurants() async {
    print('🍔 Test restoranları oluşturuluyor...');

    // Get merchant IDs
    final merchants = await _supabase
        .from(SupabaseConfig.TABLE_USERS)
        .select()
        .eq('role', 'merchant');

    for (var merchant in merchants) {
      // Create wallet
      await SupabasePaymentService.getOrCreateWallet(merchant['id']);
      print('💰 Cüzdan oluşturuldu: ${merchant['business_name']}');
    }

    print('✅ Restoranlar hazır');
  }

  // ============================================
  // TEST SİPARİŞLERİ
  // ============================================

  static Future<void> seedTestOrders() async {
    print('📦 Test siparişleri oluşturuluyor...');

    // Get first merchant
    final merchant = await _supabase
        .from(SupabaseConfig.TABLE_USERS)
        .select()
        .eq('role', 'merchant')
        .limit(1)
        .maybeSingle();

    if (merchant == null) {
      print('⚠️ Merchant bulunamadı, sipariş oluşturulamadı');
      return;
    }

    // Get first courier
    final courier = await _supabase
        .from(SupabaseConfig.TABLE_USERS)
        .select()
        .eq('role', 'courier')
        .limit(1)
        .maybeSingle();

    final orders = [
      {
        'restaurant_id': merchant['id'],
        'courier_id': courier?['id'],
        'customer_name': 'Ali Yılmaz',
        'customer_phone': '05551111111',
        'delivery_address': 'Kadıköy Moda, İstanbul',
        'items': [
          {'name': 'Cheeseburger', 'quantity': 2, 'price': 45.0},
          {'name': 'Kola', 'quantity': 1, 'price': 15.0},
        ],
        'subtotal': 105.0,
        'delivery_fee': 15.0,
        'total_amount': 120.0,
        'status': 'pending',
        'payment_method': 'credit_card',
      },
      {
        'restaurant_id': merchant['id'],
        'courier_id': courier?['id'],
        'customer_name': 'Ayşe Demir',
        'customer_phone': '05552222222',
        'delivery_address': 'Beşiktaş, İstanbul',
        'items': [
          {'name': 'Pizza Margherita', 'quantity': 1, 'price': 85.0},
          {'name': 'Fanta', 'quantity': 2, 'price': 30.0},
        ],
        'subtotal': 115.0,
        'delivery_fee': 20.0,
        'total_amount': 135.0,
        'status': 'completed',
        'payment_method': 'cash',
      },
    ];

    for (var order in orders) {
      try {
        await _supabase.from(SupabaseConfig.TABLE_ORDERS).insert(order);
        print('✅ Sipariş oluşturuldu: ${order['customer_name']}');
      } catch (e) {
        print('❌ Sipariş oluşturma hatası: $e');
      }
    }
  }

  // ============================================
  // KOMİSYON AYARLARI
  // ============================================

  static Future<void> seedCommissionConfig() async {
    print('💵 Komisyon ayarları oluşturuluyor...');

    try {
      // Check if exists
      final existing = await _supabase
          .from(SupabaseConfig.TABLE_COMMISSION_CONFIGS)
          .select()
          .isFilter('merchant_id', null)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from(SupabaseConfig.TABLE_COMMISSION_CONFIGS).insert({
          'merchant_id': null, // Global config
          'commission_type': 'percentage',
          'commission_rate': 15.0,
          'min_commission': 5.0,
          'max_commission': null,
          'is_active': true,
        });
        print('✅ Global komisyon ayarı: 15%');
      }
    } catch (e) {
      print('❌ Komisyon ayarı hatası: $e');
    }
  }

  // ============================================
  // UYGULAMA AYARLARI
  // ============================================

  static Future<void> seedAppSettings() async {
    print('⚙️ Uygulama ayarları oluşturuluyor...');

    final settings = [
      {
        'setting_key': 'min_order_amount',
        'setting_value': '50',
        'description': 'Minimum sipariş tutarı (TL)',
        'category': 'orders',
      },
      {
        'setting_key': 'max_delivery_distance',
        'setting_value': '10',
        'description': 'Maksimum teslimat mesafesi (km)',
        'category': 'delivery',
      },
      {
        'setting_key': 'platform_fee_percentage',
        'setting_value': '15',
        'description': 'Platform komisyon oranı (%)',
        'category': 'finance',
      },
      {
        'setting_key': 'courier_base_fee',
        'setting_value': '25',
        'description': 'Kurye taban ücreti (TL)',
        'category': 'finance',
      },
    ];

    for (var setting in settings) {
      try {
        final existing = await _supabase
            .from(SupabaseConfig.TABLE_APP_SETTINGS)
            .select()
            .eq('setting_key', setting['setting_key'] as String)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from(SupabaseConfig.TABLE_APP_SETTINGS).insert(setting);
          print('✅ Ayar: ${setting['setting_key']}');
        }
      } catch (e) {
        print('❌ Ayar hatası: ${setting['setting_key']} - $e');
      }
    }
  }
}
