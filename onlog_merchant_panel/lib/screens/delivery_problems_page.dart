import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:intl/intl.dart';

class DeliveryProblemsPage extends StatefulWidget {
  final String merchantId;

  const DeliveryProblemsPage({
    super.key,
    required this.merchantId,
  });

  @override
  State<DeliveryProblemsPage> createState() => _DeliveryProblemsPageState();
}

class _DeliveryProblemsPageState extends State<DeliveryProblemsPage> {
  List<Map<String, dynamic>> _problems = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, reported, resolved

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  Future<void> _loadProblems() async {
    setState(() => _isLoading = true);

    try {
      var query = SupabaseService.client
          .from('delivery_problems')
          .select('''
            *,
            delivery_requests:delivery_request_id (
              id,
              status,
              package_count,
              declared_amount,
              pickup_location,
              delivery_location
            ),
            courier:courier_id (
              id,
              full_name,
              phone
            )
          ''')
          .eq('merchant_id', widget.merchantId);

      if (_selectedFilter != 'all') {
        query = query.eq('status', _selectedFilter);
      }

      final response = await query.order('created_at', ascending: false);
      
      setState(() {
        _problems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      if (kDebugMode) print('✅ ${_problems.length} sorun kaydı yüklendi');
    } catch (e) {
      if (kDebugMode) print('❌ Sorunlar yüklenirken hata: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sorunlar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teslimat Sorunları'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // FİLTRE BUTONLARI
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildFilterChip('Tümü', 'all', _problems.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Bekleyen',
                  'reported',
                  _problems.where((p) => p['status'] == 'reported').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Çözüldü',
                  'resolved',
                  _problems.where((p) => p['status'] == 'resolved').length,
                ),
              ],
            ),
          ),

          // SORUN LİSTESİ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _problems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProblems,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _problems.length,
                          itemBuilder: (context, index) {
                            return _buildProblemCard(_problems[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
          _loadProblems();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemCard(Map<String, dynamic> problem) {
    final deliveryRequest = problem['delivery_requests'] as Map<String, dynamic>?;
    final courier = problem['courier'] as Map<String, dynamic>?;
    final deliveryId = deliveryRequest?['id'] ?? 'Bilinmeyen';
    final shortId = deliveryId.toString().substring(0, 8); // İlk 8 karakter
    final problemType = problem['problem_type'] as String;
    final problemNote = problem['problem_note'] as String?;
    final status = problem['status'] as String;
    final createdAt = DateTime.parse(problem['created_at']);
    final resolvedAt = problem['resolved_at'] != null
        ? DateTime.parse(problem['resolved_at'])
        : null;
    final courierName = courier?['full_name'] ?? 'Bilinmeyen Kurye';
    final courierPhone = courier?['phone'] ?? '';
    
    // JSONB alanlarını güvenli şekilde parse et
    String? pickupAddress;
    String? deliveryAddress;
    
    try {
      final pickupLoc = deliveryRequest?['pickup_location'];
      if (pickupLoc is Map<String, dynamic>) {
        pickupAddress = pickupLoc['address'] as String?;
      }
      
      final deliveryLoc = deliveryRequest?['delivery_location'];
      if (deliveryLoc is Map<String, dynamic>) {
        deliveryAddress = deliveryLoc['address'] as String?;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Adres parse hatası: $e');
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'reported':
        statusColor = Colors.orange;
        statusText = 'Bekliyor';
        statusIcon = Icons.schedule;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Çözüldü';
        statusIcon = Icons.check_circle;
        break;
      case 'escalated':
        statusColor = Colors.red;
        statusText = 'Yükseltildi';
        statusIcon = Icons.priority_high;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAŞLIK VE DURUM
            Row(
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
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Teslimat #$shortId',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TESLİMAT BİLGİSİ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.purple[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Teslimat Detayları',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📦 Paket: ${deliveryRequest?['package_count'] ?? 1} adet',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '💰 Tutar: ${deliveryRequest?['declared_amount'] ?? '?'} TL',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDeliveryStatusColor(deliveryRequest?['status']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getDeliveryStatusText(deliveryRequest?['status']),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getDeliveryStatusTextColor(deliveryRequest?['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (pickupAddress != null && pickupAddress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🟢 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            pickupAddress,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (deliveryAddress != null && deliveryAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔴 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            deliveryAddress,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // SORUN TİPİ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                problemType,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ),

            // KURYE BİLGİSİ
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bildiren Kurye:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          courierName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (courierPhone.isNotEmpty)
                          Text(
                            courierPhone,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // SORUN NOTU
            if (problemNote != null && problemNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kurye Notu:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      problemNote,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // TARİHLER
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Bildirim: ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (resolvedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Çözüm: ${DateFormat('dd.MM.yyyy HH:mm').format(resolvedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'Henüz sorun bildirimi yok'
                : _selectedFilter == 'reported'
                    ? 'Bekleyen sorun yok'
                    : 'Çözülmüş sorun yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kuryeler teslimat sırasında sorun yaşarsa\nburadan bildirim alacaksınız.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Teslimat durumu renkleri
  Color _getDeliveryStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'waiting_courier':
        return Colors.blue[100]!;
      case 'assigned':
        return Colors.purple[100]!;
      case 'accepted':
        return Colors.indigo[100]!;
      case 'picked_up':
        return Colors.orange[100]!;
      case 'delivering':
        return Colors.amber[100]!;
      case 'completed':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getDeliveryStatusTextColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'waiting_courier':
        return Colors.blue[900]!;
      case 'assigned':
        return Colors.purple[900]!;
      case 'accepted':
        return Colors.indigo[900]!;
      case 'picked_up':
        return Colors.orange[900]!;
      case 'delivering':
        return Colors.amber[900]!;
      case 'completed':
        return Colors.green[900]!;
      case 'cancelled':
        return Colors.red[900]!;
      default:
        return Colors.grey[900]!;
    }
  }

  String _getDeliveryStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'BEKLİYOR';
      case 'waiting_courier':
        return 'KURYE BEKLİYOR';
      case 'assigned':
        return 'ATANDI';
      case 'accepted':
        return 'KABUL EDİLDİ';
      case 'picked_up':
        return 'ALINDI';
      case 'delivering':
        return 'TESLİMAT YOLDA';
      case 'completed':
        return 'TESLİM EDİLDİ';
      case 'cancelled':
        return 'İPTAL';
      default:
        return status?.toUpperCase() ?? 'BİLİNMİYOR';
    }
  }
}
