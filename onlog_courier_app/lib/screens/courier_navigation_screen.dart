import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'tabs/home_tab_supabase.dart';
import 'earnings_screen_supabase.dart';
import 'performance_screen.dart';
import 'profile_screen.dart';
import 'problems_screen.dart';
import '../services/location_service.dart';

class CourierNavigationScreen extends StatefulWidget {
  final String courierId;
  final String courierName;

  const CourierNavigationScreen({
    super.key,
    required this.courierId,
    required this.courierName,
  });

  @override
  State<CourierNavigationScreen> createState() => _CourierNavigationScreenState();
}

class _CourierNavigationScreenState extends State<CourierNavigationScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _notificationSubscription;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String _courierType = 'esnaf'; // Default değer
  bool _isLoadingCourierType = true;
  String _currentCourierName = ''; // Güncel kurye ismi

  @override
  void initState() {
    super.initState();
    _currentCourierName = widget.courierName; // İlk değer
    _loadCourierType();
    _initLocalNotifications();
    _setupNotificationListener();
  }

  /// 🔄 Kurye ismini yenile
  Future<void> _refreshCourierName() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('full_name')
          .eq('id', widget.courierId)
          .single();
      
      if (response['full_name'] != null) {
        setState(() {
          _currentCourierName = response['full_name'];
        });
      }
    } catch (e) {
      print('❌ İsim yenileme hatası: $e');
    }
  }

  /// � KURYE TİPİNİ YÜK (ESNAF / SGK)
  Future<void> _loadCourierType() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('metadata')
          .eq('id', widget.courierId)
          .single();
      
      if (response['metadata'] != null) {
        final metadata = response['metadata'] as Map<String, dynamic>;
        setState(() {
          _courierType = metadata['courier_type'] ?? 'esnaf';
          _isLoadingCourierType = false;
        });
        print('✅ Kurye tipi yüklendi: $_courierType');
      } else {
        setState(() {
          _courierType = 'esnaf'; // Default
          _isLoadingCourierType = false;
        });
      }
    } catch (e) {
      print('❌ Kurye tipi yüklenirken hata: $e');
      setState(() {
        _courierType = 'esnaf'; // Hata durumunda default
        _isLoadingCourierType = false;
      });
    }
  }

  /// �📱 LOCAL NOTIFICATIONS BAŞLAT
  void _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
    print('✅ Local Notifications başlatıldı');
  }

  /// 🔔 LOKAL BİLDİRİM GÖSTER
  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'new_order_channel',
      'Yeni Siparişler',
      channelDescription: 'Yeni teslimat siparişleri için bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      notificationDetails,
    );
    
    print('📱 Lokal bildirim gösterildi: $title');
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// 🔔 BİLDİRİM DİNLEYİCİSİ - Yeni bildirim gelince popup göster!
  void _setupNotificationListener() {
    print('🔔 BİLDİRİM DİNLEYİCİSİ AKTİF! (CourierNavigationScreen)');
    
    _notificationSubscription = SupabaseService.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          print('📬 YENİ BİLDİRİM GELDİ! ${data.length} adet');
          
          // Sadece bu kurye'ye ait ve okunmamış bildirimleri filtrele
          final myUnreadNotifications = data.where((notif) =>
              notif['user_id'] == widget.courierId && 
              notif['is_read'] == false
          ).toList();
          
          if (myUnreadNotifications.isNotEmpty && mounted) {
            final latestNotification = myUnreadNotifications.first;
            final title = latestNotification['title'] ?? 'Yeni Bildirim';
            final message = latestNotification['message'] ?? '';
            
            // 📱 LOKAL BİLDİRİM GÖSTER (asıl önemli kısım!)
            _showLocalNotification(title, message);
            
            // Popup göster (ek bonus)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (message.isNotEmpty)
                      Text(message, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'KAPAT',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
            
            // Bildirimi okundu olarak işaretle
            SupabaseService.client
                .from('notifications')
                .update({'is_read': true})
                .eq('id', latestNotification['id'])
                .then((_) => print('✅ Bildirim okundu olarak işaretlendi'));
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    // Kurye tipi yüklenene kadar loading göster
    if (_isLoadingCourierType) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4CAF50),
          ),
        ),
      );
    }

    // SGK kuryeleri için 3 ekran (Teslimatlar, Performans, Profil)
    // Esnaf kuryeleri için 3 ekran (Teslimatlar, Kazançlar, Profil)
    final screens = _courierType == 'sgk'
        ? [
            HomeTabSupabase(
              courierId: widget.courierId,
              courierName: widget.courierName,
            ),
            PerformanceScreen(
              courierId: widget.courierId,
            ),
            ProblemsScreen(
              courierId: widget.courierId,
            ),
            const ProfileScreen(),
          ]
        : [
            HomeTabSupabase(
              courierId: widget.courierId,
              courierName: widget.courierName,
            ),
            EarningsScreenSupabase(
              courierId: widget.courierId,
            ),
            ProblemsScreen(
              courierId: widget.courierId,
            ),
            const ProfileScreen(),
          ];

    // SGK kuryeleri için Performans tab'ı, Esnaf için Kazançlar tab'ı
    final navigationItems = _courierType == 'sgk'
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining),
              label: 'Teslimatlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Performans',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem),
              label: 'Sorunlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining),
              label: 'Teslimatlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Kazançlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem),
              label: 'Sorunlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Kurye adını kısalt ve Flexible kullan
            Expanded(
              child: Text(
                'ONLOG - $_currentCourierName',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4), // Minimal boşluk
            // Global LocationService durumu - daha kompakt
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 5), (i) => i),
              builder: (context, snapshot) {
                return FutureBuilder<bool>(
                  future: Geolocator.isLocationServiceEnabled(),
                  builder: (context, locationSnapshot) {
                    final isServiceRunning = LocationService.isServiceRunning;
                    final isDutyActive = LocationService.isDutyActive;
                    final isGpsEnabled = locationSnapshot.data ?? false;
                    
                    // GPS durumu: Servis çalışıyor VE Mesai aktif VE Sistem GPS'i açık
                    final isGpsActive = isServiceRunning && isDutyActive && isGpsEnabled;
                    
                    // Debug log her 5 saniyede bir
                    if (snapshot.data != null && snapshot.data! % 12 == 0) { // Her 1 dakikada bir log (5s * 12 = 60s)
                      print('🔍 AppBar GPS Status - Service: $isServiceRunning, Duty: $isDutyActive, GPS Enabled: $isGpsEnabled');
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      constraints: const BoxConstraints(maxWidth: 60), // Daha küçük genişlik sınırı
                      decoration: BoxDecoration(
                        color: isGpsActive 
                            ? Colors.green 
                            : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGpsActive 
                                ? Icons.gps_fixed 
                                : Icons.gps_off,
                            color: Colors.white,
                            size: 12,
                          ),
                          if (isGpsActive) ...[
                            const SizedBox(width: 2),
                            Text(
                              'ON',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Profil sekmesine geçildiğinde ismi yenile
          if (index == 3) {
            _refreshCourierName();
          }
        },
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: navigationItems,
      ),
    );
  }
}
