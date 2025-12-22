import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MyDeliveriesPage extends StatefulWidget {
  final String merchantId;
  const MyDeliveriesPage({super.key, required this.merchantId});
  
  @override
  State<MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends State<MyDeliveriesPage> {
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'all'; // all, active, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      
      // delivery_requests tablosundan çek + courier join
      final response = await Supabase.instance.client
          .from('delivery_requests')
          .select('''
            *,
            courier:courier_id (
              id,
              owner_name,
              phone,
              vehicle_info
            )
          ''')
          .eq('merchant_id', widget.merchantId)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _deliveries = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Teslimatlar yüklenemedi: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDeliveries {
    if (_filterStatus == 'all') return _deliveries;
    if (_filterStatus == 'active') {
      return _deliveries.where((d) =>
        ['pending', 'assigned', 'picked_up', 'delivering'].contains(d['status'])
      ).toList();
    }
    if (_filterStatus == 'completed') {
      return _deliveries.where((d) => d['status'] == 'completed').toList();
    }
    if (_filterStatus == 'cancelled') {
      return _deliveries.where((d) => d['status'] == 'cancelled').toList();
    }
    return _deliveries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Teslimatlarım'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre Butonları
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildFilterChip('Tümü', 'all', _deliveries.length),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif', 'active', _deliveries.where((d) =>
                  ['pending', 'assigned', 'picked_up', 'delivering'].contains(d['status'])
                ).length),
                const SizedBox(width: 8),
                _buildFilterChip('Tamamlanan', 'completed', _deliveries.where((d) =>
                  d['status'] == 'completed'
                ).length),
                const SizedBox(width: 8),
                _buildFilterChip('İptal', 'cancelled', _deliveries.where((d) =>
                  d['status'] == 'cancelled'
                ).length),
              ],
            ),
          ),
          
          // Liste
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Hata: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDeliveries,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    
    final filtered = _filteredDeliveries;
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Teslimat bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final delivery = filtered[index];
        return _buildDeliveryCard(delivery);
      },
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final status = delivery['status'] ?? 'unknown';
    final packageCount = delivery['package_count'] ?? 0;
    final amount = ((delivery['declared_amount'] ?? 0) as num).toDouble();
    final createdAtStr = delivery['created_at'] as String?;
    final courierData = delivery['courier'] as Map<String, dynamic>?;
    
    // Status color & icon
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Bekliyor';
        statusIcon = Icons.access_time;
        break;
      case 'assigned':
        statusColor = Colors.blue;
        statusText = 'Atandı';
        statusIcon = Icons.person_add;
        break;
      case 'picked_up':
        statusColor = Colors.purple;
        statusText = 'Alındı';
        statusIcon = Icons.shopping_bag;
        break;
      case 'delivering':
        statusColor = Colors.teal;
        statusText = 'Yolda';
        statusIcon = Icons.local_shipping;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Tamamlandı';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'İptal';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Bilinmiyor';
        statusIcon = Icons.help_outline;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (createdAtStr != null)
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(createdAtStr)),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Package & Amount
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    Icons.inventory_2,
                    'Paket',
                    '$packageCount Adet',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    Icons.payments,
                    'Tutar',
                    '${amount.toStringAsFixed(2)}₺',
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            // Courier Info
            if (courierData != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.person, color: Colors.green[700], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courierData['owner_name'] ?? 'İsimsiz Kurye',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (courierData['phone'] != null)
                          Text(
                            courierData['phone'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (status == 'completed')
                    Row(
                      children: [
                        if (delivery['delivery_photo_url'] != null)
                          TextButton.icon(
                            icon: const Icon(Icons.photo, size: 18),
                            label: const Text('Fotoğraf'),
                            onPressed: () => _showDeliveryPhoto(delivery['delivery_photo_url']),
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Değerlendir'),
                          onPressed: () {
                            // TODO: Rating dialog aç
                            debugPrint('Rating dialog açılacak');
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryPhoto(String? photoUrl) {
    print('🖼️ _showDeliveryPhoto çağrıldı: photoUrl = "$photoUrl"');
    
    if (photoUrl == null || photoUrl.isEmpty) {
      print('❌ Fotoğraf URL boş veya null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu teslimat için fotoğraf bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    print('✅ Fotoğraf URL geçerli, dialog açılıyor: $photoUrl');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.photo, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Teslimat Fotoğrafı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Fotoğraf
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Fotoğraf yüklenemedi',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

