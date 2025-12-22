import 'package:flutter/material.dart';
import 'dart:async';
import 'package:onlog_shared/onlog_shared.dart';
import '../services/location_service.dart';
import '../widgets/courier_tracking_map.dart';

// TODO: Bu ekran merchant panel için tasarlandı, courier app'te kullanılmayacak
// Merchant panel'e taşınmalı veya silinmeli

class CourierTrackingPage extends StatefulWidget {
  const CourierTrackingPage({super.key});

  @override
  State<CourierTrackingPage> createState() => _CourierTrackingPageState();
}

class _CourierTrackingPageState extends State<CourierTrackingPage> {
  List<Order> _activeOrders = [];
  List<CourierLocation> _courierLocations = [];
  Timer? _refreshTimer;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _startPeriodicUpdates();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    LocationService.stopLocationTracking();
    super.dispose();
  }
  
  void _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: OrderService courier app'te yok, merchant panel özelliği
      // Mock data kullan veya servisi ekle
      _activeOrders = []; // Geçici olarak boş liste
      
      // Kurye konumlarını yükle
      await _loadCourierLocations();
      
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenirken hata: $e')),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _loadCourierLocations() async {
    // Şu an için demo kurye konumları
    // Gerçek uygulamada Supabase'den gelecek
    _courierLocations = [
      CourierLocation(
        courierId: 'courier_001',
        courierName: 'Ahmet Kurye',
        latitude: 41.0082,
        longitude: 28.9784,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        isActive: true,
        orderId: _activeOrders.isNotEmpty ? _activeOrders[0].id : null,
      ),
      CourierLocation(
        courierId: 'courier_002',
        courierName: 'Mehmet Kurye',
        latitude: 41.0122,
        longitude: 28.9804,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        isActive: true,
      ),
      CourierLocation(
        courierId: 'courier_003',
        courierName: 'Fatma Kurye',
        latitude: 41.0062,
        longitude: 28.9764,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isActive: false,
      ),
    ];
  }
  
  void _startPeriodicUpdates() {
    // Her 30 saniyede bir güncelle
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }
  
  void _onOrderSelected(String orderId) {
    _showOrderBottomSheet(orderId);
  }
  
  void _showOrderBottomSheet(String orderId) {
    try {
      Order order = _activeOrders.firstWhere(
        (o) => o.id == orderId,
      );
      _showOrderDetailsModal(order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sipariş bulunamadı')),
        );
      }
    }
  }
  
  void _showOrderDetailsModal(Order order) {
    
    // Siparişe atanmış kurye var mı?
    CourierLocation? assignedCourier;
    try {
      assignedCourier = _courierLocations.firstWhere(
        (c) => c.orderId == order.id,
      );
    } catch (e) {
      assignedCourier = null;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOrderDetailCard(order),
                    const SizedBox(height: 16),
                    if (assignedCourier != null) ...[
                      _buildCourierCard(assignedCourier, order),
                      const SizedBox(height: 16),
                    ],
                    _buildLocationCard(order),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderDetailCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sipariş Detayları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const Divider(),
            _buildDetailRow('Sipariş ID', order.id),
            _buildDetailRow('Müşteri', order.customer.name),
            _buildDetailRow('Telefon', order.customer.phone),
            _buildDetailRow('Tutar', '${order.totalAmount.toStringAsFixed(2)} TL'),
            _buildDetailRow('Sipariş Saati', _formatDateTime(order.orderTime)),
            const SizedBox(height: 8),
            Text(
              'Ürünler:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('• ${item.name} x${item.quantity}'),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCourierCard(CourierLocation courier, Order order) {
    Map<String, double> orderCoords = LocationService.getOrderCoordinates(order);
    double distance = courier.distanceToCustomer(
      orderCoords['latitude']!,
      orderCoords['longitude']!,
    );
    int eta = courier.estimatedArrivalTime(
      orderCoords['latitude']!,
      orderCoords['longitude']!,
    );
    
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kurye Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: courier.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    courier.isActive ? 'Aktif' : 'Pasif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('Kurye Adı', courier.courierName),
            _buildDetailRow('Mesafe', '${distance.toStringAsFixed(1)} km'),
            _buildDetailRow('Tahmini Varış', '$eta dakika'),
            _buildDetailRow('Son Güncelleme', _formatTime(courier.timestamp)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationCard(Order order) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Teslimat Adresi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(order.customer.address.fullAddress),
            const SizedBox(height: 8),
            _buildDetailRow('İlçe', order.customer.address.district),
            _buildDetailRow('İl', order.customer.address.city),
            if (order.customer.address.buildingNo != null)
              _buildDetailRow('Bina No', order.customer.address.buildingNo!),
            if (order.customer.address.floor != null)
              _buildDetailRow('Kat', order.customer.address.floor!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Bekliyor';
        break;
      case OrderStatus.assigned:
        color = Colors.blue;
        text = 'Atandı';
        break;
      case OrderStatus.preparing:
        color = Colors.yellow[700]!;
        text = 'Hazırlanıyor';
        break;
      case OrderStatus.ready:
        color = Colors.cyan;
        text = 'Hazır';
        break;
      case OrderStatus.pickedUp:
        color = Colors.purple;
        text = 'Yolda';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Teslim';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'İptal';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatTime(DateTime time) {
    Duration difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dk önce';
    } else {
      return '${difference.inHours} sa önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurye Takibi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle_tracking':
                  LocationService.startLocationTracking();
                  break;
                case 'stop_tracking':
                  LocationService.stopLocationTracking();
                  break;

              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'toggle_tracking',
                child: ListTile(
                  leading: Icon(Icons.gps_fixed),
                  title: Text('Konum Takibi Başlat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'stop_tracking',
                child: ListTile(
                  leading: Icon(Icons.gps_off),
                  title: Text('Konum Takibi Durdur'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),

            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Kurye konumları yükleniyor...'),
                ],
              ),
            )
          : Column(
              children: [
                // İstatistik kartları
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Aktif Sipariş',
                          '${_activeOrders.length}',
                          Icons.receipt,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Aktif Kurye',
                          '${_courierLocations.where((c) => c.isActive).length}',
                          Icons.delivery_dining,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Harita
                Expanded(
                  child: CourierTrackingMap(
                    orders: _activeOrders,
                    couriers: _courierLocations,
                    onOrderSelected: _onOrderSelected,
                    showCurrentLocation: true,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
