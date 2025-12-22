import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:intl/intl.dart';

class DeliveryRequestsPage extends StatefulWidget {
  const DeliveryRequestsPage({super.key});

  @override
  State<DeliveryRequestsPage> createState() => _DeliveryRequestsPageState();
}

class _DeliveryRequestsPageState extends State<DeliveryRequestsPage> {
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    try {
      final query = SupabaseService.from('delivery_requests')
          .select('*, merchant:merchant_id(full_name, business_name), courier:courier_id(full_name)');
      
      if (_selectedStatus != 'all') {
        final response = await query
            .eq('status', _selectedStatus)
            .order('created_at', ascending: false)
            .limit(100);
        
        setState(() {
          _deliveries = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        return;
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .limit(100);
      
      setState(() {
        _deliveries = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Teslimat istekleri yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'on_the_way':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'assigned':
        return 'Atandı';
      case 'picked_up':
        return 'Alındı';
      case 'on_the_way':
        return 'Yolda';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚚 Teslimat İstekleri'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tümü', 'all'),
                  _buildFilterChip('Bekliyor', 'pending'),
                  _buildFilterChip('Atandı', 'assigned'),
                  _buildFilterChip('Alındı', 'picked_up'),
                  _buildFilterChip('Yolda', 'on_the_way'),
                  _buildFilterChip('Teslim', 'delivered'),
                  _buildFilterChip('İptal', 'cancelled'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Deliveries List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _deliveries.isEmpty
                    ? const Center(child: Text('Teslimat isteği bulunamadı'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _deliveries.length,
                        itemBuilder: (context, index) {
                          final delivery = _deliveries[index];
                          final status = delivery['status'] ?? 'unknown';
                          final merchantName = delivery['merchant']?['business_name'] ?? 
                                              delivery['merchant']?['full_name'] ?? 
                                              'Bilinmeyen İşletme';
                          final courierName = delivery['courier']?['full_name'] ?? 'Atanmadı';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(status),
                                child: const Icon(Icons.delivery_dining, color: Colors.white),
                              ),
                              title: Text('Bilinmeyen İşletme → -'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kurye: $courierName'),
                                  Text('Ücret: ${delivery['declared_amount'] ?? 0} ₺'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                  _getStatusText(status),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor: _getStatusColor(status),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('ID', delivery['id']?.toString() ?? '-'),
                                      _buildDetailRow('📦 Paket', '${delivery['package_count'] ?? 0} adet'),
                                      _buildDetailRow('💰 Ücret', '${delivery['declared_amount'] ?? 0} ₺'),
                                      _buildDetailRow('📝 Kaynak', delivery['source'] ?? 'manual'),
                                      if (delivery['external_order_id'] != null)
                                        _buildDetailRow('🔗 External ID', delivery['external_order_id']),
                                      _buildDetailRow('📝 Not', delivery['notes'] ?? '-'),
                                      if (delivery['created_at'] != null)
                                        _buildDetailRow('📅 Oluşturulma', 
                                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(delivery['created_at']))),
                                      if (delivery['delivered_at'] != null)
                                        _buildDetailRow('✅ Teslim', 
                                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(delivery['delivered_at']))),
                                      
                                      const Divider(height: 24),
                                      
                                      // YÖNETİM BUTONLARI
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // Kurye Atama/Değiştirme (pending, assigned, accepted için)
                                          if (status.toLowerCase() == 'pending' || 
                                              status.toLowerCase() == 'assigned' || 
                                              status.toLowerCase() == 'accepted' ||
                                              status.toLowerCase() == 'picked_up')
                                            ElevatedButton.icon(
                                              onPressed: () => _assignCourier(delivery),
                                              icon: Icon(delivery['courier_id'] != null ? Icons.swap_horiz : Icons.person_add),
                                              label: Text(delivery['courier_id'] != null ? 'Kurye Değiştir' : 'Kurye Ata'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: delivery['courier_id'] != null ? Colors.orange : Colors.blue,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          
                                          // Durum Değiştir
                                          if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled')
                                            ElevatedButton.icon(
                                              onPressed: () => _changeStatus(delivery),
                                              icon: const Icon(Icons.change_circle),
                                              label: const Text('Durum'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          
                                          // İptal Et
                                          if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled')
                                            ElevatedButton.icon(
                                              onPressed: () => _cancelDelivery(delivery),
                                              icon: const Icon(Icons.cancel),
                                              label: const Text('İptal'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = value;
            _isLoading = true;
          });
          _loadDeliveries();
        },
        selectedColor: Colors.blue,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
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

  // 🔧 KURYE ATAMA
  Future<void> _assignCourier(Map<String, dynamic> delivery) async {
    try {
      // Müsait kuryeleri getir
      final couriers = await SupabaseService.from('users')
          .select('id, full_name, phone')
          .eq('role', 'courier')
          .eq('is_active', true);

      if (!mounted) return;

      if (couriers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müsait kurye bulunamadı')),
        );
        return;
      }

      // Kurye seçme dialog'u
      final selectedCourier = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kurye Seç'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: couriers.length,
              itemBuilder: (context, index) {
                final courier = couriers[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.delivery_dining),
                  ),
                  title: Text(courier['full_name'] ?? 'İsimsiz'),
                  subtitle: Text(courier['phone'] ?? ''),
                  onTap: () => Navigator.pop(context, courier),
                );
              },
            ),
          ),
        ),
      );

      if (selectedCourier == null) return;

      // Sadece courier_id'yi güncelle - status'a dokunma
      final currentStatus = delivery['status'] ?? 'pending';
      
      await SupabaseService.from('delivery_requests')
          .update({
            'courier_id': selectedCourier['id'],
            // Eğer pending ise assigned yap, yoksa mevcut status'u koru
            if (currentStatus.toLowerCase() == 'pending')
              'status': 'assigned',
          })
          .eq('id', delivery['id']);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kurye ${selectedCourier['full_name']} atandı!')),
      );
      
      _loadDeliveries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // 🔄 DURUM DEĞİŞTİR
  Future<void> _changeStatus(Map<String, dynamic> delivery) async {
    final statuses = [
      {'value': 'pending', 'label': 'Bekliyor'},
      {'value': 'assigned', 'label': 'Atandı'},
      {'value': 'accepted', 'label': 'Kabul Edildi'},
      {'value': 'picked_up', 'label': 'Alındı'},
      {'value': 'in_progress', 'label': 'Yolda'},
      {'value': 'delivered', 'label': 'Teslim Edildi'},
      {'value': 'cancelled', 'label': 'İptal'},
    ];

    final selectedStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((s) => ListTile(
            title: Text(s['label']!),
            onTap: () => Navigator.pop(context, s['value']),
          )).toList(),
        ),
      ),
    );

    if (selectedStatus == null) return;

    try {
      await SupabaseService.from('delivery_requests')
          .update({'status': selectedStatus})
          .eq('id', delivery['id']);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellendi!')),
      );
      
      _loadDeliveries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  // ❌ İPTAL ET
  Future<void> _cancelDelivery(Map<String, dynamic> delivery) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi İptal Et'),
        content: const Text('Bu siparişi iptal etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.from('delivery_requests')
          .update({'status': 'cancelled'})
          .eq('id', delivery['id']);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş iptal edildi!')),
      );
      
      _loadDeliveries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
}
