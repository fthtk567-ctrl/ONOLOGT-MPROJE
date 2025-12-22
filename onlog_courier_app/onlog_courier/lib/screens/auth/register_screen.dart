import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../courier/widgets/courier_splash_screen.dart';
import 'terms_and_conditions_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEmailRegister = true;
  bool _acceptTerms = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Kayıt işlemi
  void _register() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      setState(() {
        _isLoading = true;
      });

      try {
        // API çağrısı gibi bir gecikmeyi simüle ediyoruz
        await Future.delayed(const Duration(seconds: 2));
        
        // Gerçek uygulamada burada kayıt işlemi yapılacak
        // Şimdilik başarılı olduğunu varsayalım
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Başarıyla kaydolduktan sonra otomatik giriş yap
          final authService = AuthService();
          await authService.login(
            _emailPhoneController.text,
            _passwordController.text,
            name: _nameController.text,
          );

          // Ana sayfaya yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CourierSplashScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Hata mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kayıt olurken bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (!_acceptTerms) {
      // Kullanım şartlarını kabul etmesi gerektiğini hatırlat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanım şartlarını kabul edin'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                      size: 70,
                    ),
                    
                    const SizedBox(height: 30),
                    
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
                      'Yeni hesap oluştur',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Seçenekler (E-posta veya Telefon ile kayıt)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEmailRegister
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              foregroundColor: _isEmailRegister
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEmailRegister = true;
                              });
                            },
                            child: const Text('E-posta'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isEmailRegister
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              foregroundColor: !_isEmailRegister
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEmailRegister = false;
                              });
                            },
                            child: const Text('Telefon'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Ad Soyad alanı
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        hintText: 'Adınızı ve soyadınızı girin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı ve soyadınızı girin';
                        }
                        if (value.length < 3) {
                          return 'Adınız ve soyadınız en az 3 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // E-posta / Telefon alanı
                    TextFormField(
                      controller: _emailPhoneController,
                      keyboardType: _isEmailRegister
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      inputFormatters: !_isEmailRegister
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : null,
                      decoration: InputDecoration(
                        labelText: _isEmailRegister ? 'E-posta' : 'Telefon Numarası',
                        hintText: _isEmailRegister
                            ? 'ornek@mail.com'
                            : '5XX XXX XX XX',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          _isEmailRegister ? Icons.email : Icons.phone,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _isEmailRegister
                              ? 'Lütfen e-posta adresinizi girin'
                              : 'Lütfen telefon numaranızı girin';
                        }
                        
                        if (_isEmailRegister) {
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
                    
                    const SizedBox(height: 15),
                    
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
                    
                    // Şifre tekrar alanı
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Şifre Tekrar',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi tekrar girin';
                        }
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Kullanım şartları onayı
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              const Text('Kullanım şartlarını ve '),
                              GestureDetector(
                                onTap: () {
                                  // Kullanım şartları sayfasına yönlendir
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TermsAndConditionsScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Gizlilik Politikasını',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Text(' kabul ediyorum'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Kayıt butonu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
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
                              'Kayıt Ol',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Giriş yap
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Zaten hesabınız var mı?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Giriş Yap'),
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