import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'Hafta';
  bool _isLoading = true;
  String? _merchantId;
  
  // Gerçek veriler
  int _totalDeliveries = 0;
  int _completedDeliveries = 0;
  int _cancelledDeliveries = 0;
  int _pendingDeliveries = 0;
  double _totalAmount = 0;
  List<Map<String, dynamic>> _dailyStats = [];

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  Future<void> _loadMerchantData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      setState(() {
        _merchantId = user.id;
        _isLoading = true;
      });
      
      await _loadDeliveryStats();
    } catch (e) {
      print('❌ Merchant data yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDeliveryStats() async {
    if (_merchantId == null) return;
    
    try {
      // Tarih aralığı hesapla
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case 'Bugün':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Hafta':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Ay':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'Yıl':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }
      
      // Teslimat verilerini çek
      final response = await Supabase.instance.client
          .from('delivery_requests')
          .select()
          .eq('merchant_id', _merchantId!)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: true);
      
      final deliveries = response as List<dynamic>;
      
      // İstatistikleri hesapla
      int total = deliveries.length;
      int completed = 0;
      int cancelled = 0;
      int pending = 0;
      double totalAmount = 0;
      
      for (var delivery in deliveries) {
        final status = (delivery['status'] as String).toUpperCase();
        final amount = (delivery['declared_amount'] ?? 0).toDouble();
        
        if (status == 'DELIVERED') {
          completed++;
          totalAmount += amount;
        } else if (status == 'CANCELLED') {
          cancelled++;
        } else {
          pending++;
        }
      }
      
      // Günlük istatistikler için grupla
      Map<String, int> dailyCounts = {};
      for (var delivery in deliveries) {
        final date = DateTime.parse(delivery['created_at'] as String);
        final dateKey = DateFormat('dd/MM').format(date);
        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
      }
      
      List<Map<String, dynamic>> dailyStats = [];
      for (var entry in dailyCounts.entries) {
        dailyStats.add({'date': entry.key, 'count': entry.value});
      }
      
      setState(() {
        _totalDeliveries = total;
        _completedDeliveries = completed;
        _cancelledDeliveries = cancelled;
        _pendingDeliveries = pending;
        _totalAmount = totalAmount;
        _dailyStats = dailyStats;
      });
      
    } catch (e) {
      print('❌ Teslimat istatistikleri yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Raporlar & Analiz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDeliveryStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zaman Filtresi
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),

                    // BÖLÜM 1: Kurye Çağırma İstatistikleri
                    _buildSectionTitle('📦 Teslimat İstatistiklerim'),
                    const SizedBox(height: 12),
                    _buildDeliveryStats(),
                    const SizedBox(height: 20),

                    // Günlük Trend
                    if (_dailyStats.isNotEmpty) ...[
                      _buildDailyTrendChart(),
                      const SizedBox(height: 20),
                    ],

                    // BÖLÜM 2: Platform Entegrasyonları (Yakında)
                    _buildSectionTitle('🔗 Platform Entegrasyonları'),
                    const SizedBox(height: 12),
                    _buildPlatformIntegrations(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  // Zaman Dönemi Seçici
  Widget _buildPeriodSelector() {
    final periods = ['Bugün', 'Hafta', 'Ay', 'Yıl'];
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _loadDeliveryStats(); // Veriyi yeniden yükle
                });
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Teslimat İstatistikleri Kartları (GERÇEK VERİ)
  Widget _buildDeliveryStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Toplam Teslimat',
          _totalDeliveries.toString(),
          Icons.local_shipping,
          const Color(0xFF1976D2),
        ),
        _buildStatCard(
          'Tamamlanan',
          _completedDeliveries.toString(),
          Icons.check_circle,
          const Color(0xFF2E7D32),
        ),
        _buildStatCard(
          'Toplam Tutar',
          '${_totalAmount.toStringAsFixed(0)} ₺',
          Icons.payments,
          const Color(0xFFFF6F00),
        ),
        _buildStatCard(
          'İptal Edilen',
          _cancelledDeliveries.toString(),
          Icons.cancel,
          const Color(0xFFD32F2F),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Günlük Trend Grafiği
  Widget _buildDailyTrendChart() {
    if (_dailyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Günlük Teslimat Trendi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _dailyStats.length) {
                          return Text(
                            _dailyStats[index]['date'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dailyStats.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['count'].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF2E7D32),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Platform Entegrasyonları (Yakında)
  Widget _buildPlatformIntegrations() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '🚧 Bu Özellik Yakında Eklenecek',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trendyol, Getir ve diğer platform siparişlerinizin\nanalizi burada görüntülenecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlatformIcon('🛒', 'Trendyol'),
              const SizedBox(width: 16),
              _buildPlatformIcon('🚀', 'Getir'),
              const SizedBox(width: 16),
              _buildPlatformIcon('🍕', 'Yemeksepeti'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformIcon(String emoji, String name) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
