import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';

class MerchantHomePageV2 extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MerchantHomePageV2({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MerchantHomePageV2> createState() => _MerchantHomePageV2State();
}

class _MerchantHomePageV2State extends State<MerchantHomePageV2> {
  bool _isLoading = true;
  int _activeOrders = 0;
  int _todayOrders = 0;
  double _todayEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Aktif siparişler
      final activeResponse = await SupabaseService.client
          .from('orders')
          .select()
          .eq('merchant_id', widget.restaurantId)
          .inFilter('status', ['WAITING_COURIER', 'ASSIGNED', 'ACCEPTED', 'PICKED_UP']);

      // Bugünün siparişleri
      final todayResponse = await SupabaseService.client
          .from('orders')
          .select()
          .eq('merchant_id', widget.restaurantId)
          .gte('created_at', startOfDay.toIso8601String());

      setState(() {
        _activeOrders = (activeResponse as List).length;
        _todayOrders = (todayResponse as List).length;
        _todayEarnings = (todayResponse as List)
            .where((o) => o['status'] == 'DELIVERED')
            .fold(0.0, (sum, o) => sum + ((o['total_amount'] ?? 0) as num).toDouble());
        _isLoading = false;
      });
    } catch (e) {
      print('❌ İstatistik yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hoşgeldin
            Text(
              'Hoşgeldiniz, ${widget.restaurantName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // İstatistik kartları
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Aktif Siparişler',
                    _activeOrders.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Bugün',
                    _todayOrders.toString(),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildStatCard(
              'Bugünkü Kazanç',
              '${_todayEarnings.toStringAsFixed(2)} TL',
              Icons.attach_money,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
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
          ],
        ),
      ),
    );
  }
}
