import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import '../widgets/loading_states.dart';
import 'call_courier_screen.dart';
import 'live_map_page.dart';
import 'active_deliveries_page.dart';
import 'closed_deliveries_page.dart';
import 'notifications_panel_page.dart';
import 'main_navigation_screen.dart';

/// Profesyonel Merchant Dashboard - Getir UX + ONLOG Teması
class MerchantHomePageV2 extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MerchantHomePageV2({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MerchantHomePageV2> createState() => _MerchantHomePageV2State();
}

class _MerchantHomePageV2State extends State<MerchantHomePageV2> {
  int _todayDeliveriesCount = 0;
  double _todayRevenue = 0.0;
  int _activeCouriersCount = 0;
  int _activeDeliveriesCount = 0;
  StreamSubscription? _deliverySubscription;
  StreamSubscription? _courierSubscription;
  
  // 🔄 Loading States
  bool _isLoading = true;
  String? _error;
  
  // 📍 Merchant Konumu
  Map<String, dynamic> _merchantLocation = {'lat': 41.0082, 'lng': 28.9784}; // Default Istanbul

  @override
  void initState() {
    super.initState();
    loadData();
    _listenToActiveCouriers();
  }

  @override
  void dispose() {
    _deliverySubscription?.cancel();
    _courierSubscription?.cancel();
    super.dispose();
  }

  // _loadTodayEarnings artık gerekli değil, loadData içinde hesaplanıyor

  void _listenToActiveCouriers() {
    _courierSubscription = SupabaseService.client
        .from('users')
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            // Manuel filtreleme (stream.eq çalışmıyor)
            final onlineCouriers = data
                .where((c) => c['role'] == 'courier' && c['is_available'] == true)
                .length;
            setState(() {
              _activeCouriersCount = onlineCouriers;
            });
          }
        });
  }

  /// 🔥 GERÇEK ZAMANLI TESLİMAT DİNLEYİCİSİ
  void listenToDeliveries() {
    print('🔔 MERCHANT PANEL: Teslimat dinleyicisi aktif!');
    
    _deliverySubscription = SupabaseService.client
        .from('delivery_requests')
        .stream(primaryKey: ['id'])
        .eq('merchant_id', widget.restaurantId)
        .listen((List<Map<String, dynamic>> data) {
          print('🔥 MERCHANT: ${data.length} teslimat güncellendi');
          
          // Aktif teslimatları say (assigned, accepted, picked_up, in_progress)
          final activeCount = data.where((delivery) {
            final status = delivery['status'] as String?;
            return status == 'assigned' || 
                   status == 'accepted' || 
                   status == 'picked_up' ||
                   status == 'in_progress';
          }).length;
          
          if (mounted) {
            setState(() {
              _activeDeliveriesCount = activeCount;
            });
            
            // Son teslimatın durumunu kontrol et
            if (data.isNotEmpty) {
              final latestDelivery = data.first;
              final status = latestDelivery['status'] as String?;
              
              if (status == 'assigned') {
                showDeliveryNotification('assigned');
              } else if (status == 'picked_up') {
                showDeliveryNotification('pickedUp');
              } else if (status == 'in_progress') {
                showDeliveryNotification('delivering');
              } else if (status == 'delivered') {
                showDeliveryNotification('delivered');
              }
            }
          }
        });
  }

  /// Teslimat bildirimleri
  void showDeliveryNotification(String status) {
    String message = '';
    IconData icon = Icons.delivery_dining;
    Color color = Colors.blue;

    switch (status) {
      case 'assigned':
        message = '🎉 Kurye atandı!';
        icon = Icons.check_circle;
        color = Colors.blue;
        break;
      case 'pickedUp':
        message = '📦 Paket toplandı!';
        icon = Icons.shopping_bag;
        color = Colors.purple;
        break;
      case 'delivering':
        message = '🚴 Teslimat yolda!';
        icon = Icons.delivery_dining;
        color = Colors.indigo;
        break;
      case 'delivered':
        message = '✅ Teslimat tamamlandı!';
        icon = Icons.done_all;
        color = Colors.green;
        break;
    }

    if (message.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(message, style: const TextStyle(fontSize: 16)),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 📍 Merchant kullanıcısının konumunu çek
      final merchantData = await SupabaseService.from('users')
          .select('business_address, address, current_location, business_location')
          .eq('id', widget.restaurantId)
          .single();
      
      // Adres bilgisi
      final addressText = (merchantData['business_address'] as String?) ?? 
                          (merchantData['address'] as String?) ?? 
                          'Adres belirtilmemiş';
      
      // ✅ İŞLETME SABİT KONUMUNU KULLAN (business_location)
      // current_location = Anlık GPS (merchant evde/tatilde olabilir) ❌
      // business_location = İşletme adresi (kayıt sırasında seçilen) ✅
      
      final businessLocation = merchantData['business_location'];
      
      if (businessLocation != null) {
        // business_location varsa onu kullan (SABİT işletme konumu)
        final location = businessLocation;
        
        // JSON format: {"latitude": ..., "longitude": ...}
        if (location is Map) {
          if (location.containsKey('latitude') && location.containsKey('longitude')) {
            // Direct JSON format
            _merchantLocation = {
              'lat': (location['latitude'] as num).toDouble(),
              'lng': (location['longitude'] as num).toDouble(),
              'address': addressText,
            };
            print('✅ İşletme konumu (business_location): ${_merchantLocation['lat']}, ${_merchantLocation['lng']}');
          } else if (location.containsKey('coordinates')) {
            // GeoJSON format
            final coords = location['coordinates'];
            _merchantLocation = {
              'lat': (coords[1] as num).toDouble(),
              'lng': (coords[0] as num).toDouble(),
              'address': addressText,
            };
            print('✅ İşletme konumu (GeoJSON): ${_merchantLocation['lat']}, ${_merchantLocation['lng']}');
          }
        } else if (location is String && location.startsWith('POINT')) {
          // Parse POINT(lng lat) format
          final regex = RegExp(r'POINT\(([0-9.-]+)\s+([0-9.-]+)\)');
          final match = regex.firstMatch(location);
          if (match != null) {
            _merchantLocation = {
              'lng': double.parse(match.group(1)!),
              'lat': double.parse(match.group(2)!),
              'address': addressText,
            };
            print('✅ İşletme konumu (PostGIS): ${_merchantLocation['lat']}, ${_merchantLocation['lng']}');
          }
        }
      } else if (merchantData['current_location'] != null) {
        // Fallback: business_location yoksa current_location kullan (geçici)
        print('⚠️ business_location NULL - current_location kullanılıyor (FALLBACK)');
        final location = merchantData['current_location'];
        
        if (location is Map) {
          if (location.containsKey('latitude') && location.containsKey('longitude')) {
            _merchantLocation = {
              'lat': (location['latitude'] as num).toDouble(),
              'lng': (location['longitude'] as num).toDouble(),
              'address': addressText,
            };
          } else if (location.containsKey('coordinates')) {
            final coords = location['coordinates'];
            _merchantLocation = {
              'lat': (coords[1] as num).toDouble(),
              'lng': (coords[0] as num).toDouble(),
              'address': addressText,
            };
          }
        }
      } else {
        // Hiçbir konum yoksa, default Istanbul konumu kullan
        _merchantLocation['address'] = addressText;
        print('⚠️ Hiçbir konum bulunamadı - default Istanbul kullanılıyor');
      }
      
      print('📍 Merchant konumu yüklendi: $_merchantLocation');
      
      // BUGÜN TESLİM EDİLEN SİPARİŞLERİ ÇEK (istatistikler için)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final todayDeliveriesData = await SupabaseService.from('delivery_requests')
          .select()
          .eq('merchant_id', widget.restaurantId)
          .eq('status', 'delivered') // SADECE BUGÜN TESLİM EDİLENLER
          .gte('updated_at', startOfDay.toIso8601String()) // updated_at = teslimat zamanı
          .lte('updated_at', endOfDay.toIso8601String())
          .order('updated_at', ascending: false);
      
      // Aktif teslimatları çek (dashboard için)
      final activeDeliveriesData = await SupabaseService.from('delivery_requests')
          .select()
          .eq('merchant_id', widget.restaurantId)
          .inFilter('status', ['pending', 'assigned', 'accepted', 'picked_up', 'delivering'])
          .order('created_at', ascending: false);
      
      // Kurye sayılarını Supabase'den çek
      final couriersData = await SupabaseService.from('users')
          .select('id, is_available, status')
          .eq('role', 'courier')
          .eq('status', 'active');
      
      int onlineCount = 0;
      for (var courier in couriersData) {
        if (courier['is_available'] == true) onlineCount++;
      }
      
      print('📊 Bugün: ${todayDeliveriesData.length} teslimat');
      print('📦 Aktif: ${activeDeliveriesData.length} teslimat');
      print('👥 Online: $onlineCount kurye');
      
      if (mounted) {
        setState(() {
          // İstatistikler için basit veri - Order modeline çevirme gerek yok
          _todayDeliveriesCount = todayDeliveriesData.length;
          _todayRevenue = todayDeliveriesData.fold<double>(
            0, 
            (sum, d) => sum + ((d['declared_amount'] ?? 0) as num).toDouble()
          );
          
          _activeCouriersCount = onlineCount;
          _activeDeliveriesCount = activeDeliveriesData.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Veriler yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Stats hesaplama - basitleştirilmiş
  Map<String, dynamic> get _stats {
    return {
      'todayOrders': _todayDeliveriesCount,
      'todayRevenue': _todayRevenue,
      'pendingOrders': 0, // TODO: Ayrı query gerekli
      'activeCouriers': _activeCouriersCount,
      'weeklyRevenue': 0.0, // TODO: Ayrı query gerekli
      'monthlyOrders': 0, // TODO: Ayrı query gerekli
      'avgDeliveryTime': 35.0, // Ortalama 35 dk
      'totalRevenue': _todayRevenue, // Şimdilik bugünün geliri
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.restaurantName),
            Text(
              'Merchant Panel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => NotificationsPanelPage(
                  merchantId: widget.restaurantId
                )
              )
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _error != null 
            ? ErrorStateView(message: _error!, onRetry: loadData)
            : buildBody(false, false),
      ),
    );
  }

  // 🔄 Ana body - Loading states kontrolü
  Widget buildBody(bool isDesktop, bool isTablet) {
    // Hata durumu
    if (_error != null) {
      return ErrorStateView(
        message: _error!,
        onRetry: loadData,
        icon: Icons.dashboard_outlined,
      );
    }

    // Yükleniyor durumu
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 24),
            Text(
              'Dashboard yükleniyor...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Normal content
    return RefreshIndicator(
      onRefresh: loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hoş geldin + Stats
                buildWelcomeSection(context),
                const SizedBox(height: 24),
              
              // Stats Cards
              buildStatsCards(isDesktop, isTablet),
              const SizedBox(height: 32),
              
              // Quick Info Card
              buildQuickInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildWelcomeSection(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Günaydın' : hour < 18 ? 'İyi günler' : 'İyi akşamlar';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.restaurantName,
                style: const TextStyle(
                  fontSize: 28,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        // Sağ taraf: Test butonu + Bildirim ikonu
        Expanded(
          flex: 1,
          child: Wrap(
            spacing: 4,
            alignment: WrapAlignment.end,
            children: [
              // Mock Sipariş Test Butonu
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.science, size: 24),
                color: const Color(0xFF4CAF50),
                tooltip: 'Test Siparişi Oluştur',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test sipariş özelliği şu an devre dışı')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Finansal Özet ikonu
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 28),
              color: const Color(0xFF2C3E50),
              tooltip: 'Finansal Özet',
              onPressed: () {
                // MainNavigationScreen'deki index'i değiştir (3 = Ödemeler)
                final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
                if (navState != null) {
                  navState.setState(() {
                    navState.currentIndex = 3; // 4. tab (index 3)
                  });
                }
              },
            ),
            
            // Bildirim ikonu - Teslimat bildirimleri
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 28),
                  color: const Color(0xFF2C3E50),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsPanelPage(
                          merchantId: widget.restaurantId,
                        ),
                      ),
                    );
                  },
                ),
                if (_activeDeliveriesCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _activeDeliveriesCount > 9 ? '9+' : _activeDeliveriesCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildStatsCards(bool isDesktop, bool isTablet) {
    final stats = _stats;
    
    // OVERFLOW FIX v4: GridView → Column/Row (kurye dialogu gibi)
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildStatCard(
                'Bugünkü Siparişler',
                stats['todayOrders'].toString(),
                Icons.shopping_bag_outlined,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildStatCard(
                'Bugünkü Gelir',
                '₺${stats['todayRevenue'].toStringAsFixed(2)}',
                Icons.attach_money,
                const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildStatCard(
                'Bekleyen Siparişler',
                stats['pendingOrders'].toString(),
                Icons.pending_outlined,
                const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 85, // OVERFLOW FIX v4: sabit yükseklik
      padding: const EdgeInsets.all(8), // 10 → 8 (overflow fix v2)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10, // 11 → 10 (overflow fix v2)
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3), // 4 → 3 (overflow fix v2)
              Container(
                padding: const EdgeInsets.all(3), // 4 → 3 (overflow fix v2)
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 12), // 14 → 12 (overflow fix v2)
              ),
            ],
          ),
          const SizedBox(height: 1), // 2 → 1 (overflow fix v2)
          ConstrainedBox( // OVERFLOW FIX v4
            constraints: const BoxConstraints(maxHeight: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18, // 20 → 18 (overflow fix v2)
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuickInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Hoş Geldiniz!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Siparişlerinizi görüntülemek için "Siparişler" tab\'ına gidin.\nHarita üzerinden sahadaki kuryelerinizi takip edin.\nDetaylı raporlar için "Raporlar" sayfasını ziyaret edin.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              buildQuickActionButton(
                Icons.delivery_dining,
                'Kurye Çağır',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallCourierScreen(
                        merchantId: widget.restaurantId,
                        merchantName: widget.restaurantName,
                        merchantLocation: _merchantLocation, // Gerçek konum
                      ),
                    ),
                  );
                },
              ),
              buildQuickActionButton(
                Icons.map_outlined,
                'Canlı Harita',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LiveMapPage()),
                  );
                },
              ),
              buildQuickActionButton(
                Icons.shopping_bag_outlined,
                'Siparişler',
                () {
                  // Navigation handled by bottom bar
                },
              ),
              buildQuickActionButton(
                Icons.local_shipping_outlined,
                'Teslimatlarım',
                () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Teslimatlar'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.local_shipping),
                            title: const Text('Açık Teslimatlar'),
                            subtitle: const Text('Devam eden teslimat istekleri'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActiveDeliveriesPage(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Geçmiş Teslimatlar'),
                            subtitle: const Text('Önceki günlere ait teslimatlar'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClosedDeliveriesPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              buildQuickActionButton(
                Icons.bar_chart_outlined,
                'Raporlar',
                () {
                  // MainNavigationScreen'deki index'i değiştir (4 = Raporlar)
                  final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
                  if (navState != null) {
                    navState.setState(() {
                      navState.currentIndex = 4; // 5. tab (index 4 = Raporlar)
                    });
                  }
                },
              ),
              buildQuickActionButton(
                Icons.account_balance_wallet,
                'Ödemeler',
                () {
                  // MainNavigationScreen'deki index'i değiştir (3 = Ödemeler)
                  final navState = context.findAncestorStateOfType<MainNavigationScreenState>();
                  if (navState != null) {
                    navState.setState(() {
                      navState.currentIndex = 3; // 4. tab (index 3)
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildQuickActionButton(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 100, // Fixed width for Wrap layout
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
    );
  }
}
