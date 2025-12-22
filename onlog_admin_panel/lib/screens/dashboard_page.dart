import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _totalMerchants = 0;
  int _totalCouriers = 0;
  int _totalDeliveries = 0;
  int _activeDeliveries = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final merchants = await SupabaseService.from('users').select().eq('role', 'merchant');
      final couriers = await SupabaseService.from('users').select().eq('role', 'courier');
      final deliveries = await SupabaseService.from('delivery_requests').select();
      final activeDeliveries = await SupabaseService.from('delivery_requests').select().eq('status', 'in_progress');
      
      setState(() {
        _totalMerchants = merchants.length;
        _totalCouriers = couriers.length;
        _totalDeliveries = deliveries.length;
        _activeDeliveries = activeDeliveries.length;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Dashboard veri yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Dashboard'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ONLOG Admin Dashboard',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'İşletmeler',
                          _totalMerchants.toString(),
                          Icons.store,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Kuryeler',
                          _totalCouriers.toString(),
                          Icons.delivery_dining,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Teslimatlar',
                          _totalDeliveries.toString(),
                          Icons.local_shipping,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Aktif Teslimat',
                          _activeDeliveries.toString(),
                          Icons.pending_actions,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDashboardData,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
