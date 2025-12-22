import 'package:onlog_shared/services/supabase_service.dart';
import 'package:onlog_shared/services/supabase_user_service.dart';

void main() async {
  print('🚀 Supabase başlatılıyor...');
  
  await SupabaseService.initialize();
  
  print('✅ Supabase bağlandı!');
  print('');
  print('🔍 courier@onlog.com kullanıcısı bulunuyor...');
  
  // Email ile kullanıcıyı bul
  final user = await SupabaseUserService.getUserByEmail('courier@onlog.com');
  
  if (user == null) {
    print('❌ Kullanıcı bulunamadı!');
    return;
  }
  
  final userId = user['id'] as String;
  final ownerName = user['owner_name'] as String?;
  final currentAvailable = user['is_available'] as bool? ?? false;
  
  print('✅ Kullanıcı bulundu!');
  print('   ID: $userId');
  print('   İsim: $ownerName');
  print('   Şu anki durum: ${currentAvailable ? "MÜSAİT ✅" : "MÜSAİT DEĞİL ❌"}');
  print('');
  print('🔧 is_available = TRUE yapılıyor...');
  
  // Müsaitliği true yap
  final success = await SupabaseUserService.updateCourierAvailability(
    courierId: userId,
    isAvailable: true,
  );
  
  if (success) {
    print('✅ BAŞARILI! Kurye artık müsait!');
    print('');
    
    // Doğrulama
    final check = await SupabaseUserService.getUser(userId);
    final newStatus = check?['is_available'] as bool? ?? false;
    
    print('🔍 Kontrol ediliyor...');
    print('   Yeni durum: ${newStatus ? "MÜSAİT ✅" : "MÜSAİT DEĞİL ❌"}');
    
    if (newStatus) {
      print('');
      print('🎉 SORUN ÇÖZÜLDÜ! Merchant panel artık kurye bulabilecek!');
    }
  } else {
    print('❌ HATA! Güncelleme başarısız!');
  }
}
