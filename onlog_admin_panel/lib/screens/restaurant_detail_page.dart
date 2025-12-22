import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String merchantId;
  
  const RestaurantDetailPage({super.key, required this.merchantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  Map<String, dynamic>? _merchant;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMerchantDetails();
  }

  Future<void> _loadMerchantDetails() async {
    try {
      final merchant = await SupabaseService.from('users')
          .select()
          .eq('id', widget.merchantId)
          .single();
      
      final deliveries = await SupabaseService.from('delivery_requests')
          .select()
          .eq('merchant_id', widget.merchantId)
          .order('created_at', ascending: false)
          .limit(50);
      
      setState(() {
        _merchant = merchant;
        _deliveries = List<Map<String, dynamic>>.from(deliveries);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ İşletme detay yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_merchant?['business_name'] ?? 'İşletme Detayı'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _merchant == null
              ? const Center(child: Text('İşletme bulunamadı'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'Son Teslimatlar',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._deliveries.map((delivery) => _buildDeliveryCard(delivery)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.store, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _merchant!['business_name'] ?? 'İsimsiz',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(_merchant!['email'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('📞 Telefon', _merchant!['phone'] ?? 'Belirtilmemiş'),
            _buildInfoRow('📍 Adres', _merchant!['address'] ?? 'Belirtilmemiş'),
            _buildInfoRow('📊 Komisyon', '%${(_merchant!['commission_rate'] ?? 15.0).toStringAsFixed(0)}'),
            _buildInfoRow('✅ Durum', _merchant!['is_active'] == true ? 'Aktif' : 'Pasif'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final status = delivery['status'] ?? 'unknown';
    Color statusColor = Colors.grey;
    if (status == 'delivered') statusColor = Colors.green;
    if (status == 'in_progress') statusColor = Colors.blue;
    if (status == 'cancelled') statusColor = Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
        ),
        title: Text('Sipariş #${delivery['id'].toString().substring(0, 8)}'),
        subtitle: Text(delivery['pickup_address'] ?? ''),
        trailing: Text(
          '${(delivery['delivery_fee'] ?? 0)} ₺',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
