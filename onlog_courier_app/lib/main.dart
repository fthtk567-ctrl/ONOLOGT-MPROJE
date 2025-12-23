import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'screens/courier_login_screen.dart';
import 'screens/courier_navigation_screen.dart';
import 'services/cache_service.dart';
import 'services/location_service.dart';
import 'theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. OneSignal başlat
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("8e0048f9-329e-49e3-ac4a-acb8e10a34ab");
  
  // ARKA PLAN BİLDİRİMLERİ için handler (iOS için ZORUNLU!)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    debugPrint('🔔 Bildirim geldi (foreground): ${event.notification.title}');
    event.preventDefault(); // Uygulamada gösterme, sistem göstersin
    event.notification.display();
  });
  
  OneSignal.Notifications.addClickListener((event) {
    debugPrint('👆 Bildirime tıklandı: ${event.notification.additionalData}');
    // TODO: Sipariş detay sayfasına git
  });
  
  OneSignal.Notifications.requestPermission(true);
  debugPrint('✅ OneSignal başlatıldı');
  
  // 2. Supabase başlat
  await SupabaseService.initialize();
  debugPrint('✅ Courier App - Supabase başlatıldı');
  
  // 3. Cache servisi DEVRE DIŞI (crash sorunu için geçici)
  // try {
  //   await CacheService().initialize().timeout(
  //     const Duration(seconds: 3),
  //     onTimeout: () {
  //       debugPrint('⚠️ Cache servisi timeout - atlanıyor');
  //       return;
  //     },
  //   );
  //   debugPrint('✅ Cache servisi başlatıldı');
  // } catch (e) {
  //   debugPrint('⚠️ Cache servisi hatası (atlandı): $e');
  // }
  debugPrint('⚠️ Cache servisi devre dışı (test için)');
  
  runApp(const OnLogCourierApp());
}

// OneSignal Player ID'yi al ve Supabase'e kaydet
Future<void> saveOneSignalPlayerId(String userId) async {
  try {
    final deviceState = await OneSignal.User.getOnesignalId();
    
    if (deviceState != null) {
      debugPrint('📱 OneSignal Player ID alındı: $deviceState');
      
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      
      // ÖNCEKİ KAYITLARI SİL (eski Player ID'leri temizle)
      await SupabaseService.client
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('platform', platform);
      
      debugPrint('🗑️ Eski Player ID temizlendi');
      
      // YENİ Player ID'yi kaydet
      await SupabaseService.client.from('push_tokens').insert({
        'user_id': userId,
        'player_id': deviceState,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ OneSignal Player ID Supabase\'e kaydedildi');
    }
  } catch (e) {
    debugPrint('❌ OneSignal Player ID kaydetme hatası: $e');
  }
}

class OnLogCourierApp extends StatefulWidget {
  const OnLogCourierApp({super.key});

  @override
  State<OnLogCourierApp> createState() => _OnLogCourierAppState();
}

class _OnLogCourierAppState extends State<OnLogCourierApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// � APP LIFECYCLE DEĞİŞİNCE
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('📱 App State: $state');
    
    if (state == AppLifecycleState.detached) {
      // App KAPATILIYOR → Sadece servisleri temizle
      debugPrint('🛑 Global konum servisi durduruldu');
      LocationService.dispose(); // Global konum servisini temizle
      // NOT: Kullanıcı online kalır, manuel "Mesaiyi Bitir" ile offline olur
    } else if (state == AppLifecycleState.paused) {
      // App arka plana alındı (Home tuşu) → Mesai devam ediyor
      debugPrint('⏸️ App arka plana alındı - Mesai devam ediyor');
    } else if (state == AppLifecycleState.resumed) {
      // App ön plana geldi
      debugPrint('▶️ App ön plana geldi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONLOG Kurye',
      theme: AppTheme.lightTheme, // 🎨 Modern tema
      home: _buildInitialScreen(), // Auto-login kontrolü
      debugShowCheckedModeBanner: false,
    );
  }
  
  /// 🔐 AUTO-LOGIN: Supabase oturumu varsa direkt ana sayfaya git
  Widget _buildInitialScreen() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _checkExistingSession(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Oturum var mı?
        final sessionData = snapshot.data;
        
        if (sessionData != null) {
          debugPrint('✅ Mevcut oturum bulundu, ana sayfaya yönlendiriliyor');
          return CourierNavigationScreen(
            courierId: sessionData['id'],
            courierName: sessionData['name'],
          );
        } else {
          debugPrint('⚠️ Oturum yok, login ekranına yönlendiriliyor');
          return const CourierLoginScreen();
        }
      },
    );
  }
  
  /// Mevcut Supabase oturumunu kontrol et
  Future<Map<String, dynamic>?> _checkExistingSession() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        return null;
      }
      
      // Kullanıcı bilgilerini de kontrol et
      final user = SupabaseService.currentUser;
      if (user == null) {
        return null;
      }
      
      // Kullanıcının role'ünü kontrol et
      final userData = await SupabaseService.client
          .from('users')
          .select('id, email, role, is_active, status, full_name')
          .eq('id', user.id)
          .single();
      
      if (userData['role'] != 'courier') {
        await SupabaseService.client.auth.signOut();
        return null;
      }
      
      // 🔔 OneSignal Player ID kaydet (her başlangıçta)
      await saveOneSignalPlayerId(user.id);
      
      if (userData['status'] != 'approved' || userData['is_active'] != true) {
        await SupabaseService.client.auth.signOut();
        return null;
      }
      
      debugPrint('✅ Geçerli oturum bulundu: ${user.email}');
      
      return {
        'id': userData['id'],
        'name': userData['full_name'] ?? userData['email'] ?? 'Kurye',
      };
      
    } catch (e) {
      debugPrint('❌ Oturum kontrol hatası: $e');
      return null;
    }
  }
}
