import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'dart:typed_data';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // Oturum süresi ayarları - 30 gün boyunca açık kalsın
        autoRefreshToken: true, // Otomatik token yenileme
      ),
    );
    _client = Supabase.instance.client;
    print('✅ Supabase initialized successfully!');
  }
  
  // Auth helper methods
  static User? get currentUser => _client?.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  
  /// Oturum durumunu kontrol et ve gerekirse yenile
  static Future<bool> checkSessionValidity() async {
    try {
      final session = _client?.auth.currentSession;
      if (session == null) return false;
      
      // Token'ın geçerlilik süresini kontrol et
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final expiresAt = session.expiresAt ?? 0;
      
      print('🔐 Session expires at: ${DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)}');
      print('🔐 Current time: ${DateTime.now()}');
      
      // Eğer token 5 dakika içinde expire olacaksa yenile
      if (expiresAt - now < 300) { // 300 saniye = 5 dakika
        print('🔄 Token yakında expire olacak, yenileniyor...');
        await _client?.auth.refreshSession();
        return true;
      }
      
      return true;
    } catch (e) {
      print('❌ Session kontrol hatası: $e');
      return false;
    }
  }
  
  // Database helper methods
  static SupabaseQueryBuilder from(String table) => _client!.from(table);
  
  // Real-time subscriptions
  static RealtimeChannel channel(String channelName) => _client!.channel(channelName);
  
  // Auth methods
  static Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _client!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client!.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
  
  static Future<void> signOut() async {
    await _client!.auth.signOut();
  }
  
  // Storage methods
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
  }) async {
    await _client!.storage.from(bucket).uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return path;
  }
  
  static String getPublicUrl(String bucket, String path) {
    return _client!.storage.from(bucket).getPublicUrl(path);
  }
  
  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client!.storage.from(bucket).remove([path]);
  }
}