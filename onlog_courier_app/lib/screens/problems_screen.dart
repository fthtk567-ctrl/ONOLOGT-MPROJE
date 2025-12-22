import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:intl/intl.dart';

class ProblemsScreen extends StatefulWidget {
  final String courierId;

  const ProblemsScreen({
    super.key,
    required this.courierId,
  });

  @override
  State<ProblemsScreen> createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
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
              order_number,
              status
            )
          ''')
          .eq('courier_id', widget.courierId);

      if (_selectedFilter != 'all') {
        query = query.eq('status', _selectedFilter);
      }

      final response = await query.order('created_at', ascending: false);
      
      setState(() {
        _problems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      print('✅ ${_problems.length} sorun kaydı yüklendi');
    } catch (e) {
      print('❌ Sorunlar yüklenirken hata: $e');
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
        title: const Text('Bildirdiğim Sorunlar'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
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
    final orderNumber = deliveryRequest?['order_number'] ?? 'Bilinmeyen';
    final problemType = problem['problem_type'] as String;
    final problemNote = problem['problem_note'] as String?;
    final status = problem['status'] as String;
    final createdAt = DateTime.parse(problem['created_at']);
    final resolvedAt = problem['resolved_at'] != null
        ? DateTime.parse(problem['resolved_at'])
        : null;
    final adminNotes = problem['admin_notes'] as String?;

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
                  'Sipariş #$orderNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                      'Notunuz:',
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

            // ADMİN CEVABI
            if (adminNotes != null && adminNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: Colors.green[700], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Destek Yanıtı:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminNotes,
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
                ? 'Henüz sorun bildirmediniz'
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
            'Teslimat sırasında sorun yaşarsanız\n"Sorun Bildir" butonunu kullanabilirsiniz.',
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
}
