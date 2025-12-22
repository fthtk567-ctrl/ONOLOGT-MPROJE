import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActiveDeliveriesPage extends StatefulWidget {
  const ActiveDeliveriesPage({super.key});

  @override
  State<ActiveDeliveriesPage> createState() => _ActiveDeliveriesPageState();
}

class _ActiveDeliveriesPageState extends State<ActiveDeliveriesPage> {
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _subscribeToChanges();
  }

  Future<void> _loadDeliveries() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('delivery_requests')
          .select('''
            *,
            courier:courier_id (
              id,
              full_name,
              phone,
              vehicle_type
            )
          ''')
          .eq('merchant_id', user.id)
          .inFilter('status', ['assigned', 'accepted', 'picked_up', 'delivering', 'delivered'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _deliveries = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToChanges() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    Supabase.instance.client
        .from('delivery_requests')
        .stream(primaryKey: ['id']).eq('merchant_id', user.id).listen((data) {
      if (mounted) {
        setState(() {
          _deliveries = data
              .where((d) => ['assigned', 'accepted', 'picked_up', 'delivering', 'delivered']
                  .contains(d['status']))
              .toList()
            ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Teslimatlar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildFilterChip('Tümü', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Tamamlanan', 'delivered'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildList(),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) setState(() => _filterStatus = value);
      },
      selectedColor: Colors.green[600],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildList() {
    var filtered = _deliveries;
    if (_filterStatus == 'active') {
      filtered = _deliveries
          .where((d) => ['assigned', 'accepted', 'picked_up', 'delivering'].contains(d['status']))
          .toList();
    } else if (_filterStatus == 'delivered') {
      filtered = _deliveries.where((d) => d['status'] == 'delivered').toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Teslimat yok', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildCard(filtered[index]),
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    final status = data['status'] ?? '';
    final statusInfo = _getStatusInfo(status);
    final courierData = data['courier'] as Map<String, dynamic>?;
    final packageCount = data['package_count'] ?? 0;
    final amount = ((data['declared_amount'] ?? 0) as num).toDouble();
    final createdAt = data['created_at'] != null ? DateTime.parse(data['created_at']) : null;
    final hasPhoto = status == 'delivered' && data['delivery_photo_url'] != null;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: hasPhoto ? () => _showPhoto(data['delivery_photo_url']) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst: Durum + Zaman
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo['icon'], size: 12, color: statusInfo['color']),
                        const SizedBox(width: 4),
                        Text(
                          statusInfo['text'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusInfo['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (createdAt != null)
                    Text(
                      _formatTime(createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Paket + Tutar - Tek satır
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 5),
                        Text(
                          '$packageCount Paket',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${amount.toStringAsFixed(2)}₺',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Kurye bilgisi - Kompakt
              if (courierData != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue[600],
                        child: const Icon(Icons.person, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          courierData['full_name'] ?? 'Kurye',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Aranıyor: ${courierData['phone']}'),
                              backgroundColor: Colors.blue[700],
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Fotoğraf butonu - Kompakt
              if (hasPhoto) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text(
                        'Teslimat Fotoğrafı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'assigned':
        return {'text': 'Kurye Atandı', 'color': Colors.blue[600]!, 'icon': Icons.person_add};
      case 'accepted':
        return {'text': 'Kabul Edildi', 'color': Colors.indigo[600]!, 'icon': Icons.check_circle_outline};
      case 'picked_up':
        return {'text': 'Toplandı', 'color': Colors.purple[600]!, 'icon': Icons.shopping_bag_outlined};
      case 'delivering':
        return {'text': 'Yolda', 'color': Colors.orange[600]!, 'icon': Icons.local_shipping_outlined};
      case 'delivered':
        return {'text': 'Teslim Edildi', 'color': Colors.green[600]!, 'icon': Icons.check_circle};
      default:
        return {'text': 'Bekliyor', 'color': Colors.grey[600]!, 'icon': Icons.access_time};
    }
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Teslimat Fotoğrafı'),
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
