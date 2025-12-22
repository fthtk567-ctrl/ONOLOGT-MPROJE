import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class CouriersPage extends StatefulWidget {
  const CouriersPage({super.key});

  @override
  State<CouriersPage> createState() => _CouriersPageState();
}

class _CouriersPageState extends State<CouriersPage> {
  List<Map<String, dynamic>> _couriers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCouriers();
  }

  Future<void> _loadCouriers() async {
    try {
      final response = await SupabaseService.from('users')
          .select()
          .eq('role', 'courier')
          .eq('status', 'approved') // Sadece onaylı kuryeler
          .order('created_at', ascending: false);
      
      setState(() {
        _couriers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Kurye yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍🚀 Kuryeler'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _couriers.isEmpty
              ? const Center(child: Text('Henüz kurye yok'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _couriers.length,
                  itemBuilder: (context, index) {
                    final courier = _couriers[index];
                    final isActive = courier['is_active'] == true;
                    final status = courier['status'] ?? 'pending';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                          child: const Icon(Icons.delivery_dining, color: Colors.white),
                        ),
                        title: Text(courier['full_name'] ?? courier['owner_name'] ?? 'İsimsiz Kurye'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(courier['email'] ?? ''),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'approved' ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status == 'approved' ? 'Onaylı' : 'Bekliyor',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  courier['is_available'] == true ? '🟢 Müsait' : '🔴 Meşgul',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('📧 Email', courier['email'] ?? '-'),
                                _buildDetailRow('📱 Telefon', courier['phone'] ?? '-'),
                                _buildDetailRow('🚗 Araç', courier['vehicle_type'] ?? '-'),
                                _buildDetailRow('📊 Durum', status == 'approved' ? 'Onaylı' : 'Bekliyor'),
                                _buildDetailRow('⚡ Aktiflik', isActive ? 'Aktif' : 'Pasif'),
                                _buildDetailRow('🔄 Müsaitlik', courier['is_available'] == true ? 'Müsait' : 'Meşgul'),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _toggleActive(courier['id'], !isActive),
                                        icon: Icon(isActive ? Icons.block : Icons.check_circle),
                                        label: Text(isActive ? 'Pasif Yap' : 'Aktif Yap'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isActive ? Colors.red : Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: status == 'approved' 
                                            ? null 
                                            : () => _approveUser(courier['id']),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Onayla'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
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
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _toggleActive(String userId, bool newActiveStatus) async {
    try {
      await SupabaseService.from('users')
          .update({'is_active': newActiveStatus})
          .eq('id', userId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newActiveStatus ? '✅ Kurye aktif edildi' : '❌ Kurye pasif edildi'),
          backgroundColor: newActiveStatus ? Colors.green : Colors.orange,
        ),
      );
      
      _loadCouriers(); // Refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approveUser(String userId) async {
    try {
      await SupabaseService.from('users')
          .update({'status': 'approved', 'is_active': true})
          .eq('id', userId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kurye onaylandı ve aktif edildi'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadCouriers(); // Refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
