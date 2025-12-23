import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';

class PerformanceScreen extends StatefulWidget {
  final String courierId;

  const PerformanceScreen({
    super.key,
    required this.courierId,
  });

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _allDeliveries = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 📊 PERFORMANS VERİLERİNİ YÜK
  Future<void> _loadPerformanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Tüm teslimatları çek
      final deliveriesResponse = await SupabaseService.client
          .from('delivery_requests')
          .select('*')
          .eq('courier_id', widget.courierId)
          .order('created_at', ascending: false);

      final deliveries = deliveriesResponse as List<dynamic>;

      // İstatistikleri hesapla
      final totalDeliveries = deliveries.length;
      final completedDeliveries = deliveries
          .where((d) => d['status'] == 'delivered')
          .length;
      final cancelledDeliveries = deliveries
          .where((d) => d['status'] == 'cancelled')
          .length;

      // Bu ay için teslimatlar
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final thisMonthDeliveries = deliveries.where((d) {
        final createdAt = DateTime.parse(d['created_at']);
        return createdAt.isAfter(firstDayOfMonth);
      }).length;

      // Bu hafta için teslimatlar
      final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekDeliveries = deliveries.where((d) {
        final createdAt = DateTime.parse(d['created_at']);
        return createdAt.isAfter(firstDayOfWeek);
      }).length;

      // Bugün için teslimatlar
      final today = DateTime(now.year, now.month, now.day);
      final todayDeliveries = deliveries.where((d) {
        final createdAt = DateTime.parse(d['created_at']);
        final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
        return createdDay.isAtSameMomentAs(today);
      }).length;

      // Başarı oranı
      final successRate = totalDeliveries > 0
          ? (completedDeliveries / totalDeliveries * 100).toStringAsFixed(1)
          : '0.0';

      if (mounted) {
        setState(() {
          _stats = {
            'totalDeliveries': totalDeliveries,
            'completedDeliveries': completedDeliveries,
            'cancelledDeliveries': cancelledDeliveries,
            'thisMonthDeliveries': thisMonthDeliveries,
            'thisWeekDeliveries': thisWeekDeliveries,
            'todayDeliveries': todayDeliveries,
            'successRate': successRate,
          };
          _allDeliveries = deliveries.cast<Map<String, dynamic>>().toList();
          _isLoading = false;
        });
      }

