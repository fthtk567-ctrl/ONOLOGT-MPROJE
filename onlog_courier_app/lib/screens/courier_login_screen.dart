import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'courier_navigation_screen.dart';
import 'courier_type_selection_screen.dart';
import '../main.dart' show saveOneSignalPlayerId;
import '../services/battery_optimization_helper.dart';

class CourierLoginScreen extends StatefulWidget {
  const CourierLoginScreen({super.key});

  @override
  State<CourierLoginScreen> createState() => _CourierLoginScreenState();
}

class _CourierLoginScreenState extends State<CourierLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true; // Şifre gizli mi?

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo ve Marka Kimliği - KURYE İÇİN
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icons/app_icon_512.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Başlık
                const Text(
                  'ONLOG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kurye Uygulaması',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                    hintText: 'courier@onlog.com',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email gerekli';
                    if (!value!.contains('@')) return 'Geçerli bir email girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Şifre
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Şifre gerekli';
                    if (value!.length < 6) return 'Şifre en az 6 karakter olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Giriş butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Şifremi unuttum
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Şifre sıfırlama özelliği yakında eklenecek'),
                      ),
                    );
                  },
                  child: const Text(
                    'Şifremi Unuttum',
                    style: TextStyle(color: Color(0xFF4CAF50)),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Kayıt Ol bölümü
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Esnaf kurye misiniz?',
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
                            builder: (context) => const CourierTypeSelectionScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Başvuru Yap',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Bilgi notu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kurye hesabınızla giriş yapın',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔐 Kurye giriş başlatılıyor: ${_emailController.text.trim()}');

      // Supabase Authentication ile giriş
      final response = await SupabaseService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Giriş başarısız');
      }

      print('🔑 User ID: $userId');

      if (!mounted) return;

      // Supabase users tablosundan kurye bilgilerini al
      final userData = await SupabaseService.from('users')
          .select()
          .eq('id', userId)
          .single();

      print('📊 Kullanıcı verisi: $userData');

      final role = userData['role'] as String?;

      if (role != 'courier') {
        await SupabaseService.signOut();
        throw Exception('Kurye hesabı bulunamadı');
      }

      final courierName = userData['owner_name'] ?? 'Kurye';
      final isActive = userData['is_active'] as bool? ?? false;
      final status = userData['status'] as String? ?? 'pending';

      print('✅ Kurye bulundu: $courierName, Aktif: $isActive, Durum: $status');

      // Esnaf kurye onay kontrolü
      if (status == 'pending') {
        await SupabaseService.signOut();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Onay Bekleniyor'),
              content: const Text(
                'Başvurunuz inceleniyor. Yönetici onayladıktan sonra uygulamayı kullanabilirsiniz.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Reddedilmiş başvuru kontrolü
      if (status == 'rejected') {
        await SupabaseService.signOut();
        final reason = userData['rejection_reason'] ?? 'Bilgi verilmedi';
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Başvuru Reddedildi'),
              content: Text('Red nedeni: $reason'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Aktif kullanıcı kontrolü
      if (!isActive) {
        await SupabaseService.signOut();
        throw Exception('Hesabınız yönetici tarafından devre dışı bırakılmış');
      }

      // Son giriş zamanını güncelle
      await SupabaseService.from('users')
          .update({
            'last_login': DateTime.now().toIso8601String(),
            // NOT: is_available otomatik true yapılmıyor
            // Kullanıcı manuel olarak "Mesaiye Başla" butonuna basmalı
          })
          .eq('id', userId);

      print('✅ Son giriş zamanı güncellendi');

      // OneSignal Player ID'yi kaydet (Push Notification için!)
      try {
        await saveOneSignalPlayerId(userId);
        print('✅ OneSignal Player ID kaydedildi');
      } catch (e) {
        print('⚠️ OneSignal Player ID kaydetme hatası (devam ediliyor): $e');
      }

      print('✅ Ana ekrana yönlendiriliyor...');

      // Ana ekrana yönlendir
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CourierNavigationScreen(
              courierId: userId,
              courierName: courierName,
            ),
          ),
        );
        
        // Pil optimizasyonu dialogunu göster (ilk girişte)
        if (mounted) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            await BatteryOptimizationHelper.requestBatteryOptimizationDisable(context);
          }
        }
      }
    } catch (e) {
      print('❌ Giriş hatası: $e');
      
      String message = 'Giriş başarısız';
      
      if (e.toString().contains('Invalid login credentials')) {
        message = 'Email veya şifre hatalı';
      } else if (e.toString().contains('Email not confirmed')) {
        message = 'Email adresiniz onaylanmamış';
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
