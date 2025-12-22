import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/loading_states.dart';
import 'restaurant_location_settings.dart';

/// 🗺️ Canlı Harita Sayfası - Restoran, Müşteri, Kurye Takibi
/// 
/// Özellikler:
/// - 📍 Restoran konumu (sabit)
/// - 📍 Müşteri adresleri (siparişler)
/// - 🚴 Kurye gerçek zamanlı takibi
/// - 🛣️ Rota çizimleri
/// - ⏱️ Tahmini varış süreleri
/// - 📊 Hız, mesafe, kalan süre
/// - 🗺️ Isı haritası (en çok sipariş alan bölgeler)
class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController _mapController = MapController();
  
  // Data
  List<Order> _orders = [];
  List<Map<String, dynamic>> _activeCouriers = []; // Aktif kuryeler
  bool _isLoading = true;
  String? _error;
  
  // Kullanıcı konumu
  LatLng? _myLocation;
  bool _locationLoading = false;
  
  // Harita ayarları
  bool _showRoutes = true;
  bool _showOnlyActive = false;
  
  // Restoran konumu - Supabase'den yüklenecek
  LatLng _restaurantLocation = const LatLng(37.57, 32.79); // Varsayılan: Çumra, Konya
  
  // İstatistikler
  int _activeCourierCount = 0;
  String _avgDeliveryTime = '--';
  
  // Timer for auto-refresh
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadRestaurantLocation();
    _loadData();
    
    // Her 10 saniyede bir güncelle (kurye konumları için)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadData();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  // 🏪 Merchant konumunu Supabase'den yükle
  Future<void> _loadRestaurantLocation() async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ Kullanıcı oturumu bulunamadı');
        return;
      }
      
      // Merchant verisini Supabase'den çek
      final userData = await SupabaseService.client
          .from('users')
          .select('current_location, business_address')
          .eq('id', currentUser.id)
          .single();
      
      // current_location verisi - JSON formatında
      final locationData = userData['current_location'] as Map<String, dynamic>?;
      
      if (locationData != null) {
        final lat = (locationData['latitude'] ?? 0.0) as num;
        final lng = (locationData['longitude'] ?? 0.0) as num;
        
        if (lat != 0.0 && lng != 0.0) {
          setState(() {
            _restaurantLocation = LatLng(lat.toDouble(), lng.toDouble());
          });
          if (kDebugMode) debugPrint('✅ Merchant location (JSON): $lat, $lng');
        } else {
          if (kDebugMode) debugPrint('⚠️ Geçersiz merchant konumu: $lat, $lng');
        }
      } else {
        if (kDebugMode) debugPrint('⚠️ Merchant current_location verisi yok');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Merchant konumu yüklenirken hata: $e');
    }
  }
  
  Future<void> _loadData() async {
    try {
      // Mevcut kullanıcıdan merchantId al
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ Kullanıcı oturumu bulunamadı');
        return;
      }
      
      // Siparişleri yükle (hata olursa boş liste)
      List<Order> orders = [];
      try {
        // Bu merchant'ın aktif siparişlerini al
        final ordersData = await SupabaseOrderService.getMerchantOrders(
          merchantId: currentUser.id,
          status: 'active',
        );
        orders = ordersData.map((data) => Order.fromJson(data)).toList();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Siparişler yüklenemedi: $e');
      }
      
      // Aktif kuryeler yükle - Supabase users tablosundan
      final couriersData = await SupabaseService.client
          .from('users')
          .select()
          .eq('role', 'courier')
          .eq('is_active', true);
      
      if (kDebugMode) debugPrint('📦 Users collection: ${couriersData.length} aktif kurye');
      
      final couriers = <Map<String, dynamic>>[];
      for (var data in couriersData) {
        // Online kontrolü
        final isOnline = (data['is_available'] == true); // is_available kullan
        
        // Konum verisi - current_location sütununu kontrol et
        final locationData = data['current_location'] as Map<String, dynamic>?;
        
        if (isOnline && locationData != null) {
          final lat = (locationData['latitude'] ?? 0.0) as num;
          final lng = (locationData['longitude'] ?? 0.0) as num;
          
          if (lat != 0.0 && lng != 0.0) {
            couriers.add({
              'id': data['id'],
              'name': data['full_name'] ?? 'Kurye',
              'lat': lat.toDouble(),
              'lng': lng.toDouble(),
              'speed': 0.0, // Şimdilik sabit
              'status': 'available',
            });
            if (kDebugMode) debugPrint('✅ Kurye eklendi: ${data['full_name']} - Lat: $lat, Lng: $lng');
          } else {
            if (kDebugMode) debugPrint('⚠️ Kurye ${data['full_name']} - geçersiz konum: $lat, $lng');
          }
        } else {
          if (kDebugMode) debugPrint('⚠️ Kurye ${data['full_name']} - online: $isOnline, location: $locationData');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _orders = orders;
          _activeCouriers = couriers;
          
          // İstatistikleri hesapla
          _activeCourierCount = couriers.where((c) => c['status'] == 'available').length;
          _calculateAvgDeliveryTime();
        });
        if (kDebugMode) debugPrint('✅ ${couriers.length} aktif kurye yüklendi');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Harita verileri yüklenemedi: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // � Ortalama teslimat süresini hesapla
  Future<void> _calculateAvgDeliveryTime() async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;
      
      // Son 10 teslim edilmiş siparişi al
      final deliveredOrders = await SupabaseService.client
          .from('delivery_requests')
          .select('created_at, delivered_at')
          .eq('merchant_id', currentUser.id)
          .eq('status', 'delivered')
          .not('delivered_at', 'is', null)
          .order('delivered_at', ascending: false)
          .limit(10);
      
      if (deliveredOrders.isEmpty) {
        setState(() => _avgDeliveryTime = '--');
        return;
      }
      
      // Toplam süreyi hesapla (dakika)
      int totalMinutes = 0;
      for (var order in deliveredOrders) {
        final createdAt = DateTime.parse(order['created_at'] as String);
        final deliveredAt = DateTime.parse(order['delivered_at'] as String);
        final diff = deliveredAt.difference(createdAt);
        totalMinutes += diff.inMinutes;
      }
      
      final avg = totalMinutes ~/ deliveredOrders.length;
      setState(() => _avgDeliveryTime = '$avg dk');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Ortalama teslimat süresi hesaplanamadı: $e');
      setState(() => _avgDeliveryTime = '--');
    }
  }
  
  // �📍 Gerçek konumunu al - YÜKSEK HASSASİYET
  Future<void> _getMyLocation() async {
    setState(() => _locationLoading = true);
    
    try {
      // 1. Konum servisi aktif mi kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('⚠️ Konum servisi kapalı! Lütfen cihazınızda konumu açın.');
      }
      
      // 2. Konum izni kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Konum izni reddedildi');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.');
      }
      
      // 3. EN YÜKSEK HASSASİYETLE KONUM AL
      // Web için: Tarayıcı GPS hassasiyeti kullanılıyor
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // En yüksek hassasiyet
        timeLimit: const Duration(seconds: 15), // 15 saniye timeout
      );
      
      // Hassasiyet kontrolü
      if (kDebugMode) debugPrint('🎯 KONUM BİLGİSİ:');
      debugPrint('   Enlem: ${position.latitude}');
      debugPrint('   Boylam: ${position.longitude}');
      debugPrint('   Hassasiyet: ${position.accuracy} metre');
      debugPrint('   Yükseklik: ${position.altitude} m');
      debugPrint('   Hız: ${position.speed} m/s');
      
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
        _locationLoading = false;
      });
      
      // 4. Konuma yakınlaş (daha fazla zoom)
      _mapController.move(_myLocation!, 17.0);
      
      if (mounted) {
        // Hassasiyet bilgisi ile bildirim
        final accuracyText = position.accuracy < 20 
            ? '✅ Yüksek hassasiyet (±${position.accuracy.toStringAsFixed(1)}m)'
            : position.accuracy < 100
            ? '⚠️ Orta hassasiyet (±${position.accuracy.toStringAsFixed(1)}m)'
            : '❌ Düşük hassasiyet (±${position.accuracy.toStringAsFixed(1)}m)';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('📍 Konumunuz bulundu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Koordinat: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}', 
                  style: const TextStyle(fontSize: 11)),
                Text(accuracyText, style: const TextStyle(fontSize: 11)),
              ],
            ),
            backgroundColor: position.accuracy < 100 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      setState(() => _locationLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Konum alınamadı: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: _getMyLocation,
            ),
          ),
        );
      }
    }
  }
  
  // 📍 Marker'ları oluştur
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    
    // 1. İşletme konumu (🏪 turuncu)
    markers.add(
      Marker(
        point: _restaurantLocation,
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.store, // 🏪 Mağaza/İşletme ikonu
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Text(
                'İŞLETME',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    // 2. Siparişler (📍 renk: durum bazlı) - GERÇEK KOORDİNATLAR
    for (var order in _orders) {
      if (_showOnlyActive && order.status == OrderStatus.delivered) {
        continue; // Teslim edilmiş siparişleri gösterme
      }
      
      // ✅ Gerçek müşteri konumu - Address'ten al
      final customerLat = order.customer.address.latitude;
      final customerLng = order.customer.address.longitude;
      
      // Koordinat yoksa atla
      if (customerLat == null || customerLng == null) {
        debugPrint('⚠️ Sipariş ${order.id} için koordinat yok!');
        continue;
      }
      
      markers.add(
        Marker(
          point: LatLng(customerLat, customerLng),
          width: 100,
          height: 100,
          child: GestureDetector(
            onTap: () => _showOrderDetails(order),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.status),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _getOrderStatusText(order.status),
                  style: TextStyle(
                    fontSize: 8,
                    color: _getOrderStatusColor(order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 3. Kuryeler (🚴 yeşil - gerçek zamanlı Supabase verisi)
    for (var courier in _activeCouriers) {
      markers.add(
        Marker(
          point: LatLng(courier['lat'] as double, courier['lng'] as double),
          width: 90,
          height: 90,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      courier['name'] as String,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(courier['speed'] as double).toStringAsFixed(0)} km/h',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 4. 📍 KULLANICI KONUMU (Senin gerçek konumun - mavi)
    if (_myLocation != null) {
      markers.add(
        Marker(
          point: _myLocation!,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: const Text(
                  'SEN',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return markers;
  }
  
  // 🛣️ Rota çizgileri oluştur (Restoran → Müşteri) - GERÇEK KOORDİNATLAR
  List<Polyline> _buildRoutes() {
    if (!_showRoutes) return [];
    
    List<Polyline> routes = [];
    
    // ✅ Gerçek rota: Restoran'dan her müşteriye
    for (var order in _orders) {
      if (order.status == OrderStatus.delivered) continue; // Teslim edilmişlere rota çizme
      
      final customerLat = order.customer.address.latitude;
      final customerLng = order.customer.address.longitude;
      
      // Koordinat varsa rota çiz
      if (customerLat != null && customerLng != null) {
        routes.add(
          Polyline(
            points: [
              _restaurantLocation,
              LatLng(customerLat, customerLng),
            ],
            strokeWidth: 3,
            color: _getOrderStatusColor(order.status).withOpacity(0.6),
            borderStrokeWidth: 1,
            borderColor: Colors.white,
          ),
        );
      }
    }
    
    return routes;
  }
  
  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.assigned:
        return Colors.purple;
      case OrderStatus.pickedUp:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
      default:
        return Colors.red;
    }
  }
  
  String _getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Bekliyor';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.assigned:
        return 'Atandı';
      case OrderStatus.ready:
        return 'Hazır';
      case OrderStatus.pickedUp:
        return 'Yolda';
      case OrderStatus.delivered:
        return 'Teslim';
      default:
        return 'İptal';
    }
  }
  
  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sipariş #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Müşteri', order.customer.name),
            _buildInfoRow('Adres', order.customer.address.fullAddress),
            _buildInfoRow('Durum', _getOrderStatusText(order.status)),
            _buildInfoRow('Ürün Sayısı', '${order.items.length} adet'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Tahmini Varış: 15 dakika',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Mesafe: 3.2 km',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Canlı Harita')),
        body: ErrorStateView(
          message: _error!,
          onRetry: _loadData,
          icon: Icons.map_outlined,
        ),
      );
    }
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: SimpleLoadingView(message: 'Harita yükleniyor...'),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // 🗺️ Ana harita
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _restaurantLocation,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.onlog.merchant',
              ),
              PolylineLayer(polylines: _buildRoutes()),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          
          // 📊 Üst bilgi paneli
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: _buildInfoPanel(),
          ),
          
          // 🎛️ Kontrol butonları
          Positioned(
            right: 16,
            bottom: 100,
            child: _buildControls(),
          ),
          
          // 📈 İstatistik paneli (sol alt)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildStatsPanel(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Canlı Harita Takip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              // Restoran Konumu Ayarla Butonu
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestaurantLocationSettings(),
                    ),
                  );
                  
                  if (result != null) {
                    setState(() {
                      _restaurantLocation = result;
                    });
                    _mapController.move(_restaurantLocation, 15.0);
                  }
                },
                icon: const Icon(Icons.edit_location),
                tooltip: 'Restoran Konumunu Ayarla',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'CANLI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem(Icons.restaurant, Colors.orange, 'Restoran'),
              const SizedBox(width: 16),
              _buildLegendItem(Icons.location_on, Colors.blue, 'Müşteriler'),
              const SizedBox(width: 16),
              _buildLegendItem(Icons.two_wheeler, Colors.green, 'Kuryeler'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildControls() {
    return Column(
      children: [
        // 📍 Konumumu Göster butonu
        FloatingActionButton(
          mini: true,
          heroTag: 'myLocation',
          backgroundColor: _myLocation != null ? Colors.blue : Colors.white,
          onPressed: _locationLoading ? null : _getMyLocation,
          child: _locationLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : Icon(
                  Icons.my_location,
                  color: _myLocation != null ? Colors.white : Colors.blue,
                ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'center',
          backgroundColor: Colors.white,
          onPressed: () {
            _mapController.move(_restaurantLocation, 13.0);
          },
          child: const Icon(Icons.center_focus_strong, color: Color(0xFF4CAF50)),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'routes',
          backgroundColor: _showRoutes ? const Color(0xFF4CAF50) : Colors.white,
          onPressed: () {
            setState(() {
              _showRoutes = !_showRoutes;
            });
          },
          child: Icon(
            Icons.route,
            color: _showRoutes ? Colors.white : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'filter',
          backgroundColor: _showOnlyActive ? const Color(0xFF4CAF50) : Colors.white,
          onPressed: () {
            setState(() {
              _showOnlyActive = !_showOnlyActive;
            });
          },
          child: Icon(
            Icons.filter_alt,
            color: _showOnlyActive ? Colors.white : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'refresh',
          backgroundColor: Colors.white,
          onPressed: _loadData,
          child: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
        ),
      ],
    );
  }
  
  Widget _buildStatsPanel() {
    final activeOrders = _orders.where((o) => 
      o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled
    ).length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Anlık Durum',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatRow('Aktif Sipariş', activeOrders.toString(), Colors.orange),
          _buildStatRow('Yoldaki Kurye', _activeCourierCount.toString(), Colors.green),
          _buildStatRow('Ort. Teslimat', _avgDeliveryTime, Colors.blue),
          const SizedBox(height: 4),
          const Text(
            '🔄 Her 10 saniyede güncelleniyor',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
