import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/merchant_fcm_service.dart';
import 'main_navigation_screen.dart';
import 'merchant_registration_screen.dart';

class MerchantLoginPage extends StatefulWidget {
  const MerchantLoginPage({super.key});

  @override
  State<MerchantLoginPage> createState() => _MerchantLoginPageState();
}

class _MerchantLoginPageState extends State<MerchantLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true; // Varsayılan olarak aktif
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Supabase Authentication ile giriş yap
      final response = await SupabaseService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = response.user!.id;

      // Supabase'den kullanıcı bilgilerini al
      final userResponse = await SupabaseService.from('users')
          .select()
          .eq('id', userId)
          .single();

      final userData = userResponse;
      final role = userData['role'] as String;
      
      // Merchant ya da işletme kategorilerinden biri olmalı (courier, admin değil!)
      final validRoles = [
        'merchant', // Genel merchant rolü
        'restaurant', 'market', 'cafe', 'bakery', 'grocery', 
        'hardware', 'pharmacy', 'butcher', 'florist', 'petshop', 
        'industrial', 'other'
      ];
      
      if (!validRoles.contains(role)) {
        await SupabaseService.signOut();
        throw Exception('Bu panele erişim yetkiniz yok. Sadece işletme sahipleri giriş yapabilir.');
      }

      // Başvuru durumu kontrolü
      final isActive = userData['is_active'] as bool? ?? false;
      final status = userData['status'] as String? ?? 'pending';

      if (status == 'pending') {
        await SupabaseService.signOut();
        throw Exception('Başvurunuz henüz onaylanmamış. Lütfen yönetici onayını bekleyin.');
      }

      if (status == 'rejected') {
        await SupabaseService.signOut();
        final reason = userData['rejection_reason'] ?? 'Belirtilmemiş';
        throw Exception('Başvurunuz reddedildi. Sebep: $reason');
      }

      if (!isActive) {
        await SupabaseService.signOut();
        throw Exception('Hesabınız yönetici tarafından kapatılmış. Lütfen yönetici ile iletişime geçin.');
      }

      // Son giriş zamanını güncelle
      await SupabaseService.from('users')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', userId);

      print('✅ Login başarılı - MainNavigationScreen\'e yönlendirilecek');
      
      // FCM Token'ı kaydet
      try {
        await MerchantFCMService.saveCurrentToken();
        print('🔔 FCM Token kaydedildi');
      } catch (e) {
        print('⚠️ FCM Token kaydetme hatası: $e');
      }

      // MainNavigationScreen'e yönlendir - eski tüm sayfaları temizle
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
        (route) => false, // Tüm eski route'ları temizle
      );
      
      print('🚀 Navigator.pushAndRemoveUntil çağrıldı');
    } on AuthException catch (e) {
      String message;
      switch (e.message) {
        case 'Invalid login credentials':
          message = 'E-posta veya şifre hatalı. Lütfen tekrar deneyin.';
          break;
        case 'Email not confirmed':
          message = 'E-posta adresiniz onaylanmamış.';
          break;
        default:
          message = 'Giriş yapılırken bir hata oluştu: ${e.message}';
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],  // BEYAZ ARKA PLAN!
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Yeşil ikon kutusu (telefondaki gibi)
                    Center(
                      child: Container(
                        width: 280,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.green[50],  // AÇIK YEŞİL ARKA PLAN
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.store,
                            size: 80,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ONLOG Başlık (YEŞİL)
                    const Text(
                      'ONLOG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),  // YEŞİL
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Alt başlık
                    Text(
                      'Satıcı Paneli',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Hata mesajı
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // E-posta
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        hintText: 'restoran@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta adresi gerekli';
                        }
                        if (!value.contains('@')) {
                          return 'Geçerli bir e-posta adresi girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Şifre
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre gerekli';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Beni Hatırla seçeneği
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                          activeColor: const Color(0xFF388E3C),
                        ),
                        const Text(
                          'Beni hatırla (30 gün)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Giriş butonu
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF388E3C),  // KOYU YEŞİL BUTON (telefondaki gibi)
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kayıt Ol bölümü
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Henüz hesabınız yok mu? ',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MerchantRegistrationScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'İşletme Olarak Kayıt Ol',
                            style: TextStyle(
                              color: Color(0xFF388E3C),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
