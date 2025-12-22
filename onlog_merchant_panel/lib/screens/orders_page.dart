import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import '../services/trendyol_api_service.dart';
import '../widgets/loading_states.dart';
import '../utils/animations.dart';

/// Profesyonel Siparişler Sayfası - ONLOG Merchant Panel
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  String _selectedFilter = 'Tümü';
  final TextEditingController _searchController = TextEditingController();
  
  // 🔄 Loading States
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final merchantId = SupabaseService.currentUser?.id ?? '';
      
      // ⭐ YENİ: delivery_requests tablosundan çek (hem Yemek App hem manuel)
      final response = await SupabaseService.client
          .from('delivery_requests')
          .select('''
            *,
            courier:courier_id (
              id,
              full_name,
              phone
            )
          ''')
          .eq('merchant_id', merchantId)
          .order('created_at', ascending: false);

      // delivery_requests'i Order formatına dönüştür
      _orders = (response as List).map((e) {
        final deliveryLoc = e['delivery_location'] as Map<String, dynamic>?;
        final source = e['source'] as String?;
        final externalOrderId = e['external_order_id'] as String?;
        final orderId = e['id'] as String;
        
        // ⭐ Sipariş numarası: Yemek App'teyse external_order_id, değilse kısa ID
        final displayId = (source == 'yemek_app' && externalOrderId != null) 
            ? externalOrderId 
            : orderId.substring(0, 8);
        
        return Order(
          id: displayId, // ⭐ Düzgün sipariş numarası
          platform: source == 'yemek_app' ? OrderPlatform.yemeksepeti : OrderPlatform.manuel,
          customer: Customer(
            name: e['customer_name'] ?? 'Müşteri',
            phone: e['customer_phone'] ?? '',
            address: Address(
              fullAddress: deliveryLoc?['address'] ?? '',
              district: '',
              city: 'İstanbul',
              latitude: (deliveryLoc?['latitude'] as num?)?.toDouble(),
              longitude: (deliveryLoc?['longitude'] as num?)?.toDouble(),
            ),
          ),
          items: [],
          totalAmount: (e['declared_amount'] ?? 0.0).toDouble(),
          status: _mapDeliveryStatusToOrderStatus(e['status'] as String?),
          orderTime: DateTime.parse(e['created_at']),
          courierName: (e['courier'] as Map?)?['full_name'],
          courierPhone: (e['courier'] as Map?)?['phone'],
          specialNote: e['notes'] ?? '',
          deliveryLocation: deliveryLoc?['address'],
        );
      }).toList();
      
      if (mounted) {
        setState(() {
          _filteredOrders = _orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Siparişler yüklenirken bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  // delivery_requests status'unu Order status'una çevir
  OrderStatus _mapDeliveryStatusToOrderStatus(String? deliveryStatus) {
    switch (deliveryStatus) {
      case 'pending':
        return OrderStatus.pending;
      case 'assigned':
        return OrderStatus.assigned;
      case 'accepted':
        return OrderStatus.ready;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'completed':
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'rejected':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  void _filterOrders(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Tümü') {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders
            .where((order) =>
                order.platform.toString().split('.').last.toLowerCase() ==
                filter.toLowerCase())
            .toList();
      }
    });
  }

  void _searchOrders(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _selectedFilter == 'Tümü'
            ? _orders
            : _orders
                .where((order) =>
                    order.platform.toString().split('.').last.toLowerCase() ==
                    _selectedFilter.toLowerCase())
                .toList();
      } else {
        _filteredOrders = _orders.where((order) {
          final searchLower = query.toLowerCase();
          final matchesSearch = 
              order.id.toLowerCase().contains(searchLower) ||
              order.customer.name.toLowerCase().contains(searchLower) ||
              order.customer.phone.contains(query); // Telefon araması
          final matchesFilter = _selectedFilter == 'Tümü' ||
              order.platform.toString().split('.').last.toLowerCase() ==
                  _selectedFilter.toLowerCase();
          return matchesSearch && matchesFilter;
        }).toList();
      }
    });
  }

  Color _getPlatformColor(OrderPlatform platform) {
    switch (platform) {
      case OrderPlatform.trendyol:
        return const Color(0xFFFF6000);
      case OrderPlatform.yemeksepeti:
        return const Color(0xFFFF0000);
      case OrderPlatform.getir:
        return const Color(0xFF5D3EBC);
      case OrderPlatform.bitaksi:
        return const Color(0xFFFFD300);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  String _getPlatformLabel(OrderPlatform platform) {
    switch (platform) {
      case OrderPlatform.trendyol:
        return 'TRENDYOL';
      case OrderPlatform.yemeksepeti:
        return 'YEMEKSEPETI';
      case OrderPlatform.getir:
        return 'GETİR';
      case OrderPlatform.bitaksi:
        return 'BİTAKSİ';
      default:
        return 'MANUEL';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFA726);
      case OrderStatus.assigned:
        return const Color(0xFF42A5F5);
      case OrderStatus.preparing:
        return const Color(0xFF66BB6A);
      case OrderStatus.ready:
        return const Color(0xFF26A69A);
      case OrderStatus.pickedUp:
        return const Color(0xFF5C6BC0);
      case OrderStatus.delivered:
        return const Color(0xFF4CAF50);
      case OrderStatus.cancelled:
        return const Color(0xFFEF5350);
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.assigned:
        return 'Atandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.ready:
        return 'Hazır';
      case OrderStatus.pickedUp:
        return 'Teslim Alındı';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal';
    }
  }

  void _showOrderDetails(Order order) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(order.platform),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getPlatformLabel(order.platform),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 28), // 32 → 28 (overflow fix)
                
                // Müşteri Bilgileri
                _buildDetailRow(Icons.person_outline, 'Müşteri', order.customer.name),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on_outlined, 'Adres', 
                    '${order.customer.address.district}, ${order.customer.address.city}'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.phone_outlined, 'Telefon', order.customer.phone),
              
              const Divider(height: 32),
              
              // Sipariş Detayları
              _buildDetailRow(Icons.inventory_2_outlined, 'Ürün Sayısı', 
                  '${order.items.length} ürün'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.attach_money, 'Toplam Tutar', 
                  '₺${order.totalAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Sipariş Zamanı', 
                  _formatDate(order.orderTime)),
              
              const Divider(height: 32),
              
              // Durum Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(order.status).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Durum: ${_getStatusLabel(order.status)}',
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Trendyol Sipariş İşlemleri (sadece Trendyol siparişlerinde göster)
              if (order.platform == OrderPlatform.trendyol)
                _buildTrendyolActions(order),
              
              // Test Butonları - Diğer platformlar için (Ses testi)
              if (order.platform != OrderPlatform.trendyol)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.science, color: Colors.blue[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Test Butonları (Ses Testi)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await SupabaseOrderService.updateOrderStatus(
                                  orderId: order.id,
                                  status: OrderStatus.assigned.name,
                                );
                                _loadOrders();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delivery_dining, size: 18),
                              label: const Text('Kurye Ata', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await SupabaseOrderService.updateOrderStatus(
                                  orderId: order.id,
                                  status: OrderStatus.delivered.name,
                                );
                                _loadOrders();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Teslim Et', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // ✨ Scale + Fade animasyonu
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 
                    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ONLOG Satıcı',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50)),
            onPressed: () {
              // Teslimat Ekle butonu
            },
            tooltip: 'Teslimat Ekle',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(isDesktop),
    );
  }

  // 🔄 Ana body - Loading states kontrolü
  Widget _buildBody(bool isDesktop) {
    // Hata durumu
    if (_error != null) {
      return ErrorStateView(
        message: _error!,
        onRetry: _loadOrders,
      );
    }

    // Yükleniyor durumu
    if (_isLoading) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: _buildStatsRowShimmer(),
          ),
          Expanded(
            child: ListShimmer(
              itemCount: 5,
              shimmerItem: const OrderCardShimmer(),
            ),
          ),
        ],
      );
    }

    // Boş durum
    if (_orders.isEmpty) {
      return EmptyStateView(
        title: 'Henüz Sipariş Yok',
        message: 'Siparişler geldiğinde burada görünecek',
        icon: Icons.shopping_bag_outlined,
      );
    }

    // Normal liste
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                _buildStatsRow(),
                const SizedBox(height: 24),
                
                // Search Bar
                _buildSearchBar(),
                const SizedBox(height: 16),
                
                // Filters
                _buildFilters(),
                const SizedBox(height: 16),
                
                // Orders List
                _filteredOrders.isEmpty
                    ? EmptyStateView(
                        title: 'Sonuç Bulunamadı',
                        message: 'Arama kriterlerinize uygun sipariş bulunamadı',
                        icon: Icons.search_off,
                      )
                    : _buildOrdersList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📊 Stats Row Shimmer
  Widget _buildStatsRowShimmer() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 4),
            child: const StatCardShimmer(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final todayOrders = _orders.where((o) {
      final now = DateTime.now();
      return o.orderTime.year == now.year &&
          o.orderTime.month == now.month &&
          o.orderTime.day == now.day;
    }).length;

    final todayRevenue = _orders.where((o) {
      final now = DateTime.now();
      return o.orderTime.year == now.year &&
          o.orderTime.month == now.month &&
          o.orderTime.day == now.day;
    }).fold<double>(0, (sum, o) => sum + o.totalAmount);

    final pendingOrders = _orders.where((o) => o.status == OrderStatus.pending).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatMiniCard(
            'Bugünkü Siparişler',
            todayOrders.toString(),
            Icons.shopping_bag_outlined,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMiniCard(
            'Bugünkü Gelir',
            '₺${todayRevenue.toStringAsFixed(2)}',
            Icons.attach_money,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMiniCard(
            'Bekleyen Siparişler',
            pendingOrders.toString(),
            Icons.pending_outlined,
            const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildStatMiniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 Arama Çubuğu
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchOrders,
        decoration: InputDecoration(
          hintText: 'Sipariş No, Müşteri Adı veya Telefon ara...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _searchOrders('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Tümü butonu
          _buildFilterChip('Tümü', null),
          const SizedBox(width: 6),
          _buildFilterChip('Trendyol', const Color(0xFFFF6000)),
          const SizedBox(width: 6),
          _buildFilterChip('Getir', const Color(0xFF5D3EBC)),
          const SizedBox(width: 6),
          _buildFilterChip('Yemeksepeti', const Color(0xFFFF0000)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color? color) {
    final isSelected = _selectedFilter == label;
    
    return GestureDetector(
      onTap: () => _filterOrders(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? const Color(0xFF4CAF50))
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (color ?? const Color(0xFF4CAF50))
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sipariş bulunamadı',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        // ✨ Kademeli giriş animasyonu
        return CardAnimations.fadeInCard(
          _buildOrderCard(order),
          delay: index * 50, // Her kart 50ms sonra giriş yapar
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}), // Hafif highlight efekti için
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showOrderDetails(order),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header: Platform Badge + Order ID
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(order.platform),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPlatformLabel(order.platform),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusLabel(order.status),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Customer Info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.customer.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Address
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.customer.address.district}, ${order.customer.address.city}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Items Count
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${order.items.length} ürün',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                
                // Divider with pattern
                const SizedBox(height: 12),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.yellow[700]!,
                        Colors.black,
                      ],
                      stops: const [0.0, 0.5],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      tileMode: TileMode.repeated,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  // Trendyol Sipariş İşlem Butonları
  Widget _buildTrendyolActions(Order order) {
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(12), // 16 → 12 (overflow fix)
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange[50]!,
                Colors.orange[100]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[300]!, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // 8 → 6 (overflow fix)
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 18), // 20 → 18 (overflow fix)
                  ),
                  const SizedBox(width: 10), // 12 → 10 (overflow fix)
                  const Text(
                    'Trendyol Sipariş İşlemleri',
                    style: TextStyle(
                      fontSize: 14, // 15 → 14 (overflow fix)
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // 16 → 12 (overflow fix)

              // Action Buttons
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                )
              else
                Row(
                  children: [
                    // Kabul Et - Pending durumunda
                    if (order.status == OrderStatus.pending)
                      _buildActionButton(
                        icon: Icons.check_circle_outline,
                        label: 'Kabul Et',
                        color: Colors.green,
                        onPressed: () async {
                          setState(() => isLoading = true);
                          await _handleTrendyolAction(
                            order,
                            'accept',
                            'Sipariş kabul edildi',
                          );
                          setState(() => isLoading = false);
                        },
                      ),

                    // Hazır - Preparing durumunda
                    if (order.status == OrderStatus.preparing) ...[
                      if (order.status != OrderStatus.pending) const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.restaurant_menu,
                        label: 'Hazır',
                        color: Colors.blue,
                        onPressed: () async {
                          setState(() => isLoading = true);
                          await _handleTrendyolAction(
                            order,
                            'ready',
                            'Sipariş hazır olarak işaretlendi',
                          );
                          setState(() => isLoading = false);
                        },
                      ),
                    ],

                    // Yola Çıktı - Ready durumunda
                    if (order.status == OrderStatus.ready) ...[
                      if (order.status != OrderStatus.pending) const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delivery_dining,
                        label: 'Yola Çıktı',
                        color: Colors.purple,
                        onPressed: () async {
                          setState(() => isLoading = true);
                          await _handleTrendyolAction(
                            order,
                            'shipped',
                            'Sipariş yola çıktı',
                          );
                          setState(() => isLoading = false);
                        },
                      ),
                    ],

                    // Teslim Edildi - PickedUp durumunda
                    if (order.status == OrderStatus.pickedUp) ...[
                      if (order.status != OrderStatus.pending) const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.task_alt,
                        label: 'Teslim Edildi',
                        color: Colors.green[700]!,
                        onPressed: () async {
                          setState(() => isLoading = true);
                          await _handleTrendyolAction(
                            order,
                            'delivered',
                            'Sipariş teslim edildi',
                          );
                          setState(() => isLoading = false);
                        },
                      ),
                    ],

                    // İptal Et - Her zaman göster (delivered hariç)
                    if (order.status != OrderStatus.delivered &&
                        order.status != OrderStatus.cancelled) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.cancel_outlined,
                        label: 'İptal Et',
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Siparişi İptal Et'),
                              content: const Text(
                                'Bu siparişi iptal etmek istediğinizden emin misiniz?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Vazgeç'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('İptal Et'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setState(() => isLoading = true);
                            await _handleTrendyolAction(
                              order,
                              'cancel',
                              'Sipariş iptal edildi',
                            );
                            setState(() => isLoading = false);
                          }
                        },
                      ),
                    ],
                  ],
                ),

              // Info text
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Durum değişiklikleri Trendyol API\'ye gönderilir',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Flexible(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(0, 44), // Minimum dokunma alanı
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTrendyolAction(
    Order order,
    String action,
    String successMessage,
  ) async {
    try {
      final trendyolService = TrendyolApiService();
      
      // API çağrısı yap
      switch (action) {
        case 'accept':
          await trendyolService.acceptOrder(order.id);
          await SupabaseOrderService.updateOrderStatus(
            orderId: order.id,
            status: OrderStatus.preparing.name,
          );
          break;
        case 'ready':
          await trendyolService.markOrderReady(order.id);
          await SupabaseOrderService.updateOrderStatus(
            orderId: order.id,
            status: OrderStatus.ready.name,
          );
          break;
        case 'shipped':
          await trendyolService.markOrderShipped(order.id);
          await SupabaseOrderService.updateOrderStatus(
            orderId: order.id,
            status: OrderStatus.pickedUp.name,
          );
          break;
        case 'delivered':
          await trendyolService.markOrderDelivered(order.id);
          await SupabaseOrderService.updateOrderStatus(
            orderId: order.id,
            status: OrderStatus.delivered.name,
          );
          break;
        case 'cancel':
          // Trendyol cancel reason IDs:
          // 1 = Ürün tükendi
          // 2 = Restoran kapalı
          // 3 = Diğer
          await trendyolService.cancelOrder(order.id, reasonId: 3);
          await SupabaseOrderService.updateOrderStatus(
            orderId: order.id,
            status: OrderStatus.cancelled.name,
          );
          break;
      }

      // Başarılı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(successMessage),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Siparişleri yenile
        await _loadOrders();

        // Dialogu kapat
        Navigator.pop(context);
      }
    } catch (e) {
      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Hata: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
