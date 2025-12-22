import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userPhoneKey = 'user_phone';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  // Kullanıcının giriş yapıp yapmadığını kontrol et
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Kullanıcı giriş yap
  static Future<bool> login({
    required String phone,
    String? email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userPhoneKey, phone);
    if (email != null) { await prefs.setString(_userEmailKey, email); }
    if (name != null) { await prefs.setString(_userNameKey, name); }
    return true;
  }

  // Kullanıcı çıkış yap
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Kullanıcı bilgilerini al
  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'phone': prefs.getString(_userPhoneKey),
      'email': prefs.getString(_userEmailKey),
      'name': prefs.getString(_userNameKey),
    };
  }
}




