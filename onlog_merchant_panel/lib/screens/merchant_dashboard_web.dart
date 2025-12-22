import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'call_courier_screen.dart';

/// 🖥️ PROFESSIONAL WEB/DESKTOP DASHBOARD
/// Modern, geniş ekran odaklı tasarım
class MerchantDashboardWeb extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MerchantDashboardWeb({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MerchantDashboardWeb> createState() => _MerchantDashboardWebState();
}

class _MerchantDashboardWebState extends State<MerchantDashboardWeb> {
  // 📊 Dashboard İstatistikleri
  int _todayOrders = 0;
  double _todayRevenue = 0.0;
  int _activeDeliveries = 0;
  int _pendingOrders = 0;
  
  // � Merchant Location
  final Map<String, dynamic> _merchantLocation = {'lat': 41.0082, 'lng': 28.9784}; // Default Istanbul
  
  // �🔄 Loading
  bool _isLoading = true;
  
  // 📡 Subscriptions
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Bugünkü siparişleri al
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final orders = await SupabaseService.client
          .from('orders')
          .select()
          .eq('merchant_id', widget.restaurantId)
          .gte('created_at', startOfDay.toIso8601String());
      
      _todayOrders = orders.length;
      _todayRevenue = orders.fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0.0));
      _activeDeliveries = orders.where((o) => 
        o['status'] == 'ASSIGNED' || 
        o['status'] == 'ACCEPTED' || 
        o['status'] == 'PICKED_UP'
      ).length;
      _pendingOrders = orders.where((o) => o['status'] == 'WAITING_COURIER').length;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Dashboard yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Açık gri arka plan
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Başlık
          _buildHeader(),
          const SizedBox(height: 32),
          
          // 📊 İstatistik Kartları
          _buildStatCards(),
          const SizedBox(height: 32),
          
          // 📋 Son Siparişler + Hızlı İşlemler
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRecentOrders(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildQuickActions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş Geldiniz, ${widget.restaurantName}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bugünün özeti ve aktif siparişleriniz',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        // 🔔 Bildirim İkonu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_outlined, size: 28),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Bugünkü Siparişler',
            value: _todayOrders.toString(),
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF4CAF50), // Yeşil
            trend: '+12%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Günlük Ciro',
            value: '₺${_todayRevenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: const Color(0xFF2E7D32), // Koyu yeşil
            trend: '+8%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Aktif Teslimatlar',
            value: _activeDeliveries.toString(),
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF66BB6A), // Açık yeşil
            trend: '',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Bekleyen Siparişler',
            value: _pendingOrders.toString(),
            icon: Icons.pending_actions,
            color: const Color(0xFF81C784), // Daha açık yeşil
            trend: '',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C48C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Color(0xFF00C48C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1F36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Siparişler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 24),
          // TODO: Gerçek siparişler buraya gelecek
          _buildOrderItem(
            orderNumber: '#1234',
            customerName: 'Ahmet Yılmaz',
            status: 'Hazırlanıyor',
            amount: '₺125.50',
            time: '10 dk önce',
          ),
          const Divider(height: 32),
          _buildOrderItem(
            orderNumber: '#1235',
            customerName: 'Ayşe Demir',
            status: 'Kuryede',
            amount: '₺89.00',
            time: '15 dk önce',
          ),
          const Divider(height: 32),
          _buildOrderItem(
            orderNumber: '#1236',
            customerName: 'Mehmet Kaya',
            status: 'Beklemede',
            amount: '₺156.75',
            time: 'Şimdi',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required String orderNumber,
    required String customerName,
    required String status,
    required String amount,
    required String time,
  }) {
    Color statusColor;
    if (status == 'Beklemede') {
      statusColor = const Color(0xFFFF9800); // Turuncu (uyarı için)
    } else if (status == 'Hazırlanıyor') {
      statusColor = const Color(0xFF2196F3); // Mavi (işlem için)
    } else {
      statusColor = const Color(0xFF4CAF50); // Yeşil (başarılı için)
    }

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long, color: statusColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$orderNumber - $customerName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionCard(
          title: 'Yeni Sipariş',
          subtitle: 'Manuel sipariş ekle',
          icon: Icons.add_shopping_cart,
          color: const Color(0xFF4CAF50), // Yeşil
          onTap: () {
            // TODO: Yeni sipariş ekranı
          },
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Kurye Çağır',
          subtitle: 'Hızlı teslimat talebi',
          icon: Icons.delivery_dining,
          color: const Color(0xFF2E7D32), // Koyu yeşil
          onTap: () {
            // Mevcut kurye çağırma sistemi
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallCourierScreen(
                  merchantId: widget.restaurantId,
                  merchantName: widget.restaurantName,
                  merchantLocation: _merchantLocation,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Menü Yönetimi',
          subtitle: 'Ürün ekle/düzenle',
          icon: Icons.restaurant_menu,
          color: const Color(0xFF66BB6A), // Açık yeşil
          onTap: () {
            // TODO: Menü yönetimi ekranı
          },
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Raporlar',
          subtitle: 'Satış analizleri',
          icon: Icons.analytics_outlined,
          color: const Color(0xFF81C784), // Daha açık yeşil
          onTap: () {
            // TODO: Raporlar ekranı
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