      print('✅ Performans verileri yüklendi: $_stats');
    } catch (e) {
      print('❌ Performans verileri yüklenirken hata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Performans & Bonus',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPerformanceData,
              color: const Color(0xFF4CAF50),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // GÜNLÜK/HAFTALIK/AYLIK İSTATİSTİKLER
                  _buildPeriodStats(),
                  const SizedBox(height: 16),

                  // GENEL İSTATİSTİKLER
                  _buildOverallStats(),
                  const SizedBox(height: 16),

                  // BAŞARI ORANI
                  _buildSuccessRate(),
                  const SizedBox(height: 16),

                  // BONUS BİLGİLERİ
                  _buildBonusInfo(),
                  const SizedBox(height: 16),

                  // SON TESLİMATLAR
                  _buildRecentDeliveries(),
                ],
              ),
            ),
    );
  }

  /// 📅 GÜNLÜK/HAFTALIK/AYLIK İSTATİSTİKLER
  Widget _buildPeriodStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 8),
                Text(
                  'Teslimat İstatistikleri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Bugün',
                  '${_stats['todayDeliveries'] ?? 0}',
                  Icons.today,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Bu Hafta',
                  '${_stats['thisWeekDeliveries'] ?? 0}',
                  Icons.date_range,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Bu Ay',
                  '${_stats['thisMonthDeliveries'] ?? 0}',
                  Icons.calendar_month,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 GENEL İSTATİSTİKLER
  Widget _buildOverallStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 8),
                Text(
                  'Genel İstatistikler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Toplam Teslimat',
              '${_stats['totalDeliveries'] ?? 0}',
              Icons.delivery_dining,
              const Color(0xFF4CAF50),
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Tamamlanan',
              '${_stats['completedDeliveries'] ?? 0}',
              Icons.check_circle,
              Colors.green,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'İptal Edilen',
              '${_stats['cancelledDeliveries'] ?? 0}',
              Icons.cancel,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 BAŞARI ORANI
  Widget _buildSuccessRate() {
    final successRate = double.tryParse(_stats['successRate'] ?? '0.0') ?? 0.0;
    final progressColor = successRate >= 90
        ? Colors.green
        : successRate >= 70
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              progressColor.withOpacity(0.1),
              progressColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: progressColor, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Başarı Oranı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '%${_stats['successRate'] ?? '0.0'}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getSuccessMessage(successRate),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎁 BONUS BİLGİLERİ
  Widget _buildBonusInfo() {
    final thisMonthDeliveries = _stats['thisMonthDeliveries'] ?? 0;
    final bonusLevel = _calculateBonusLevel(thisMonthDeliveries);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withOpacity(0.2),
              const Color(0xFFFFA500).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.card_giftcard, color: Color(0xFFFF9800), size: 20),
                SizedBox(width: 8),
                Text(
                  'Bonus Durumu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bu Ay Bonus Seviyesi:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        bonusLevel['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: bonusLevel['color'],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Teslimat Sayısı:'),
                      Text(
                        '$thisMonthDeliveries',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (thisMonthDeliveries / 200).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: bonusLevel['color'],
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bonusLevel['message'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bonus detayları için yöneticinizle iletişime geçin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📦 TÜM TESLİMATLAR (TAB VIEW)
  Widget _buildRecentDeliveries() {
    if (_allDeliveries.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Henüz teslimat yok',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // TAB BAR
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF4CAF50),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Tümü (${_allDeliveries.length})'),
                Tab(text: 'Teslim Edildi (${_allDeliveries.where((d) => d['status'] == 'delivered').length})'),
                Tab(text: 'İptal Edildi (${_allDeliveries.where((d) => d['status'] == 'cancelled').length})'),
                Tab(text: 'Devam Eden (${_allDeliveries.where((d) => d['status'] != 'delivered' && d['status'] != 'cancelled').length})'),
              ],
            ),
          ),
          // TAB VIEW
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeliveryList(_allDeliveries),
                _buildDeliveryList(_allDeliveries.where((d) => d['status'] == 'delivered').toList()),
                _buildDeliveryList(_allDeliveries.where((d) => d['status'] == 'cancelled').toList()),
                _buildDeliveryList(_allDeliveries.where((d) => d['status'] != 'delivered' && d['status'] != 'cancelled').toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 TESLİMAT LİSTESİ
  Widget _buildDeliveryList(List<Map<String, dynamic>> deliveries) {
    if (deliveries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Bu kategoride teslimat yok',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        final createdAt = DateTime.parse(delivery['created_at']);
        final status = (delivery['status'] ?? '').toLowerCase();
        final statusColor = status == 'delivered'
            ? Colors.green
            : status == 'cancelled'
                ? Colors.red
                : Colors.orange;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListTile(
              onTap: () => _showDeliveryDetails(context, delivery),
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                delivery['order_number'] ?? 'ONL-${delivery['id']?.toString().substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (delivery['pickup_business_name'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${delivery['pickup_business_name']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 📊 İSTATİSTİK ITEM
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 📊 İSTATİSTİK SATIRI
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 🎯 BAŞARI MESAJI
  String _getSuccessMessage(double rate) {
    if (rate >= 95) return 'Mükemmel! Harika gidiyorsun! 🌟';
    if (rate >= 90) return 'Çok iyi! Böyle devam et! 🚀';
    if (rate >= 80) return 'İyi performans gösteriyorsun! 👍';
    if (rate >= 70) return 'Gelişim gösteriyorsun! 💪';
    return 'Daha iyisini yapabilirsin! 📈';
  }

  /// 🎁 BONUS SEVİYESİ HESAPLA
  Map<String, dynamic> _calculateBonusLevel(int deliveries) {
    if (deliveries >= 200) {
      return {
        'name': '⭐ Platin',
        'color': const Color(0xFF9C27B0),
        'message': 'Tebrikler! Maksimum bonusa ulaştınız!',
      };
    } else if (deliveries >= 150) {
      return {
        'name': '🥇 Altın',
        'color': const Color(0xFFFFD700),
        'message': '${200 - deliveries} teslimat daha Platin\'e!',
      };
    } else if (deliveries >= 100) {
      return {
        'name': '🥈 Gümüş',
        'color': const Color(0xFFC0C0C0),
        'message': '${150 - deliveries} teslimat daha Altın\'a!',
      };
    } else if (deliveries >= 50) {
      return {
        'name': '🥉 Bronz',
        'color': const Color(0xFFCD7F32),
        'message': '${100 - deliveries} teslimat daha Gümüş\'e!',
      };
    } else {
      return {
        'name': '🌱 Başlangıç',
        'color': Colors.grey,
        'message': '${50 - deliveries} teslimat daha Bronz\'a!',
      };
    }
  }

  /// 📅 TARİH FORMATLA
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Bugün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == yesterday) {
      return 'Dün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// ✅ DURUM METNİ
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      case 'picked_up':
        return 'Teslim Alındı';
      case 'accepted':
        return 'Kabul Edildi';
      case 'assigned':
        return 'Atandı';
      case 'pending':
        return 'Beklemede';
      case 'rejected':
        return 'Reddedildi';
      default:
        return status;
    }
  }

  /// 📋 TESLİMAT DETAYLARI DIALOG
  void _showDeliveryDetails(BuildContext context, Map<String, dynamic> delivery) {
    final createdAt = DateTime.parse(delivery['created_at']);
    final status = (delivery['status'] ?? '').toLowerCase();
    final statusColor = status == 'delivered'
        ? Colors.green
        : status == 'cancelled'
            ? Colors.red
            : Colors.orange;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              delivery['order_number'] ?? 'ONL-${delivery['id']?.toString().substring(0, 8) ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // BODY
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TARİH VE SAAT
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Oluşturulma',
                        value: '${_formatDate(createdAt)} - ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                        color: Colors.blue,
                      ),
                      const Divider(height: 24),
                      
                      // ALIM ADRESİ
                      if (delivery['pickup_business_name'] != null) ...[
                        _buildDetailRow(
                          icon: Icons.store,
                          label: 'İşletme',
                          value: delivery['pickup_business_name'],
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (delivery['pickup_address'] != null) ...[
                        _buildDetailRow(
                          icon: Icons.location_on,
                          label: 'Alım Adresi',
                          value: delivery['pickup_address'],
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (delivery['pickup_contact_name'] != null) ...[
                        _buildDetailRow(
                          icon: Icons.person,
                          label: 'Alım İletişim',
                          value: delivery['pickup_contact_name'],
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (delivery['pickup_phone'] != null) ...[
                        _buildDetailRow(
                          icon: Icons.phone,
                          label: 'Alım Telefon',
                          value: delivery['pickup_phone'],
                          color: Colors.green,
                        ),
                        const Divider(height: 24),
                      ],

                      // TESLİM ADRESİ (delivery_location JSON'dan)
                      if (delivery['delivery_location'] is Map && 
                          delivery['delivery_location']['address'] != null) ...[
                        _buildDetailRow(
                          icon: Icons.home,
                          label: 'Teslimat Adresi',
                          value: delivery['delivery_location']['address'],
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (delivery['delivery_contact_name'] != null) ...[
                        _buildDetailRow(
                          icon: Icons.person_outline,
                          label: 'Teslimat İletişim',
                          value: delivery['delivery_contact_name'],
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (delivery['delivery_phone'] != null) ...[
                        _buildDetailRow(
                          icon: Icons.phone_android,
                          label: 'Teslimat Telefon',
                          value: delivery['delivery_phone'],
                          color: Colors.cyan,
                        ),
                        const Divider(height: 24),
                      ],

                      // PAKET VE ÜCRET
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.inventory_2,
                              label: 'Paket Sayısı',
                              value: delivery['package_count']?.toString() ?? '0',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.payments,
                              label: 'Ücret',
                              value: '${delivery['delivery_fee'] ?? 0} ₺',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),

                      // NOTLAR
                      if (delivery['notes'] != null && delivery['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.note, color: Colors.amber, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Notlar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                delivery['notes'],
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // İPTAL NEDENİ
                      if (status == 'cancelled' && delivery['rejection_reason'] != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.cancel, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'İptal Nedeni',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                delivery['rejection_reason'],
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📊 DETAY SATIRI
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
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
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📦 BİLGİ KARTI
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
