import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Supabase başlat
  await Supabase.initialize(
    url: 'https://ahlmkqrqzwypqwwwqwzj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFobG1rcXJxend5cHF3d3dxd3pqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzUxNDE5OTEsImV4cCI6MjA1MDcxNzk5MX0.Kv-r5a3lx6IzOhvAZ44P0EGk_oM0XnNsG8cJQ6h8Kf4',
  );

  final supabase = Supabase.instance.client;

  try {
    print('🔍 courier@onlog.com kullanıcısı aranıyor...');
    
    // Courier kullanıcısını bul
    final response = await supabase
        .from('users')
        .select()
        .eq('email', 'courier@onlog.com')
        .single();

    print('✅ Kullanıcı bulundu: ${response['owner_name']}');
    print('   ID: ${response['id']}');
    print('   is_available: ${response['is_available']}');
    
    // is_available'ı true yap
    await supabase
        .from('users')
        .update({'is_available': true})
        .eq('id', response['id']);

    print('✅ is_available = true olarak güncellendi!');
    
    // Kontrol et
    final check = await supabase
        .from('users')
        .select('is_available')
        .eq('id', response['id'])
        .single();
    
    print('✅ Kontrol: is_available = ${check['is_available']}');
    
  } catch (e) {
    print('❌ Hata: $e');
  }
}
