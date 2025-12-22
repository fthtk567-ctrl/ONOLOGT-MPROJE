import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/merchant_login_page.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'config/trendyol_config.dart';
import 'services/trendyol_api_service.dart';
import 'services/merchant_fcm_service.dart';

// Global initialization flag
bool _isAppInitialized = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hemen uygulamayı başlat (loading ekranı göster)
  runApp(
    ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const OnLogMerchantApp(),
      ),
    ),
  );
}

/// Trendyol API Credentials'ı başlat
void _initializeTrendyolApi() {
  if (TrendyolConfig.isConfigured) {
    TrendyolApiService().setCredentials(
      supplierId: TrendyolConfig.supplierId,
      apiKey: TrendyolConfig.apiKey,
      apiSecretKey: TrendyolConfig.apiSecretKey,
      entegratorName: TrendyolConfig.entegratorName,
    );
    // Production'da log gösterme
  }
}

class OnLogMerchantApp extends StatelessWidget {
  const OnLogMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ONLOG Satıcı Paneli',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(), // Oturum kontrolü wrapper'ı
          routes: {
            '/login': (context) => const MerchantLoginPage(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Oturum durumunu kontrol eder ve uygun sayfaya yönlendirir
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _loadingMessage = 'Uygulama başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Eğer daha önce başlatıldıysa HIZLI KONTROL
      if (_isAppInitialized) {
        setState(() => _loadingMessage = 'Oturum kontrol ediliyor...');
        await _checkAuthStatus();
        return;
      }

      // 1. Supabase'i initialize et (EN ÖNEMLI)
      setState(() => _loadingMessage = 'Bağlantı kuruluyor...');
      await SupabaseService.initialize();

      // 2. Firebase'i başlat (ARKAPLANDA, ASYNC)
      if (kIsWeb) {
        // Firebase'i beklemeden devam et
        Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBQwN-n2qxLIbOiyJn688LwuJteEd21rfE",
            authDomain: "onlog-push.firebaseapp.com",
            projectId: "onlog-push",
            storageBucket: "onlog-push.firebasestorage.app",
            messagingSenderId: "253730298253",
            appId: "1:253730298253:web:23fdb8667c67f9db1805c4",
            measurementId: "G-7WZ2M1JZPS",
          ),
        ).then((_) {
          MerchantFCMService.initialize();
        }).catchError((e) {
          // Sessizce handle et
        });
      }

      // 3. Trendyol API - hızlı
      _initializeTrendyolApi();

      // 4. Tarih formatı - arkaplanda
      initializeDateFormatting('tr_TR', null).catchError((e) {
        // Sessizce handle et
      });

      // Global flag'i ayarla
      _isAppInitialized = true;

      // 5. Auth durumunu kontrol et
      setState(() => _loadingMessage = 'Giriş kontrol ediliyor...');
      await _checkAuthStatus();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Uygulama başlatma hatası: $e');
      }
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Mevcut oturumu kontrol et
      final isValid = await SupabaseService.checkSessionValidity();
      final currentUser = SupabaseService.currentUser;
      
      if (isValid && currentUser != null) {
        // Kullanıcı bilgilerini kontrol et
        final userResponse = await SupabaseService.from('users')
            .select()
            .eq('id', currentUser.id)
            .single();
            
        final userData = userResponse;
        final isActive = userData['is_active'] as bool? ?? false;
        final status = userData['status'] as String? ?? 'pending';
        
        // Aktif ve onaylanmış hesap mı?
        if (isActive && status == 'approved') {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Sessizce handle et
    }
    
    // Oturum geçersiz veya hatalı
    setState(() {
      _isLoggedIn = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo - Merchant Panel için mağaza ikonu
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.store,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF4CAF50),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                _loadingMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      // Ana sayfaya git - import ekle
      return const MainNavigationScreen();
    }

    // Login sayfasına git
    return const MerchantLoginPage();
  }
}
