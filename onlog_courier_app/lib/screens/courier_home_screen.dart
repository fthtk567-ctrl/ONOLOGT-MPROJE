gırıs yaotım import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import '../widgets/compact_order_card.dart'; // ✨ YENİ kompakt kart
import 'delivery_details_screen_supabase.dart';
import '../services/location_service.dart';

class CourierHomeScreen extends StatefulWidget {
  final String courierId;
  final String courierName;
  
  const CourierHomeScreen({super.key, required this.courierId, required this.courierName});

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  StreamSubscription? _deliverySubscription;
  StreamSubscription? _notificationSubscription;

  
  // 🟢 MESAİ DURUMU
  bool _isOnDuty = false; // Mesaide mi?
  bool _isTogglingDuty = false; // Toggle işlemi yapılıyor mu?
  
  // Filtreleme
  String _selectedStatus = 'all'; // 'all', 'assigned', 'in_progress', 'completed'
  
  // İstatistikler
  int _todayDeliveries = 0;
  int _pendingDeliveries = 0;
  int _completedDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _loadDutyStatus(); // Mesai durumunu yükle
    _loadOrders();
    _setupRealtimeListener();
    _setupNotificationListener();
    // ❌ Konum güncellemesi burada BAŞLATILMAYACAK
    // ✅ Sadece "Mesaiye Başla" butonuna basınca başlayacak
  }
  
  /// 🟢 MESAİ DURUMUNU YÜKLE
  Future<void> _loadDutyStatus() async {
    print('🚀 _loadDutyStatus() başlatıldı - Kurye ID: ${widget.courierId}');
    
    try {
      print('🔍 Supabase\'den is_available durumu sorgulanıyor...');
      final response = await SupabaseService.client
          .from('users')
          .select('is_available')
          .eq('id', widget.courierId)
          .single();
      
      print('📥 Supabase yanıtı alındı: $response');
      
      if (mounted) {
        final isAvailable = response['is_available'] ?? false;
        print('🎯 is_available değeri: $isAvailable');
        
        setState(() {
          _isOnDuty = isAvailable;
        });
        print('✅ UI durumu güncellendi - _isOnDuty: $_isOnDuty');
        
        // Eğer zaten mesaideyse global konum servisini başlat
        if (isAvailable) {
          print('🔍 Mesaiye başlama işlemi başlatılıyor...');
          final success = await LocationService.startPersistentLocationService(widget.courierId);
          print('✅ Mesai durumu: Mesaide - Global konum servisi başlatıldı: $success');
        } else {
          print('🔍 Mesai kapalı durumda, servis durduruluyor...');
          LocationService.setDutyStatus(false);
          print('✅ Mesai durumu: Mesaide değil');
        }
      } else {
        print('⚠️ Widget mount edilmemiş, UI güncellemesi atlandı');
      }
    } catch (e) {
      print('❌ Mesai durumu yüklenemedi: $e');
    }
    
    print('🏁 _loadDutyStatus() tamamlandı');
  }
  
  /// 🔄 MESAİYE BAŞLA / BİTİR
  Future<void> _toggleDutyStatus() async {
    setState(() => _isTogglingDuty = true);
    
    try {
      final newStatus = !_isOnDuty;
      
      // Mesaiye başlarken konum iznini kontrol et
      if (newStatus) {
        print('📍 Mesaiye başlamadan önce konum izni kontrol ediliyor...');
        
        LocationPermission permission = await Geolocator.checkPermission();
        
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          // Konum izni yok, mesaiye başlayamaz
          if (mounted) {
            setState(() => _isTogglingDuty = false);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '❌ Konum izni gerekli! Mesaiye başlamak için konum iznini verin.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
        
        // Global servisi başlat
        await LocationService.startPersistentLocationService(widget.courierId);
      }
      
      // Mesai durumunu güncelle
      await SupabaseService.client
          .from('users')
          .update({'is_available': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.courierId);
      
      if (mounted) {
        setState(() {
          _isOnDuty = newStatus;
          _isTogglingDuty = false;
        });
        
        // 📍 Global konum servisini kontrol et
        if (newStatus) {
          print('🔍 Mesaiye başlama - Global LocationService başlatılıyor...');
          final success = await LocationService.startPersistentLocationService(widget.courierId);
          print('✅ Global LocationService başlatıldı: $success');
          LocationService.setDutyStatus(true);
        } else {
          LocationService.setDutyStatus(false);
          print('⏹️ Mesai durumu pasif yapıldı');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus 
                  ? '🟢 Mesaiye başladınız! Konumunuz 30 saniyede bir güncellenecek.' 
                  : '🔴 Mesai bitti. Artık sipariş gelmeyecek.',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        
        print(newStatus ? '🟢 MESAİYE BAŞLANDI + KONUM GÜNCELLEME AKTİF' : '🔴 MESAİ BİTTİ + KONUM GÜNCELLEME DURDURULDU');
      }
    } catch (e) {
      print('❌ Mesai durumu güncellenemedi: $e');
      
      if (mounted) {
        setState(() => _isTogglingDuty = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    _deliverySubscription?.cancel();
    _notificationSubscription?.cancel();
    // Global LocationService widget dispose'da durdurmuyoruz - sayfa geçişlerinde çalışmaya devam etsin
    super.dispose();
  }
  
  /// 🔔 BİLDİRİM DİNLEYİCİSİ - Yeni bildirim gelince ses + popup göster!
  void _setupNotificationListener() {
    print('🔔 BİLDİRİM DİNLEYİCİSİ AKTİF!');
    
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
            
            // Ses çal + Popup göster
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

  /// GERÇEK ZAMANLI DİNLEYİCİ - Yeni sipariş gelince otomatik göster!
  void _setupRealtimeListener() {
    print('🔔 GERÇEK ZAMANLI DİNLEYİCİ AKTİF EDİLDİ!');
    
    _deliverySubscription = SupabaseService.client
        .from('delivery_requests')
        .stream(primaryKey: ['id'])
        .eq('courier_id', widget.courierId)
        .listen((List<Map<String, dynamic>> data) {
          print('🔥 YENİ VERİ GELDİ! ${data.length} sipariş');
          
          // 🔴 CLIENT-SIDE FİLTER: Red edilenleri çıkar
          final myOrders = data.where((order) {
            final courierId = order['courier_id'] as String?;
            final rejectedAt = order['rejected_at'];
            return courierId == widget.courierId && rejectedAt == null;
          }).toList();
          
          print('✅ Bu kuryeye ait siparişler: ${myOrders.length}');
          
          // Sadece 'assigned' veya 'in_progress' olanları göster
          final activeOrders = myOrders.where((order) {
            final status = order['status'] as String?;
            return status == 'assigned' || status == 'in_progress';
          }).toList();
          
          // Zamana göre sırala (en yeni üstte)
          activeOrders.sort((a, b) {
            final dateA = DateTime.parse(a['created_at'] ?? DateTime.now().toIso8601String());
            final dateB = DateTime.parse(b['created_at'] ?? DateTime.now().toIso8601String());
            return dateB.compareTo(dateA);
          });
          
          if (mounted) {
            setState(() {
              orders = activeOrders;
              isLoading = false;
            });
            
            // Yeni sipariş bildirimi göster
            if (activeOrders.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Yeni teslimat isteği geldi!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        });
  }

  Future<void> _loadOrders() async {
    try {
      print('📦 Teslimat istekleri yükleniyor...');
      final response = await SupabaseService
          .from('delivery_requests')
          .select()
          .eq('courier_id', widget.courierId)
          .is_('rejected_at', null)  // ❌ RED EDİLENLERİ GETİRME!
          .order('created_at', ascending: false);
      
      final allOrders = List<Map<String, dynamic>>.from(response);
      
      // İstatistikleri hesapla
      final today = DateTime.now();
      _todayDeliveries = allOrders.where((order) {
        final createdAt = DateTime.parse(order['created_at'] ?? '');
        return createdAt.year == today.year && 
               createdAt.month == today.month && 
               createdAt.day == today.day;
      }).length;
      
      _pendingDeliveries = allOrders.where((order) => 
        order['status'] == 'assigned' || order['status'] == 'in_progress'
      ).length;
      
      _completedDeliveries = allOrders.where((order) => 
        order['status'] == 'completed' || order['status'] == 'delivered'
      ).length;
      
      setState(() {
        orders = allOrders;
        isLoading = false;
      });
      print('✅ ${orders.length} teslimat isteği yüklendi');
    } catch (e) {
      print('❌ Teslimat yükleme hatası: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedStatus == 'all') return orders;
    
    if (_selectedStatus == 'pending') {
      return orders.where((order) => 
        order['status'] == 'assigned' || order['status'] == 'in_progress'
      ).toList();
    }
    
    return orders.where((order) => order['status'] == _selectedStatus).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // ✨ Daha modern açık gri
      body: CustomScrollView(
        slivers: [
          // ✨ Modern Minimal App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00B894), Color(0xFF00A383)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Merhaba ${widget.courierName.split(' ')[0]} 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            _isOnDuty ? '🟢 Mesaide' : '⚪ Mesai dışı',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  setState(() => isLoading = true);
                  _loadOrders();
                },
                tooltip: 'Yenile',
              ),
            ],
          ),
          
          // 🟢 MESAİ KONTROL SWITCH
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildDutySwitch(),
            ),
          ),
          
          // İstatistik Kartları
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 8),
                  _buildFilterChips(),
                ],
              ),
            ),
          ),
          
          // Teslimat Listesi
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredOrders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 100, color: Colors.grey[300]),
                    const SizedBox(height: 24),
                    Text(
                      _selectedStatus == 'all' 
                        ? 'Henüz teslimat yok' 
                        : 'Bu filtrede teslimat yok',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Yenile'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = _filteredOrders[index];
                    return CompactOrderCard( // ✨ YENİ kompakt kart
                      order: order,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryDetailsScreenSupabase(
                              orderId: order['id'],
                              courierId: widget.courierId,
                            ),
                          ),
                        );
                      },
                      onAccept: order['status'] == 'WAITING_COURIER' 
                          ? () => _acceptOrder(order['id'])
                          : null,
                      onReject: order['status'] == 'WAITING_COURIER'
                          ? () => _rejectOrder(order['id'])
                          : null,
                    );
                  },
                  childCount: _filteredOrders.length,
                ),
              ),
            ),
          
          // Alt boşluk
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Bugün',
            _todayDeliveries.toString(),
            Icons.today_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Bekleyen',
            _pendingDeliveries.toString(),
            Icons.hourglass_empty_rounded,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tamamlanan',
            _completedDeliveries.toString(),
            Icons.check_circle_rounded,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tümü', 'all', orders.length),
          const SizedBox(width: 8),
          _buildFilterChip('Bekleyen', 'pending', _pendingDeliveries),
          const SizedBox(width: 8),
          _buildFilterChip('Atanan', 'assigned', orders.where((o) => o['status'] == 'assigned').length),
          const SizedBox(width: 8),
          _buildFilterChip('Devam Eden', 'in_progress', orders.where((o) => o['status'] == 'in_progress').length),
          const SizedBox(width: 8),
          _buildFilterChip('Tamamlanan', 'completed', _completedDeliveries),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: const Color(0xFF4CAF50),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
  
  /// 🟢 MESAİ KONTROL SWITCH WIDGET
  Widget _buildDutySwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isOnDuty 
                    ? [const Color(0xFF00D2A0), const Color(0xFF00B894)]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isOnDuty ? Icons.electric_bolt_rounded : Icons.bolt_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Metin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnDuty ? 'Aktif Mesai' : 'Pasif Durum',
                  style: const TextStyle(
                    color: Color(0xFF2D3436),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isOnDuty 
                      ? 'Siparişler sana yönlendiriliyor' 
                      : 'Sipariş almak için aktif et',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Switch Butonu
          _isTogglingDuty
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isOnDuty ? const Color(0xFF00B894) : Colors.grey.shade400
                    ),
                  ),
                )
              : Switch(
                  value: _isOnDuty,
                  onChanged: (value) => _toggleDutyStatus(),
                  activeColor: const Color(0xFF00B894),
                  activeTrackColor: const Color(0xFF00B894).withOpacity(0.3),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade200,
                ),
        ],
      ),
    );
  }

  // Sipariş kabul et
  Future<void> _acceptOrder(String orderId) async {
    try {
      await SupabaseService.client
          .from('delivery_requests')
          .update({
            'status': 'ACCEPTED',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sipariş kabul edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Sipariş reddet
  Future<void> _rejectOrder(String orderId) async {
    try {
      await SupabaseService.client
          .from('delivery_requests')
          .update({
            'rejected_at': DateTime.now().toIso8601String(),
            'rejection_reason': 'Kurye tarafından reddedildi',
          })
          .eq('id', orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Sipariş reddedildi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
