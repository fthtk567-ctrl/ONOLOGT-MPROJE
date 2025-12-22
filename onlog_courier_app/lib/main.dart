import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:onlog_shared/services/supabase_fcm_service.dart';
import 'screens/courier_login_screen.dart';
import 'screens/courier_navigation_screen.dart';
import 'services/cache_service.dart';
import 'services/location_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Arka plan mesaj handler (TOP-LEVEL FUNCTION OLMALI!)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 ARKA PLAN BİLDİRİMİ ALINDI: ${message.notification?.title ?? message.data['title']}');
  
  // NOT: FCM zaten otomatik bildirim gösteriyor!
  // Lokal bildirim göstermeye gerek yok, yoksa 2 bildirim gelir!
  // await _showLocalNotification(message); // KALDIRILDI!
  
  print('✅ Arka plan bildirimi işlendi (FCM otomatik gösterecek)');
}

// Local notification gösterme fonksiyonu
Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'new_order_channel',
    'Yeni Siparişler',
    channelDescription: 'Yeni sipariş bildirimleri',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    ticker: 'ONLOG Bildirim',
    icon: 'ic_stat_courier_app_icon', // ONLOG özel bildirim ikonu (status bar için)
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // Data-only message için title/body data içinde
  final title = message.notification?.title ?? message.data['title'] ?? 'ONLOG';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    notificationDetails,
    payload: message.data['deliveryId'] ?? message.data['order_id'],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Firebase başlat (sadece FCM için!)
    await Firebase.initializeApp();
    debugPrint('✅ Firebase (FCM) başlatıldı');
  } catch (e) {
    debugPrint('⚠️ Firebase başlatma hatası: $e');
  }
  
  // 2. Supabase başlat
  await SupabaseService.initialize();
  debugPrint('✅ Courier App - Supabase başlatıldı');
  
  // 3. Cache servisi başlat (OFFLINE SUPPORT!)
  await CacheService().initialize();
  debugPrint('✅ Cache servisi başlatıldı');
  
  // 4. FCM arka plan handler kaydet
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // 5. Local notifications başlat
  await _initializeLocalNotifications();
  
  // 6. FCM Token al ve kaydet
  await _setupFCMToken();
  
  // 7. Foreground mesajları dinle
  _setupForegroundMessageHandler();
  
  runApp(const OnLogCourierApp());
}

// FCM Token'ı al ve Supabase'e kaydet
Future<void> _setupFCMToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('📱 FCM Token alındı: ${token.substring(0, 20)}...');
      
      // Token'ı users tablosunda güncelle (giriş yapınca tekrar güncellenecek)
      final user = SupabaseService.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('users')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('✅ FCM Token users tablosuna kaydedildi');
      } else {
        debugPrint('⚠️ Kullanıcı giriş yapmamış, token kaydedilemedi');
      }
    }
  } catch (e) {
    debugPrint('❌ FCM Token hatası: $e');
  }
}

// Local notifications konfigürasyonu
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload != null) {
        debugPrint('📱 Bildirime tıklandı, order_id: $payload');
      }
    },
  );

  // Android notification channels oluştur
  if (!kIsWeb) {
    await _createNotificationChannels();
  }
  
  debugPrint('✅ Local notifications başlatıldı');
}

// Android bildirim kanallarını oluştur
Future<void> _createNotificationChannels() async {
  final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin == null) return;

  const AndroidNotificationChannel newOrderChannel = AndroidNotificationChannel(
    'new_order_channel',
    'Yeni Siparişler',
    description: 'Yeni sipariş bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
    'urgent_order_channel',
    'Acil Siparişler',
    description: 'Acil teslimat bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFFFF0000),
  );

  await androidPlugin.createNotificationChannel(newOrderChannel);
  await androidPlugin.createNotificationChannel(urgentChannel);
  debugPrint('✅ Android bildirim kanalları oluşturuldu');
}

// Foreground mesaj handler
void _setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Data-only mesajlarda title data içinde olacak
    final title = message.notification?.title ?? message.data['title'] ?? 'ONLOG';
    debugPrint('🔔 Foreground bildirimi: $title');
    _showLocalNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'ONLOG';
    debugPrint('📱 Bildirime tıklandı: $title');
    // Sayfayı refresh et - Navigator ile ana ekrana dön ve refresh yap
    // Not: Bu callback app açıkken çalışır, kapalıyken getInitialMessage kullan
  });
}

// FCM Token'ı al ve Supabase'e kaydet
Future<void> saveFCMToken(String userId) async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    
    if (fcmToken != null) {
      debugPrint('📱 FCM Token alındı');
      
      final fcmService = SupabaseFCMService();
      await fcmService.saveToken(
        userId: userId,
        fcmToken: fcmToken,
        deviceType: kIsWeb ? 'web' : 'mobile',
        deviceId: fcmToken.hashCode.toString(),
        deviceName: kIsWeb ? 'Web Browser' : 'Mobile Device',
        appVersion: '1.0.0',
      );
      
      debugPrint('✅ FCM Token Supabase\'e kaydedildi');
    }
  } catch (e) {
    debugPrint('❌ FCM Token kaydetme hatası: $e');
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
  
  /// 🔴 APP LIFECYCLE DEĞİŞİNCE - OTOMATIK OFFLINE
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('📱 App State: $state');
    
    // SADECE uygulama tamamen kapanınca offline yap
    // Arka plana atınca (paused) offline YAPMA!
    if (state == AppLifecycleState.detached) {
      // App KAPATILIYOR → Kullanıcıyı otomatik offline yap!
      debugPrint('� App kapatılıyor - Kullanıcı offline yapılıyor...');
      LocationService.dispose(); // Global konum servisini temizle
      _setUserOffline(); // Asenkron ama await yok çünkü didChangeAppLifecycleState sync olmalı
    } else if (state == AppLifecycleState.paused) {
      // App arka plana alındı (Home tuşu) → Offline yapma, mesai devam etsin
      debugPrint('⏸️ App arka plana alındı ama mesai devam ediyor');
    } else if (state == AppLifecycleState.resumed) {
      // App ön plana geldi
      debugPrint('▶️ App ön plana geldi');
    }
  }
  
  /// Kullanıcıyı offline yap
  Future<void> _setUserOffline() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('users')
            .update({
              'is_available': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
        
        debugPrint('🔴 Kullanıcı otomatik offline yapıldı (app kapatıldı)');
      }
    } catch (e) {
      debugPrint('❌ Offline yapma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONLOG Kurye',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Merchant ile aynı yeşil tema
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF111111),
        ),
        useMaterial3: true,
      ),
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
      
      if (userData['status'] != 'approved' || userData['is_active'] != true) {
        await SupabaseService.client.auth.signOut();
        return null;
      }
      
      // FCM Token'ı güncelle (her app açılışında)
      await _setupFCMToken();
      
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
