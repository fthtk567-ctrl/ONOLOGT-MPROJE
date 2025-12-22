import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  List<Map<String, dynamic>> _activeCouriers = [];
  List<Map<String, dynamic>> _merchants = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Her 10 saniyede bir otomatik yenile (courier app 30 saniyede konum gönderiyor)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Kuryeleri yükle
      final couriersResponse = await SupabaseService.from('users')
          .select()
          .eq('role', 'courier');
      
      // Merchant'ları yükle
      final merchantsResponse = await SupabaseService.from('users')
          .select()
          .eq('role', 'merchant');
      
      setState(() {
        _activeCouriers = List<Map<String, dynamic>>.from(couriersResponse);
        _merchants = List<Map<String, dynamic>>.from(merchantsResponse);
        _isLoading = false;
      });
      
      print('📍 Yüklenen kuryeler: ${_activeCouriers.length}');
      print('🏪 Yüklenen işletmeler: ${_merchants.length}');
      
      for (var courier in _activeCouriers) {
        print('  - ${courier['full_name']}: ${courier['current_location']} (${courier['is_available'] ? 'Müsait' : 'Meşgul'})');
      }
      
      for (var merchant in _merchants) {
        print('  - ${merchant['business_name']}: ${merchant['current_location']}');
      }
    } catch (e) {
      print('❌ Veri yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Canlı İzleme'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Kuryeler', _activeCouriers.length.toString(), Icons.delivery_dining, Colors.green),
                      _buildStatCard('İşletmeler', _merchants.length.toString(), Icons.store, Colors.blue),
                    ],
                  ),
                ),
                Expanded(
                  child: (_activeCouriers.isEmpty && _merchants.isEmpty)
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Henüz veri yok', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            ],
                          ),
                        )
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(41.0082, 28.9784), // Varsayılan: İstanbul merkez
                            initialZoom: 12,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.onlog.admin',
                            ),
                            MarkerLayer(
                              markers: _buildAllMarkers(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildAllMarkers() {
    List<Marker> markers = [];
    
    // Kurye marker'ları
    for (var courier in _activeCouriers) {
      final location = courier['current_location'];
      
      if (location != null && location is Map) {
        // Hem eski format (lat/lng) hem yeni format (latitude/longitude) destekle
        final lat = location['latitude'] ?? location['lat'];
        final lng = location['longitude'] ?? location['lng'];
        
        if (lat != null && lng != null) {
          final latDouble = lat is double ? lat : double.tryParse(lat.toString());
          final lngDouble = lng is double ? lng : double.tryParse(lng.toString());
          
          if (latDouble != null && lngDouble != null) {
            print('📍 Kurye marker eklendi: ${courier['full_name']} - $latDouble, $lngDouble');
            
            markers.add(
              Marker(
                point: LatLng(latDouble, lngDouble),
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: courier['is_available'] == true ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        courier['full_name']?.toString().split(' ')[0] ?? 'Kurye',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(
                      Icons.delivery_dining,
                      color: courier['is_available'] == true ? Colors.green : Colors.orange,
                      size: 30,
                    ),
                  ],
                ),
              ),
            );
          } else {
            print('⚠️ ${courier['full_name']}: Konum parse edilemedi - lat: $lat, lng: $lng');
          }
        } else {
          print('⚠️ ${courier['full_name']}: Konum bilgisi eksik - location: $location');
        }
      } else {
        print('⚠️ ${courier['full_name']}: current_location null veya Map değil');
      }
    }
    
    // Merchant marker'ları
    for (var merchant in _merchants) {
      final location = merchant['current_location'];
      
      if (location != null && location is Map) {
        // Hem eski format (lat/lng) hem yeni format (latitude/longitude) destekle
        final lat = location['latitude'] ?? location['lat'];
        final lng = location['longitude'] ?? location['lng'];
        
        if (lat != null && lng != null) {
          final latDouble = lat is double ? lat : double.tryParse(lat.toString());
          final lngDouble = lng is double ? lng : double.tryParse(lng.toString());
          
          if (latDouble != null && lngDouble != null) {
            print('🏪 Merchant marker eklendi: ${merchant['business_name']} - $latDouble, $lngDouble');
            
            markers.add(
              Marker(
                point: LatLng(latDouble, lngDouble),
                width: 100,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (merchant['business_name'] ?? 'İşletme').toString().length > 15
                            ? '${(merchant['business_name'] ?? 'İşletme').toString().substring(0, 15)}...'
                            : (merchant['business_name'] ?? 'İşletme').toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.store,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ],
                ),
              ),
            );
          } else {
            print('⚠️ ${merchant['business_name']}: Konum parse edilemedi - lat: $lat, lng: $lng');
          }
        } else {
          print('⚠️ ${merchant['business_name']}: Konum bilgisi eksik - location: $location');
        }
      } else {
        print('⚠️ Merchant ${merchant['business_name']} - Konum alınamadı');
      }
    }
    
    print('📍 Haritada gösterilen kuryeler: ${_activeCouriers.length}, işletmeler: ${_merchants.length}, toplam marker: ${markers.length}');
    return markers;
  }
}
