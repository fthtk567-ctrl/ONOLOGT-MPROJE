import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:onlog_shared/onlog_shared.dart';

/// 🖥️ MODERN WEB/DESKTOP SİPARİŞLER SAYFASI
/// Responsive, küçük butonlar, modern tasarım
class OrdersPageWeb extends StatefulWidget {
  const OrdersPageWeb({super.key});

  @override
  State<OrdersPageWeb> createState() => _OrdersPageWebState();
}

class _OrdersPageWebState extends State<OrdersPageWeb> {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  String _selectedFilter = 'Tümü';
  final TextEditingController _searchController = TextEditingController();
  
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
      
      // ⭐ YENİ: delivery_requests tablosundan çek (hem Yemek App hem manuel teslimatlar)
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
      
      _filteredOrders = _orders;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Siparişler yüklenemedi: $e';
      });
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
        _filteredOrders = _orders.where((order) {
          switch (filter) {
            case 'Bekleyen':
              return order.status == 'WAITING_COURIER';
            case 'Aktif':
              return order.status == 'ASSIGNED' || 
                     order.status == 'ACCEPTED' || 
                     order.status == 'PICKED_UP';
            case 'Tamamlanan':
              return order.status == 'DELIVERED';
            case 'İptal':
              return order.status == 'CANCELLED';
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🖥️ Web için max width sınırı
    final maxWidth = kIsWeb ? 1400.0 : double.infinity;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                        : _buildOrdersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Siparişler',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredOrders.length} sipariş',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // 🔍 Arama
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Sipariş ara...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              // TODO: Arama filtresi
            },
          ),
        ),
        
        const SizedBox(width: 16),
        
        // ➕ Yeni Sipariş
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Yeni sipariş ekranı
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Yeni Sipariş', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ['Tümü', 'Bekleyen', 'Aktif', 'Tamamlanan', 'İptal'];
    
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return FilterChip(
            label: Text(
              filter,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFF1A1F36),
              ),
            ),
            selected: isSelected,
            onSelected: (_) => _filterOrders(filter),
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sipariş bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor = _getStatusColor(order.status.toString());
    String statusText = _getStatusText(order.status.toString());
    
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              // 📦 Sipariş İkonu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_bag, color: statusColor, size: 24),
              ),
              
              const SizedBox(width: 16),
              
              // Sipariş Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sipariş ${order.id}', // ⭐ # kaldırıldı, artık YO-292016 gibi gösterecek
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.customer.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tutar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.orderTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // İşlemler
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 12),
                        Text('Detaylar', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (order.status.toString().contains('WAITING'))
                    const PopupMenuItem(
                      value: 'call_courier',
                      child: Row(
                        children: [
                          Icon(Icons.delivery_dining, size: 18),
                          SizedBox(width: 12),
                          Text('Kurye Çağır', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('İptal Et', style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  // TODO: İşlem yap
                },
              ),
            ],
          ),
          
          // Adres ve Notlar
          if (order.deliveryLocation != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryLocation!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAITING_COURIER':
        return const Color(0xFFFF9800);
      case 'ASSIGNED':
      case 'ACCEPTED':
        return const Color(0xFF2196F3);
      case 'PICKED_UP':
        return const Color(0xFF9C27B0);
      case 'DELIVERED':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'WAITING_COURIER':
        return 'Beklemede';
      case 'ASSIGNED':
        return 'Atandı';
      case 'ACCEPTED':
        return 'Kabul Edildi';
      case 'PICKED_UP':
        return 'Yolda';
      case 'DELIVERED':
        return 'Teslim Edildi';
      case 'CANCELLED':
        return 'İptal';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}
