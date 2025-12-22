import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class CourierEarningsManagementPage extends StatefulWidget {
  const CourierEarningsManagementPage({super.key});

  @override
  State<CourierEarningsManagementPage> createState() => _CourierEarningsManagementPageState();
}

class _CourierEarningsManagementPageState extends State<CourierEarningsManagementPage> {
  List<Map<String, dynamic>> _courierEarnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourierEarnings();
  }

  Future<void> _loadCourierEarnings() async {
    try {
      final couriers = await SupabaseService.from('users')
          .select()
          .eq('role', 'courier');
      
      List<Map<String, dynamic>> earnings = [];
      
      for (final courier in couriers) {
        final deliveries = await SupabaseService.from('delivery_requests')
            .select()
            .eq('courier_id', courier['id'])
            .eq('status', 'delivered');
        
        double totalEarnings = 0;
        for (final delivery in deliveries) {
          totalEarnings += (delivery['delivery_fee'] ?? 0).toDouble() * 0.85; // 85% kuryeye
        }
        
        earnings.add({
          'courier': courier,
          'total_deliveries': deliveries.length,
          'total_earnings': totalEarnings,
        });
      }
      
      earnings.sort((a, b) => (b['total_earnings'] as double).compareTo(a['total_earnings'] as double));
      
      setState(() {
        _courierEarnings = earnings;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Kurye kazanç yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💵 Kurye Kazançları'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courierEarnings.isEmpty
              ? const Center(child: Text('Veri bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courierEarnings.length,
                  itemBuilder: (context, index) {
                    final data = _courierEarnings[index];
                    final courier = data['courier'];
                    final earnings = data['total_earnings'] as double;
                    final deliveries = data['total_deliveries'] as int;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(courier['full_name'] ?? 'İsimsiz'),
                        subtitle: Text('$deliveries teslimat'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${earnings.toStringAsFixed(2)} ₺',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Ort: ${deliveries > 0 ? (earnings / deliveries).toStringAsFixed(2) : 0} ₺',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
