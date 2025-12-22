import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ClosedDeliveriesPage extends StatefulWidget {
  const ClosedDeliveriesPage({super.key});

  @override
  State<ClosedDeliveriesPage> createState() => _ClosedDeliveriesPageState();
}

class _ClosedDeliveriesPageState extends State<ClosedDeliveriesPage> {
  List<Map<String, dynamic>> _deliveries = [];
  List<Map<String, dynamic>> _filteredDeliveries = [];
  bool _isLoading = true;
  
  // Filtre seçenekleri
  String _selectedFilter = 'all'; // all, today, week, month
  String _selectedStatus = 'all'; // all, delivered, cancelled

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // KAPANAN TESLİMATLAR: delivered, cancelled
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
          .inFilter('status', ['delivered', 'cancelled'])
          .order('created_at', ascending: false)
          .limit(100); // Son 100 teslimat

      if (mounted) {
        setState(() {
          _deliveries = List<Map<String, dynamic>>.from(response);
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Kapanan teslimatlar yüklenirken hata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_deliveries);
    
    // Tarih filtresi
    final now = DateTime.now();
    if (_selectedFilter == 'today') {
      final todayStart = DateTime(now.year, now.month, now.day);
      filtered = filtered.where((d) {
        final date = DateTime.parse(d['created_at']);
        return date.isAfter(todayStart);
      }).toList();
    } else if (_selectedFilter == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      filtered = filtered.where((d) {
        final date = DateTime.parse(d['created_at']);
        return date.isAfter(weekAgo);
      }).toList();
    } else if (_selectedFilter == 'month') {
      final monthAgo = now.subtract(const Duration(days: 30));
      filtered = filtered.where((d) {
        final date = DateTime.parse(d['created_at']);
        return date.isAfter(monthAgo);
      }).toList();
    }
    
    // Status filtresi
    if (_selectedStatus != 'all') {
      filtered = filtered.where((d) => d['status'] == _selectedStatus).toList();
    }
    
    setState(() {
      _filteredDeliveries = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Toplam istatistikler
    final totalAmount = _filteredDeliveries.fold<double>(
      0, 
      (sum, d) => sum + ((d['declared_amount'] ?? 0) as num).toDouble()
    );
    final deliveredCount = _filteredDeliveries.where((d) => d['status'] == 'delivered').length;
    final cancelledCount = _filteredDeliveries.where((d) => d['status'] == 'cancelled').length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kapanan Teslimatlar'),
        actions: [
          // İstatistik özeti
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_filteredDeliveries.length} teslimat • ₺${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre seçenekleri
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tarih filtresi
                Row(
                  children: [
                    const Text('Tarih:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip('Tümü', 'all'),
                          _buildFilterChip('Bugün', 'today'),
                          _buildFilterChip('Son 7 Gün', 'week'),
                          _buildFilterChip('Son 30 Gün', 'month'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status filtresi
                Row(
                  children: [
                    const Text('Durum:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _buildStatusChip('Tümü', 'all'),
                          _buildStatusChip('Teslim Edildi', 'delivered'),
                          _buildStatusChip('İptal Edildi', 'cancelled'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // İstatistik kartları
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '✓ Teslim',
                        deliveredCount.toString(),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '✕ İptal',
                        cancelledCount.toString(),
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '₺ Toplam',
                        '${totalAmount.toStringAsFixed(0)} TL',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDeliveries.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Seçilen kriterlere uygun teslimat bulunamadı',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDeliveries.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final delivery = _filteredDeliveries[index];
                    final courier = delivery['courier'] as Map<String, dynamic>?;
                    
                    // Tarih formatla: Bugün ise sadece saat, değilse gün.ay.yıl + saat
                    final createdAt = DateTime.parse(delivery['created_at']);
                    final now = DateTime.now();
                    final isToday = createdAt.year == now.year && 
                                   createdAt.month == now.month && 
                                   createdAt.day == now.day;
                    
                    final formattedDate = isToday
                        ? DateFormat('HH:mm').format(createdAt)  // Sadece saat
                        : DateFormat('dd.MM.yyyy HH:mm').format(createdAt);  // Tam tarih
                    
                    final status = delivery['status'] ?? 'unknown';
                    final packageCount = delivery['package_count'] ?? 0;
                    final amount = ((delivery['declared_amount'] ?? 0) as num).toDouble();
                    
                    // Status rengi ve ikonu
                    Color statusColor;
                    IconData statusIcon;
                    if (status == 'delivered') {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else if (status == 'cancelled') {
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                    } else {
                      statusColor = Colors.grey;
                      statusIcon = Icons.help;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık satırı: Sipariş Numarası + Status badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    delivery['order_number'] ?? 'ORD-${delivery['id'].toString().substring(0, 8)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 16, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getStatusText(status),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            
                            // Detaylar
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(Icons.access_time, 'Tarih', formattedDate),
                                      const SizedBox(height: 8),
                                      if (courier != null)
                                        _buildDetailRow(
                                          Icons.person,
                                          'Kurye',
                                          courier['full_name'] ?? 'İsimsiz Kurye',
                                        ),
                                      if (courier != null) const SizedBox(height: 8),
                                      _buildDetailRow(
                                        Icons.inventory,
                                        'Paket',
                                        '$packageCount adet',
                                      ),
                                    ],
                                  ),
                                ),
                                // Tutar
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '₺${amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Tutar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // İptal Nedeni (sadece cancelled durumunda)
                            if (status == 'cancelled' && delivery['rejection_reason'] != null) ...[
                              const Divider(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'İptal Nedeni',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            delivery['rejection_reason'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Fotoğraf butonu (sadece delivered durumunda)
                            if (status == 'delivered' && delivery['delivery_photo_url'] != null) ...[
                              const Divider(height: 20),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showDeliveryPhoto(delivery['delivery_photo_url']),
                                  icon: const Icon(Icons.photo, size: 20),
                                  label: const Text('Teslimat Fotoğrafını Gör'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: Colors.blue.shade700,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.blue.shade200),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilters();
        });
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
  
  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
          _applyFilters();
        });
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'assigned':
        return 'Atandı';
      case 'picked_up':
        return 'Alındı';
      case 'delivering':
        return 'Teslimatta';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  void _showDeliveryPhoto(String? photoUrl) {
    if (kDebugMode) print('🖼️ _showDeliveryPhoto çağrıldı: photoUrl = "$photoUrl"');
    
    if (photoUrl == null || photoUrl.isEmpty) {
      if (kDebugMode) print('❌ Fotoğraf URL boş veya null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu teslimat için fotoğraf bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (kDebugMode) print('✅ Fotoğraf URL geçerli, dialog açılıyor: $photoUrl');

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