import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Test verisi oluşturma script'i
/// Kullanım: dart run lib/scripts/seed_data.dart
Future<void> main() async {
  print('🌱 Test verisi oluşturuluyor...');
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  final supabase = Supabase.instance.client;
  
  try {
    // 1. Test Restoranları
    print('🏪 Restoranlar oluşturuluyor...');
    await supabase.from('users').upsert([
      {
        'id': '11111111-1111-1111-1111-111111111111',
        'email': 'pizza@test.com',
        'role': 'merchant',
        'business_name': 'Pizza Palace',
        'owner_name': 'Ahmet Yılmaz',
        'phone': '+90 555 123 45 67',
        'is_active': true,
        'status': 'approved',
      },
      {
        'id': '22222222-2222-2222-2222-222222222222',
        'email': 'burger@test.com',
        'role': 'merchant',
        'business_name': 'Burger King Test',
        'owner_name': 'Mehmet Demir',
        'phone': '+90 555 234 56 78',
        'is_active': true,
        'status': 'approved',
      },
    ]);
    print('✅ 2 restoran oluşturuldu!');
    
    // 2. Test Kuryesi
    print('🚴 Kurye oluşturuluyor...');
    await supabase.from('users').upsert([
      {
        'id': '33333333-3333-3333-3333-333333333333',
        'email': 'kurye2@test.com',
        'role': 'courier',
        'owner_name': 'Ali Veli',
        'phone': '+90 555 345 67 89',
        'is_active': true,
        'status': 'approved',
      },
    ]);
    print('✅ 1 kurye oluşturuldu!');
    
    // 3. Test Siparişleri
    print('📦 Siparişler oluşturuluyor...');
    final now = DateTime.now();
    await supabase.from('orders').upsert([
      {
        'id': '44444444-4444-4444-4444-444444444444',
        'restaurant_id': '11111111-1111-1111-1111-111111111111',
        'courier_id': '7b6e981d-4d0a-4016-89fe-de184590226f',
        'customer_name': 'Zeynep Kaya',
        'customer_phone': '+90 555 111 22 33',
        'delivery_address': 'Kadıköy, İstanbul - Test Adres 1',
        'items': [
          {'name': 'Margarita Pizza', 'quantity': 2, 'price': 89.90}
        ],
        'subtotal_amount': 179.80,
        'delivery_fee': 20.00,
        'total_amount': 199.80,
        'status': 'on_the_way',
        'created_at': now.subtract(Duration(minutes: 30)).toIso8601String(),
      },
      {
        'id': '55555555-5555-5555-5555-555555555555',
        'restaurant_id': '22222222-2222-2222-2222-222222222222',
        'courier_id': '7b6e981d-4d0a-4016-89fe-de184590226f',
        'customer_name': 'Can Öztürk',
        'customer_phone': '+90 555 222 33 44',
        'delivery_address': 'Beşiktaş, İstanbul - Test Adres 2',
        'items': [
          {'name': 'Cheeseburger', 'quantity': 1, 'price': 65.00},
          {'name': 'Patates Kızartması', 'quantity': 1, 'price': 25.00}
        ],
        'subtotal_amount': 90.00,
        'delivery_fee': 15.00,
        'total_amount': 105.00,
        'status': 'preparing',
        'created_at': now.subtract(Duration(minutes: 15)).toIso8601String(),
      },
      {
        'id': '66666666-6666-6666-6666-666666666666',
        'restaurant_id': '11111111-1111-1111-1111-111111111111',
        'courier_id': '7b6e981d-4d0a-4016-89fe-de184590226f',
        'customer_name': 'Ayşe Yıldız',
        'customer_phone': '+90 555 333 44 55',
        'delivery_address': 'Şişli, İstanbul - Test Adres 3',
        'items': [
          {'name': 'Pepperoni Pizza', 'quantity': 1, 'price': 99.90}
        ],
        'subtotal_amount': 99.90,
        'delivery_fee': 20.00,
        'total_amount': 119.90,
        'status': 'delivered',
        'created_at': now.subtract(Duration(hours: 2)).toIso8601String(),
      },
    ]);
    print('✅ 3 sipariş oluşturuldu!');
    
    // 4. Mali İşlemler
    print('💰 Mali işlemler oluşturuluyor...');
    await supabase.from('financial_transactions').upsert([
      {
        'user_id': '11111111-1111-1111-1111-111111111111',
        'type': 'order_payment',
        'amount': 199.80,
        'description': 'Sipariş #44444444',
        'created_at': now.subtract(Duration(minutes: 30)).toIso8601String(),
      },
      {
        'user_id': '11111111-1111-1111-1111-111111111111',
        'type': 'order_payment',
        'amount': 119.90,
        'description': 'Sipariş #66666666',
        'created_at': now.subtract(Duration(hours: 2)).toIso8601String(),
      },
      {
        'user_id': '22222222-2222-2222-2222-222222222222',
        'type': 'order_payment',
        'amount': 105.00,
        'description': 'Sipariş #55555555',
        'created_at': now.subtract(Duration(minutes: 15)).toIso8601String(),
      },
    ]);
    print('✅ 3 mali işlem oluşturuldu!');
    
    print('\n🎉 TEST VERİSİ HAZIR!');
    print('📊 Özet:');
    print('   - 2 Restoran (Pizza Palace, Burger King)');
    print('   - 1 Ek Kurye (Ali Veli)');
    print('   - 3 Sipariş (Yolda, Hazırlanıyor, Teslim Edildi)');
    print('   - 3 Mali İşlem');
    
  } catch (e) {
    print('❌ HATA: $e');
  }
}
