import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../courier/widgets/courier_splash_screen.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'widgets/demo_accounts_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isEmailLogin = true;

  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Kimlik doğrulama servisi ile giriş
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = AuthService();
      final loginSuccessful = await authService.login(
        _emailPhoneController.text,
        _passwordController.text,
      );

      // Eğer beni hatırla seçeneği seçilmişse...
      if (_rememberMe) {
        // Kullanıcı bilgilerini kaydet
        // Gerçek uygulamada güvenli bir şekilde saklanmalı
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (loginSuccessful) {
          // Giriş başarılı - ana sayfaya yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CourierSplashScreen()),
          );
        } else {
          // Giriş başarısız - hata mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    const FlutterLogo(
                      size: 100,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Başlık
                    const Text(
                      'ONLOG Kurye',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Alt başlık
                    Text(
                      'Hesabınıza giriş yapın',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Seçenekler (E-posta veya Telefon ile giriş)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEmailLogin
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              foregroundColor: _isEmailLogin
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEmailLogin = true;
                              });
                            },
                            child: const Text('E-posta'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isEmailLogin
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              foregroundColor: !_isEmailLogin
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEmailLogin = false;
                              });
                            },
                            child: const Text('Telefon'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // E-posta / Telefon alanı
                    TextFormField(
                      controller: _emailPhoneController,
                      keyboardType: _isEmailLogin
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      inputFormatters: !_isEmailLogin
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : null,
                      decoration: InputDecoration(
                        labelText: _isEmailLogin ? 'E-posta' : 'Telefon Numarası',
                        hintText: _isEmailLogin
                            ? 'ornek@mail.com'
                            : '5XX XXX XX XX',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          _isEmailLogin ? Icons.email : Icons.phone,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _isEmailLogin
                              ? 'Lütfen e-posta adresinizi girin'
                              : 'Lütfen telefon numaranızı girin';
                        }
                        
                        if (_isEmailLogin) {
                          // Basit e-posta doğrulaması
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                        } else {
                          // Basit telefon numarası doğrulaması
                          if (value.length < 10) {
                            return 'Geçerli bir telefon numarası girin';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Şifre alanı
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi girin';
                        }
                        if (value.length < 6) {
                          return 'Şifreniz en az 6 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Beni hatırla & Şifremi unuttum
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Beni hatırla
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('Beni hatırla'),
                          ],
                        ),
                        
                        // Şifremi unuttum
                        TextButton(
                          onPressed: () {
                            // Şifre sıfırlama sayfasına yönlendir
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text('Şifremi unuttum'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Giriş butonu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Giriş Yap',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Demo Hesaplar Widget'ı
                    DemoAccountsWidget(
                      onSelect: (username, password) {
                        setState(() {
                          _emailPhoneController.text = username;
                          _passwordController.text = password;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Kayıt ol
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Hesabınız yok mu?'),
                        TextButton(
                          onPressed: () {
                            // Kayıt sayfasına yönlendir
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Kayıt Ol'),
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