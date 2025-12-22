import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:onlog_shared/services/supabase_fcm_service.dart';
import 'screens/courier_login_screen.dart';
import 'services/cache_service.dart';
import 'dart:io' show Platform;

// Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Arka plan mesaj handler (TOP-LEVEL FUNCTION OLMALI!)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Arka plan bildirimi: ${message.notification?.title}');
  
  // Local notification göster
  await _showLocalNotification(message);
}

// Local notification gösterme fonksiyonu
Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'new_order_channel',
    'Yeni Siparişler',
    channelDescription: 'Yeni sipariş bildirimleri',
    importance: Importance.max,
    priority: Priority.max,
    sound: RawResourceAndroidNotificationSound('new_order_sound'),
    playSound: true,
    enableVibration: true,
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

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'ONLOG',
    message.notification?.body ?? '',
    notificationDetails,
    payload: message.data['order_id'],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Firebase başlat (sadece FCM için!)
  await Firebase.initializeApp();
  debugPrint('✅ Firebase (FCM) başlatıldı');
  
  // 2. Supabase başlat
  await SupabaseService.initialize();
  debugPrint('✅ Supabase başlatıldı');
  
  // 3. Cache servisi başlat
  await CacheService().initialize();
  debugPrint('✅ Cache servisi başlatıldı');
  
  // 4. FCM arka plan handler kaydet
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // 5. Local notifications başlat
  await _initializeLocalNotifications();
  
  // 6. FCM izinleri al
  await _requestNotificationPermissions();
  
  // 7. Foreground mesajları dinle
  _setupForegroundMessageHandler();
  
  runApp(const OnLogCourierApp());
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
      // Bildirime tıklandığında
      final payload = response.payload;
      if (payload != null) {
        debugPrint('📱 Bildirime tıklandı, order_id: $payload');
        // TODO: Order detay sayfasına git
      }
    },
  );

  // Android notification channels oluştur
  if (Platform.isAndroid) {
    await _createNotificationChannels();
  }
}

// Android bildirim kanallarını oluştur
Future<void> _createNotificationChannels() async {
  final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin == null) return;

  // Yeni Sipariş Kanalı
  const AndroidNotificationChannel newOrderChannel = AndroidNotificationChannel(
    'new_order_channel',
    'Yeni Siparişler',
    description: 'Yeni sipariş bildirimleri',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('new_order_sound'),
    playSound: true,
    enableVibration: true,
  );

  // Acil Sipariş Kanalı
  const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
    'urgent_order_channel',
    'Acil Siparişler',
    description: 'Acil teslimat bildirimleri',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('urgent_sound'),
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFFFF0000),
  );

  // Genel Bildirimler
  const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
    'general_channel',
    'Genel Bildirimler',
    description: 'Teslimat durumu ve genel bildirimler',
    importance: Importance.high,
    playSound: true,
  );

  // Info Kanalı
  const AndroidNotificationChannel infoChannel = AndroidNotificationChannel(
    'info_channel',
    'Bilgilendirmeler',
    description: 'Sistem bildirimleri',
    importance: Importance.defaultImportance,
  );

  await androidPlugin.createNotificationChannel(newOrderChannel);
  await androidPlugin.createNotificationChannel(urgentChannel);
  await androidPlugin.createNotificationChannel(generalChannel);
  await androidPlugin.createNotificationChannel(infoChannel);

  debugPrint('✅ Android bildirim kanalları oluşturuldu');
}

// FCM izinleri
Future<void> _requestNotificationPermissions() async {
  final messaging = FirebaseMessaging.instance;

  // iOS için izin iste
  if (Platform.isIOS) {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // Android 13+ için izin otomatik istenir
  debugPrint('✅ Bildirim izinleri ayarlandı');
}

// Foreground mesaj handler
void _setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('🔔 Foreground bildirimi: ${message.notification?.title}');
    
    // App açıkken de local notification göster
    _showLocalNotification(message);
  });

  // Bildirime tıklandığında (app kapalıyken açıldıysa)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📱 Bildirime tıklandı: ${message.data}');
    // TODO: Order detay sayfasına git
  });
}

// FCM Token'ı al ve Supabase'e kaydet
Future<void> saveFCMToken(String userId) async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    
    if (fcmToken != null) {
      debugPrint('📱 FCM Token: ${fcmToken.substring(0, 20)}...');
      
      final fcmService = SupabaseFCMService();
      await fcmService.saveToken(
        userId: userId,
        fcmToken: fcmToken,
        deviceType: Platform.isAndroid ? 'android' : 'ios',
        deviceId: fcmToken.hashCode.toString(),
        deviceName: Platform.isAndroid ? 'Android Device' : 'iOS Device',
        appVersion: '1.0.0',
      );
      
      debugPrint('✅ FCM Token Supabase\'e kaydedildi');
    }
  } catch (e) {
    debugPrint('❌ FCM Token kaydetme hatası: $e');
  }
}

class OnLogCourierApp extends StatelessWidget {
  const OnLogCourierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONLOG Kurye',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF111111),
        ),
        useMaterial3: true,
      ),
      home: const CourierLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
