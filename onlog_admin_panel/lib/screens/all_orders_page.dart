import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:intl/intl.dart';

class AllOrdersPage extends StatefulWidget {
  const AllOrdersPage({super.key});

  @override
  State<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      var query = SupabaseService.from('orders').select('*, merchant:merchant_id(business_name)');
      
      if (_filter != 'all') {
        final response = await query.eq('status', _filter).order('created_at', ascending: false).limit(100);
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        return;
      }
      
      final response = await query.order('created_at', ascending: false).limit(100);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Sipariş yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Platform Siparişleri'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('Sipariş bulunamadı'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('all', 'Tümü', Colors.grey),
          _buildFilterChip('pending', 'Bekliyor', Colors.orange),
          _buildFilterChip('preparing', 'Hazırlanıyor', Colors.blue),
          _buildFilterChip('ready', 'Hazır', Colors.green),
          _buildFilterChip('cancelled', 'İptal', Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (selected) {
          setState(() {
            _filter = value;
            _isLoading = true;
          });
          _loadOrders();
        },
        selectedColor: color,
        labelStyle: TextStyle(
          color: _filter == value ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final merchant = order['merchant'];
    final platform = order['platform'] ?? 'unknown';
    Color platformColor = Colors.grey;
    if (platform == 'trendyol') platformColor = Colors.orange;
    if (platform == 'getir') platformColor = Colors.purple;
    if (platform == 'yemeksepeti') platformColor = Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: platformColor,
          child: Text(
            platform[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${merchant?['business_name'] ?? 'Bilinmeyen'}'),
        subtitle: Text('Sipariş #${order['external_order_id'] ?? 'N/A'}'),
        trailing: Text(
          '${(order['total_amount'] ?? 0)} ₺',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform: ${platform.toUpperCase()}'),
                Text('Durum: ${order['status'] ?? 'unknown'}'),
                Text('Müşteri: ${order['customer_name'] ?? 'Belirtilmemiş'}'),
                Text('Adres: ${order['delivery_address'] ?? 'Belirtilmemiş'}'),
                Text('Oluşturma: ${order['created_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order['created_at'])) : 'N/A'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
