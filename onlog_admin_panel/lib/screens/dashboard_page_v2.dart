import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class DashboardPageV2 extends StatefulWidget {
  const DashboardPageV2({super.key});

  @override
  State<DashboardPageV2> createState() => _DashboardPageV2State();
}

class _DashboardPageV2State extends State<DashboardPageV2> {
  StreamSubscription? _deliverySubscription;
  StreamSubscription? _usersSubscription;
  int _liveActiveDeliveries = 0;
  int _liveAvailableCouriers = 0;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _deliverySubscription?.cancel();
    _usersSubscription?.cancel();
    super.dispose();
  }

  /// 🔥 ADMIN: Gerçek zamanlı teslimat + kullanıcı takibi
  void _setupRealtimeListeners() {
    // Teslimatları dinle
    _deliverySubscription = SupabaseService.client
        .from('delivery_requests')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final activeCount = data.where((d) => 
            d['status'] == 'assigned' || 
            d['status'] == 'accepted' ||
            d['status'] == 'in_progress'
          ).length;
          
          if (mounted) {
            setState(() => _liveActiveDeliveries = activeCount);
          }
        });

    // Kullanıcıları dinle (müsait kuryeler)
    _usersSubscription = SupabaseService.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('role', 'courier')
        .listen((data) {
          final availableCount = data.where((u) => u['is_available'] == true).length;
          
          if (mounted) {
            setState(() => _liveAvailableCouriers = availableCount);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            const Text(
              '📊 Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Özet Kartlar
            _buildSummaryCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAllData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final deliveryRequests = data['deliveryRequests'] as List;
        final orders = data['orders'] as List;
        final users = data['users'] as List;
        
        final totalDeliveries = deliveryRequests.length;
        final activeDeliveries = deliveryRequests.where((d) => 
          d['status'] == 'pending' || d['status'] == 'in_progress'
        ).length;
        ).length;
        final completedDeliveries = deliveryRequests.where((d) => d['status'] == 'delivered').length;
        
        final platformOrders = orders.length;
        final pendingApprovals = users.where((u) => u['status'] == 'pending').length;
        
        // Gelir hesaplama
        double totalRevenue = 0;
        for (final delivery in deliveryRequests) {
          if (delivery['status'] == 'delivered') {
            totalRevenue += (delivery['delivery_fee'] ?? 0).toDouble();
          }
        }
        final commission = totalRevenue * 0.15;

        return Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildStatCard(
                  title: 'Toplam İşletme',
                  value: '$activeMerchants / $merchants',
                  subtitle: 'Aktif / Toplam',
                  icon: Icons.store,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  title: 'Toplam Kurye',
                  value: '$activeCouriers / $couriers',
                  subtitle: 'Aktif / Toplam',
                  icon: Icons.delivery_dining,
                  color: Colors.green,
                ),
                _buildStatCard(
                  title: 'Müsait Kurye',
                  value: availableCouriers.toString(),
                  subtitle: 'Şu an çevrimiçi',
                  icon: Icons.online_prediction,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Teslimatlar',
                  value: '$activeDeliveries / $totalDeliveries',
                  subtitle: 'Aktif / Toplam',
                  icon: Icons.local_shipping,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildStatCard(
                  title: 'Tamamlanan',
                  value: completedDeliveries.toString(),
                  subtitle: 'Başarılı teslimat',
                  icon: Icons.check_circle,
                  color: Colors.teal,
                ),
                _buildStatCard(
                  title: 'Platform Siparişleri',
                  value: platformOrders.toString(),
                  subtitle: 'Trendyol/Getir/YS',
                  icon: Icons.shopping_bag,
                  color: Colors.pink,
                ),
                _buildStatCard(
                  title: 'Bekleyen Başvuru',
                  value: pendingApprovals.toString(),
                  subtitle: 'Onay bekliyor',
                  icon: Icons.pending_actions,
                  color: Colors.amber,
                ),
                _buildStatCard(
                  title: 'Toplam Gelir',
                  value: '${totalRevenue.toStringAsFixed(2)} ₺',
                  subtitle: 'Komisyon: ${commission.toStringAsFixed(2)} ₺',
                  icon: Icons.attach_money,
                  color: Colors.indigo,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadAllData() async {
    final users = await SupabaseService.from('users').select();
    final deliveryRequests = await SupabaseService.from('delivery_requests').select();
    final orders = await SupabaseService.from('orders').select();
    return {
      'users': users,
      'deliveryRequests': deliveryRequests,
      'orders': orders,
    };
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
