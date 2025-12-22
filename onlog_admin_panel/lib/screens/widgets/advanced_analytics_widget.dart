import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:onlog_shared/services/supabase_service.dart';

/// Advanced Analytics Widget - Courier Performance & Heatmaps
class AdvancedAnalytics extends StatefulWidget {
  const AdvancedAnalytics({super.key});

  @override
  State<AdvancedAnalytics> createState() => _AdvancedAnalyticsState();
}

class _AdvancedAnalyticsState extends State<AdvancedAnalytics> {
  String _selectedMetric = 'deliveries'; // deliveries, revenue, rating
  final _supabase = SupabaseService.client;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📊 Gelişmiş Analitikler',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'deliveries', label: Text('Teslimat'), icon: Icon(Icons.local_shipping, size: 16)),
                ButtonSegment(value: 'revenue', label: Text('Gelir'), icon: Icon(Icons.attach_money, size: 16)),
                ButtonSegment(value: 'rating', label: Text('Puan'), icon: Icon(Icons.star, size: 16)),
              ],
              selected: {_selectedMetric},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedMetric = newSelection.first;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Charts Grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Courier Performance Ranking
            Expanded(
              flex: 2,
              child: _buildCourierPerformanceCard(),
            ),
            const SizedBox(width: 24),
            // Right: Time-based chart
            Expanded(
              flex: 3,
              child: _buildTimeSeriesCard(),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Delivery Heatmap by Hour
        _buildDeliveryHeatmapCard(),
      ],
    );
  }

  /// Courier Performance Ranking
  Widget _buildCourierPerformanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.leaderboard, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Kurye Performansı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'courier')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final couriers = snapshot.data!.docs;
                
                // Calculate metrics for each courier
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _calculateCourierMetrics(couriers),
                  builder: (context, metricsSnapshot) {
                    if (!metricsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final metrics = metricsSnapshot.data!;
                    metrics.sort((a, b) {
                      final aValue = (a[_selectedMetric] ?? 0) as num;
                      final bValue = (b[_selectedMetric] ?? 0) as num;
                      return bValue.compareTo(aValue);
                    });

                    return SizedBox(
                      height: 400,
                      child: ListView.builder(
                        itemCount: metrics.take(10).length,
                        itemBuilder: (context, index) {
                          final courier = metrics[index];
                          final value = courier[_selectedMetric] ?? 0;
                          final maxValue = metrics.first[_selectedMetric] ?? 1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Rank
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: index == 0
                                            ? Colors.amber
                                            : index == 1
                                                ? Colors.grey[400]
                                                : index == 2
                                                    ? Colors.orange[300]
                                                    : Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: index < 3 ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Name
                                    Expanded(
                                      child: Text(
                                        courier['name'] ?? 'Kurye ${index + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    // Value
                                    Text(
                                      _formatMetricValue(value),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: maxValue > 0 ? (value as num) / (maxValue as num) : 0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      index == 0
                                          ? Colors.amber
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Time Series Chart
  Widget _buildTimeSeriesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  _selectedMetric == 'deliveries'
                      ? 'Teslimat Trendi (Son 7 Gün)'
                      : _selectedMetric == 'revenue'
                          ? 'Gelir Trendi (Son 7 Gün)'
                          : 'Ortalama Puan (Son 7 Gün)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getTimeSeriesData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!;
                  
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < data.length) {
                                return Text(
                                  data[value.toInt()]['label'] ?? '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['value'] as num).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Delivery Heatmap by Hour
  Widget _buildDeliveryHeatmapCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Saatlik Teslimat Yoğunluğu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<Map<int, int>>(
              stream: _getHourlyDeliveryData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hourlyData = snapshot.data!;
                final maxDeliveries = hourlyData.values.fold<int>(0, (max, val) => val > max ? val : max);

                return SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(24, (hour) {
                      final deliveries = hourlyData[hour] ?? 0;
                      final intensity = maxDeliveries > 0 ? deliveries / maxDeliveries : 0.0;

                      return Expanded(
                        child: Tooltip(
                          message: '$hour:00 - $deliveries teslimat',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 120 * intensity + 30,
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(intensity),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Text(
                                  '$hour',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: intensity > 0.5 ? Colors.white : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Az', Colors.green[200]!),
                const SizedBox(width: 16),
                _buildLegendItem('Orta', Colors.amber[400]!),
                const SizedBox(width: 16),
                _buildLegendItem('Yoğun', Colors.red[400]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity > 0.7) return Colors.red[400]!;
    if (intensity > 0.4) return Colors.amber[400]!;
    if (intensity > 0.1) return Colors.green[300]!;
    return Colors.green[100]!;
  }

  String _formatMetricValue(dynamic value) {
    if (_selectedMetric == 'revenue') {
      return '₺${(value as num).toStringAsFixed(2)}';
    } else if (_selectedMetric == 'rating') {
      return '⭐ ${(value as num).toStringAsFixed(1)}';
    }
    return value.toString();
  }

  Future<List<Map<String, dynamic>>> _calculateCourierMetrics(List<QueryDocumentSnapshot> couriers) async {
    final List<Map<String, dynamic>> metrics = [];

    for (var courier in couriers) {
      final courierId = courier.id;
      final courierData = courier.data() as Map<String, dynamic>;

      // Get deliveries for this courier
      final deliveries = await FirebaseFirestore.instance
          .collection('deliveryRequests')
          .where('assignedCourierId', isEqualTo: courierId)
          .where('status', isEqualTo: 'delivered')
          .get();

      // Calculate metrics
      double totalRevenue = 0;
      double totalRating = 0;
      int ratingCount = 0;

      for (var delivery in deliveries.docs) {
        final data = delivery.data();
        if (data['courierCollectedAmount'] != null) {
          totalRevenue += (data['courierCollectedAmount'] as num).toDouble();
        }
        if (data['courierRating'] != null) {
          totalRating += (data['courierRating'] as num).toDouble();
          ratingCount++;
        }
      }

      metrics.add({
        'name': courierData['name'] ?? 'İsimsiz Kurye',
        'deliveries': deliveries.docs.length,
        'revenue': totalRevenue,
        'rating': ratingCount > 0 ? totalRating / ratingCount : 0,
      });
    }

    return metrics;
  }

  Stream<List<Map<String, dynamic>>> _getTimeSeriesData() async* {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final deliveries = await FirebaseFirestore.instance
          .collection('deliveryRequests')
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('deliveredAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      double value = 0;
      if (_selectedMetric == 'deliveries') {
        value = deliveries.docs.length.toDouble();
      } else if (_selectedMetric == 'revenue') {
        value = deliveries.docs.fold<double>(0, (sum, doc) {
          return sum + ((doc.data()['courierCollectedAmount'] as num?) ?? 0).toDouble();
        });
      } else if (_selectedMetric == 'rating') {
        final ratings = deliveries.docs
            .where((doc) => doc.data()['courierRating'] != null)
            .map((doc) => (doc.data()['courierRating'] as num).toDouble())
            .toList();
        value = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0;
      }

      data.add({
        'label': DateFormat('E').format(date),
        'value': value,
      });
    }

    yield data;
  }

  Stream<Map<int, int>> _getHourlyDeliveryData() async* {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final deliveries = await FirebaseFirestore.instance
        .collection('deliveryRequests')
        .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    final Map<int, int> hourlyData = {};
    for (int hour = 0; hour < 24; hour++) {
      hourlyData[hour] = 0;
    }

    for (var doc in deliveries.docs) {
      final data = doc.data();
      if (data['deliveredAt'] != null) {
        final deliveredAt = (data['deliveredAt'] as Timestamp).toDate();
        hourlyData[deliveredAt.hour] = (hourlyData[deliveredAt.hour] ?? 0) + 1;
      }
    }

    yield hourlyData;
  }
}
