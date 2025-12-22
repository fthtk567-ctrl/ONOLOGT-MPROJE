import 'package:supabase_flutter/supabase_flutter.dart';

/// Test merchant kullanıcısı oluşturma scripti
void main() async {
  try {
    print('🚀 Supabase bağlantısı kuruluyor...');
    
    await Supabase.initialize(
      url: 'https://oilldfyywtzybrmpyixx.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZnl5d3R6eWJybXB5aXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk2MTMzMzUsImV4cCI6MjA0NTE4OTMzNX0.s7Lntz6_ACvWRr3K4f7QmVXYU4c8-k0ZfVTvXEbqBBA',
    );

    final supabase = Supabase.instance.client;
    print('✅ Supabase bağlantısı başarılı!');

    // Test merchant kullanıcısı oluştur
    print('\n📝 Test merchant kullanıcısı oluşturuluyor...');
    print('Email: merchant1@test.com');
    print('Password: merchant123');

    try {
      final authResponse = await supabase.auth.signUp(
        email: 'merchant1@test.com',
        password: 'merchant123',
      );

      if (authResponse.user == null) {
        print('❌ Kullanıcı oluşturulamadı!');
        return;
      }

      final userId = authResponse.user!.id;
      print('✅ Auth kullanıcısı oluşturuldu! ID: $userId');

      // Users tablosuna merchant bilgilerini ekle
      print('\n📊 Users tablosuna merchant bilgileri ekleniyor...');
      
      await supabase.from('users').insert({
        'id': userId,
        'email': 'merchant1@test.com',
        'role': 'restaurant',
        'businessName': 'Test Restaurant',
        'ownerName': 'Test Merchant',
        'phone': '+905551234567',
        'city': 'Istanbul',
        'district': 'Kadıköy',
        'address': 'Test Address, Kadıköy, Istanbul',
        'status': 'approved',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Merchant kullanıcısı başarıyla oluşturuldu!');
      print('\n🎉 Artık şu bilgilerle giriş yapabilirsiniz:');
      print('   Email: merchant1@test.com');
      print('   Password: merchant123');
      
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        print('⚠️  Bu kullanıcı zaten mevcut!');
        print('✅ Mevcut kullanıcı ile giriş yapabilirsiniz:');
        print('   Email: merchant1@test.com');
        print('   Password: merchant123');
      } else {
        print('❌ Auth hatası: ${e.message}');
      }
    }

  } catch (e) {
    print('❌ Hata: $e');
  }
}
