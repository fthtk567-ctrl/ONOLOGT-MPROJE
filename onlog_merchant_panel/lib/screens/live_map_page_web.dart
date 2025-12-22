import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:onlog_shared/onlog_shared.dart';

/// 🗺️ Modern Web Harita Sayfası
class LiveMapPageWeb extends StatefulWidget {
  const LiveMapPageWeb({super.key});

  @override
  State<LiveMapPageWeb> createState() => _LiveMapPageWebState();
}

class _LiveMapPageWebState extends State<LiveMapPageWeb> {
  final MapController _mapController = MapController();
  
  List<Order> _orders = [];
  bool _isLoading = true;
  LatLng _restaurantLocation = const LatLng(37.57, 32.79);
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) return;
      
      // Restoran konumu
      final userData = await SupabaseService.client
          .from('users')
          .select('current_location')
          .eq('id', currentUser.id)
          .single();
      
      final locationData = userData['current_location'] as Map<String, dynamic>?;
      if (locationData != null) {
        final lat = (locationData['latitude'] ?? 0.0) as num;
        final lng = (locationData['longitude'] ?? 0.0) as num;
        if (lat != 0.0 && lng != 0.0) {
          _restaurantLocation = LatLng(lat.toDouble(), lng.toDouble());
        }
      }
      
      // Aktif siparişler
      final ordersData = await SupabaseService.client
          .from('orders')
          .select('*, courier:users!orders_courier_id_fkey(id, full_name, current_location)')
          .eq('merchant_id', currentUser.id)
          .inFilter('status', ['ASSIGNED', 'ACCEPTED', 'PICKED_UP'])
          .order('created_at', ascending: false);
      
      setState(() {
        _orders = (ordersData as List).map((o) => Order.fromJson(o)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Harita veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : Row(
              children: [
                // Sol Panel - İstatistikler
                Container(
                  width: 320,
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Başlık
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.map, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Canlı Harita',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // İstatistik Kartları
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildStatCard(
                              'Aktif Teslimatlar',
                              '${_orders.length}',
                              Icons.local_shipping,
                              const Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              'Kuryeler',
                              '${_orders.where((o) => o.courierName != null).length}',
                              Icons.two_wheeler,
                              const Color(0xFF2196F3),
                            ),
                            const SizedBox(height: 12),
                            _buildStatCard(
                              'Bekleyen',
                              '${_orders.where((o) => o.status == OrderStatus.pending).length}',
                              Icons.access_time,
                              const Color(0xFFFF9800),
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(height: 1),
                      
                      // Sipariş Listesi
                      Expanded(
                        child: _orders.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Aktif teslimat yok',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  return _buildOrderCard(order);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                
                // Sağ Taraf - Harita
                Expanded(
                  child: FlutterMap(
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
                      MarkerLayer(
                        markers: [
                          // Restoran marker
                          Marker(
                            point: _restaurantLocation,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.store,
                              color: Color(0xFF4CAF50),
                              size: 32,
                            ),
                          ),
                          // Sipariş konumları
                          ..._orders.map((order) {
                            if (order.deliveryLocation == null) return null;
                            try {
                              final coords = order.deliveryLocation!.split(',');
                              final lat = double.parse(coords[0].trim());
                              final lng = double.parse(coords[1].trim());
                              return Marker(
                                point: LatLng(lat, lng),
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                  color: _getStatusColor(order.status.name),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              );
                            } catch (e) {
                              return null;
                            }
                          }).whereType<Marker>(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderCard(Order order) {
    final statusText = _getStatusText(order.status.name);
    final statusColor = _getStatusColor(order.status.name);
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${order.id.substring(0, 8)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customer.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.fullDeliveryLocation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Kurye Bekliyor';
      case 'assigned':
        return 'Atandı';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'pickedUp':
        return 'Alındı';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'assigned':
        return const Color(0xFF2196F3);
      case 'preparing':
        return const Color(0xFF9C27B0);
      case 'ready':
        return const Color(0xFF00BCD4);
      case 'pickedUp':
        return const Color(0xFF4CAF50);
      case 'delivered':
        return const Color(0xFF607D8B);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }
}
