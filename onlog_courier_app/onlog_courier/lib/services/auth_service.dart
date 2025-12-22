import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Kullanıcı kimlik doğrulama durumunu kontrol et
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Demo hesap bilgileri
  final Map<String, String> _demoAccounts = {
    'demo@onlog.com': 'demo123',
    'admin@onlog.com': 'admin123',
    'kurye@onlog.com': 'kurye123',
    '5551234567': '123456',
  };

  // Kullanıcıyı sisteme girmiş olarak işaretle
  Future<bool> login(String username, String password, {String? name}) async {
    // Demo hesapları kontrol et
    if (_demoAccounts.containsKey(username) && _demoAccounts[username] == password) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      await prefs.setString('name', name ?? 'Demo Kurye');
      return true;
    }
    
    // Gerçek API çağrısı burada yapılacak, şimdilik basit bir doğrulama
    if (username.isNotEmpty && password.length >= 6) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      if (name != null) {
        await prefs.setString('name', name);
      }
      return true;
    }
    return false;
  }

  // Kullanıcıyı sistemden çıkar
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  // Kullanıcı bilgilerini getir
  Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? '',
    };
  }
}