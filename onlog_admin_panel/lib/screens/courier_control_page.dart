import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class CourierControlPage extends StatefulWidget {
  const CourierControlPage({super.key});

  @override
  State<CourierControlPage> createState() => _CourierControlPageState();
}

class _CourierControlPageState extends State<CourierControlPage> {
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

  Future<void> _toggleCourierStatus(String courierId, bool currentStatus) async {
    try {
      await SupabaseService.from('users')
          .update({'is_active': !currentStatus})
          .eq('id', courierId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? '✅ Kurye aktif edildi' : '❌ Kurye pasif edildi'),
          backgroundColor: !currentStatus ? Colors.green : Colors.orange,
        ),
      );
      _loadCouriers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getInitial(String? text) {
    if (text == null || text.isEmpty) return 'K';
    return text[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎛️ Kurye Kontrol'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _couriers.isEmpty
              ? const Center(child: Text('Kurye bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _couriers.length,
                  itemBuilder: (context, index) {
                    final courier = _couriers[index];
                    final isActive = courier['is_active'] == true;
                    final isAvailable = courier['is_available'] == true;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                          child: Text(
                            _getInitial(courier['full_name'] ?? courier['email']),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(courier['full_name'] ?? 'İsimsiz'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(courier['email'] ?? ''),
                            Text('Telefon: ${courier['phone'] ?? '-'}'),
                            Text('Araç: ${courier['vehicle_type'] ?? '-'}'),
                            Text('Müsait: ${isAvailable ? '🟢 Evet' : '🔴 Hayır'}'),
                          ],
                        ),
                        trailing: Switch(
                          value: isActive,
                          onChanged: (value) => _toggleCourierStatus(courier['id'], isActive),
                          activeThumbColor: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
