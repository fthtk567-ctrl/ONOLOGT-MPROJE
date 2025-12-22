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
          .inFilter('status', ['pending', 'assigned', 'accepted', 'picked_up', 'delivering', 'rejected'])
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
        .stream(primaryKey: ['id'])
        .eq('merchant_id', user.id)
        .listen((data) {
      if (mounted) {
        setState(() {
          _deliveries = data
              .where((d) {
                // Sadece aktif durumda olanları filtrele (pending, rejected, assigned, accepted, picked_up, delivering)
                final isActive = ['pending', 'assigned', 'accepted', 'picked_up', 'delivering', 'rejected'].contains(d['status']);
                return isActive;
              })
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
        title: const Text('� Açık Teslimatlar'),
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
          .where((d) => ['pending', 'assigned', 'accepted', 'picked_up', 'delivering', 'rejected'].contains(d['status']))
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
            Text('Açık teslimat yok', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Yeni teslimat oluşturduğunuzda burada görünecek', 
                 style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
    final orderNumber = data['order_number'] ?? 'ORD-${data['id']?.toString().substring(0, 8) ?? ''}';
    final pickupAddress = data['pickup_address'] ?? 'Adres belirtilmemiş';
    final deliveryAddress = data['delivery_address'] ?? 'Adres belirtilmemiş';
    final notes = data['notes'] ?? '';

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusInfo['color'].withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ÜST: Teslimat Numarası + Durum
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.deepOrange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tag, size: 14, color: Colors.deepOrange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                orderNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo['icon'], size: 14, color: statusInfo['color']),
                        const SizedBox(width: 5),
                        Text(
                          statusInfo['text'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusInfo['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // ORTA: Paket Sayısı + Tutar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paket Sayısı',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '$packageCount Adet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payments, size: 20, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tahsilat',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${amount.toStringAsFixed(2)} ₺',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // ALT: Adres Bilgileri
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.store, size: 14, color: Colors.orange.shade700),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alış Adresi',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pickupAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_downward, size: 14, color: Colors.grey.shade500),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on, size: 14, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teslim Adresi',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                deliveryAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Kurye Bilgisi (eğer varsa)
              if (courierData != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade50, Colors.purple.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delivery_dining, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kurye',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              courierData['full_name'] ?? 'Atanmadı',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (courierData['phone'] != null)
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📞 ${courierData['phone']}'),
                                backgroundColor: Colors.purple.shade700,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Notlar (eğer varsa)
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_alt, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Alt: Detay Butonu + Tarih
              const SizedBox(height: 12),
              Row(
                children: [
                  if (createdAt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showDetailDialog(data),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detaylar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {'text': 'Kurye Bekleniyor', 'color': Colors.grey[600]!, 'icon': Icons.access_time};
      case 'rejected':
        return {'text': 'Yeni Kurye Aranıyor', 'color': Colors.amber[700]!, 'icon': Icons.refresh};
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

  void _showDetailDialog(Map<String, dynamic> data) {
    final orderNumber = data['order_number'] ?? 'ORD-${data['id']?.toString().substring(0, 8) ?? ''}';
    final status = data['status'] ?? '';
    final statusInfo = _getStatusInfo(status);
    final packageCount = data['package_count'] ?? 0;
    final amount = ((data['declared_amount'] ?? 0) as num).toDouble();
    final pickupAddress = data['pickup_address'] ?? 'Belirtilmemiş';
    final deliveryAddress = data['delivery_address'] ?? 'Belirtilmemiş';
    final notes = data['notes'] ?? '';
    final courierData = data['courier'] as Map<String, dynamic>?;
    final createdAt = data['created_at'] != null ? DateTime.parse(data['created_at']) : null;
    final deliveryPhotoUrl = data['delivery_photo_url'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_long, color: Colors.deepOrange.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Teslimat Detayları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orderNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.deepOrange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                
                // Durum
                _buildDetailRow(
                  icon: statusInfo['icon'],
                  iconColor: statusInfo['color'],
                  label: 'Durum',
                  value: statusInfo['text'],
                  valueColor: statusInfo['color'],
                ),
                const SizedBox(height: 16),
                
                // Paket Sayısı
                _buildDetailRow(
                  icon: Icons.inventory_2,
                  iconColor: Colors.blue.shade700,
                  label: 'Paket Sayısı',
                  value: '$packageCount Adet',
                ),
                const SizedBox(height: 16),
                
                // Tahsilat
                _buildDetailRow(
                  icon: Icons.payments,
                  iconColor: Colors.green.shade700,
                  label: 'Tahsilat Tutarı',
                  value: '${amount.toStringAsFixed(2)} ₺',
                  valueColor: Colors.green.shade700,
                  valueBold: true,
                ),
                const SizedBox(height: 16),
                
                // Alış Adresi
                _buildDetailRow(
                  icon: Icons.store,
                  iconColor: Colors.orange.shade700,
                  label: 'Alış Adresi',
                  value: pickupAddress,
                  multiline: true,
                ),
                const SizedBox(height: 16),
                
                // Teslim Adresi
                _buildDetailRow(
                  icon: Icons.location_on,
                  iconColor: Colors.blue.shade700,
                  label: 'Teslim Adresi',
                  value: deliveryAddress,
                  multiline: true,
                ),
                
                // Kurye
                if (courierData != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.delivery_dining,
                    iconColor: Colors.purple.shade700,
                    label: 'Kurye',
                    value: courierData['full_name'] ?? 'Atanmadı',
                  ),
                ],
                
                // Notlar
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.note_alt,
                    iconColor: Colors.amber.shade700,
                    label: 'Notlar',
                    value: notes,
                    multiline: true,
                  ),
                ],
                
                // Oluşturulma Tarihi
                if (createdAt != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    iconColor: Colors.grey.shade700,
                    label: 'Oluşturulma',
                    value: '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                ],
                
                // Teslimat Fotoğrafı
                if (deliveryPhotoUrl != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showPhoto(deliveryPhotoUrl),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Teslimat Fotoğrafını Görüntüle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ],
                
                // İptal Butonu (sadece pending, assigned, rejected durumlarında)
                if (['pending', 'assigned', 'rejected'].contains(status)) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _cancelDelivery(data),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Teslimatı İptal Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Not: İptal edilen teslimatlar borcunuza yansımaz.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelDelivery(Map<String, dynamic> data) async {
    final deliveryId = data['id'];
    final orderNumber = data['order_number'] ?? 'ORD-${data['id']?.toString().substring(0, 8) ?? ''}';
    
    // Önce onay al
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Teslimatı İptal Et', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teslimat: $orderNumber',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu teslimatı iptal etmek istediğinizden emin misiniz?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İptal edilen teslimatlar borcunuza yansımaz ve "Geçmiş Teslimatlar" bölümünde görünür.',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cancel),
            label: const Text('İptal Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Loading göster
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Teslimatı iptal et
      await Supabase.instance.client
          .from('delivery_requests')
          .update({
            'status': 'cancelled',
            'rejection_reason': 'Merchant tarafından iptal edildi',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deliveryId);

      // Kuryeye bildirim gönder (eğer atanmışsa)
      final courierId = data['courier_id'];
      if (courierId != null) {
        await Supabase.instance.client
            .from('notifications')
            .insert({
              'user_id': courierId,
              'title': '❌ Teslimat İptal Edildi',
              'message': 'Sipariş $orderNumber merchant tarafından iptal edildi.',
              'type': 'delivery',
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      if (!mounted) return;
      
      // Loading kapat
      Navigator.pop(context);
      // Detay dialog'u kapat
      Navigator.pop(context);

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Teslimat $orderNumber iptal edildi.'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );

      // Listeyi yenile
      _loadDeliveries();
    } catch (e) {
      if (!mounted) return;
      
      // Loading kapat
      Navigator.pop(context);
      
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Hata: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
                maxLines: multiline ? null : 1,
                overflow: multiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPhoto(String url) {
    print('🖼️ _showPhoto çağrıldı: url = "$url"');
    
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
