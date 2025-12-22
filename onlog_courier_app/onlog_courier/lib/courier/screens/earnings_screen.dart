import 'package:flutter/material.dart';
import '../../shared/models/earnings.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;
  DailyEarnings? _todayEarnings;
  WeeklyEarnings? _weeklyEarnings;
  MonthlyEarnings? _monthlyEarnings;
  
  // Scroll kontrolcüleri
  final ScrollController _dailyScrollController = ScrollController();
  final ScrollController _weeklyScrollController = ScrollController();
  final ScrollController _monthlyScrollController = ScrollController();
  
  final List<String> _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  
  String _selectedMonth = '';
  int _selectedYear = DateTime.now().year;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedMonth = _months[DateTime.now().month - 1];
    _loadEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dailyScrollController.dispose();
    _weeklyScrollController.dispose();
    _monthlyScrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEarningsData() async {
    try {
      setState(() => _isLoading = true);
      
      // Normalde API'dan veri çekilir
      // Burada örnek veri oluşturuyoruz
      await Future.delayed(const Duration(seconds: 1));
      
      // Bugünün kazançları
      _todayEarnings = DailyEarnings(
        date: DateTime.now(),
        totalEarnings: 342.50,
        deliveryCount: 8,
        tipAmount: 25.00,
        bonusAmount: 15.00,
        deliveries: List.generate(8, (index) => 
          DeliveryEarning(
            id: 'D${100 + index}',
            amount: 35.0 + (index * 3.5),
            timestamp: DateTime.now().subtract(Duration(hours: index)),
            description: 'Teslimat #${100 + index}',
            tip: index % 3 == 0 ? 5.0 : 0.0,
            bonus: index == 4 ? 15.0 : 0.0,
          ),
        ),
      );
      
      // Haftalık kazançlar
      _weeklyEarnings = WeeklyEarnings(
        startDate: DateTime.now().subtract(const Duration(days: 6)),
        endDate: DateTime.now(),
        totalEarnings: 2185.75,
        deliveryCount: 54,
        tipAmount: 135.00,
        bonusAmount: 50.00,
        dailyEarnings: List.generate(7, (index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          return DailyEarnings(
            date: date,
            totalEarnings: 250.0 + (index * 25.0),
            deliveryCount: 6 + index,
            tipAmount: index * 5.0,
            bonusAmount: index == 3 ? 50.0 : 0.0,
            deliveries: [],
          );
        }),
      );
      
      // Aylık kazançlar
      _monthlyEarnings = MonthlyEarnings(
        month: DateTime.now().month,
        year: DateTime.now().year,
        totalEarnings: 8752.00,
        deliveryCount: 215,
        tipAmount: 520.00,
        totalHours: 124.5,
        totalDistance: 324.7,
        bonusAmount: 200.00,
        weeklyEarnings: [],
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenirken bir hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _todayEarnings == null || _weeklyEarnings == null || _monthlyEarnings == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kazançlarım'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'BUGÜN'),
              Tab(text: 'HAFTALIK'),
              Tab(text: 'AYLIK'),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kazançlarım'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'BUGÜN'),
            Tab(text: 'HAFTALIK'),
            Tab(text: 'AYLIK'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            controller: _dailyScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildDailyEarningsTab(),
          ),
          SingleChildScrollView(
            controller: _weeklyScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildWeeklyEarningsTab(),
          ),
          SingleChildScrollView(
            controller: _monthlyScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildMonthlyEarningsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyEarningsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_todayEarnings != null) ...[
              _buildEarningsSummaryCard(_todayEarnings!),
              const SizedBox(height: 16),
              Text(
                'Teslimatlar (${_todayEarnings!.deliveryCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._todayEarnings!.deliveries.map(_buildDeliveryItem),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyEarningsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_weeklyEarnings != null) ...[
              _buildWeeklyEarningsSummaryCard(_weeklyEarnings!),
              const SizedBox(height: 16),
              Text(
                'Günlere Göre (${_weeklyEarnings!.dailyEarnings.length} gün)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDailyEarningsChart(_weeklyEarnings!),
              const SizedBox(height: 24),
              ...List.generate(_weeklyEarnings!.dailyEarnings.length, (index) {
                final daily = _weeklyEarnings!.dailyEarnings[index];
                return _buildDailyEarningsItem(daily);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyEarningsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthYearSelector(),
            if (_monthlyEarnings != null) ...[
              const SizedBox(height: 16),
              _buildMonthlyEarningsSummaryCard(_monthlyEarnings!),
              const SizedBox(height: 16),
              _buildMonthlyPerformanceCard(),
              const SizedBox(height: 16),
              _buildMonthlyStats(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummaryCard(DailyEarnings earnings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${earnings.date.day} ${_getMonthName(earnings.date.month)} ${earnings.date.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${earnings.deliveryCount} Teslimat',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${earnings.totalEarnings.toStringAsFixed(2)} ₺',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'Toplam Kazanç',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEarningDetail('Teslimat', earnings.totalEarnings - earnings.tipAmount - earnings.bonusAmount),
                _buildEarningDetail('Bahşiş', earnings.tipAmount),
                _buildEarningDetail('Bonus', earnings.bonusAmount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyEarningsSummaryCard(WeeklyEarnings earnings) {
    final startDay = earnings.startDate.day;
    final endDay = earnings.endDate.day;
    final month = _getMonthName(earnings.endDate.month);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$startDay - $endDay $month',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${earnings.deliveryCount} Teslimat',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${earnings.totalEarnings.toStringAsFixed(2)} ₺',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'Haftalık Toplam',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEarningDetail('Teslimat', earnings.totalEarnings - earnings.tipAmount - earnings.bonusAmount),
                _buildEarningDetail('Bahşiş', earnings.tipAmount),
                _buildEarningDetail('Bonus', earnings.bonusAmount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyEarningsSummaryCard(MonthlyEarnings earnings) {
    final month = _getMonthName(earnings.month);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$month ${earnings.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${earnings.deliveryCount} Teslimat',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${earnings.totalEarnings.toStringAsFixed(2)} ₺',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'Aylık Toplam',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEarningDetail('Teslimat', earnings.totalEarnings - earnings.tipAmount - earnings.bonusAmount),
                _buildEarningDetail('Bahşiş', earnings.tipAmount),
                _buildEarningDetail('Bonus', earnings.bonusAmount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningDetail(String label, double amount) {
    return Column(
      children: [
        Text(
          '${amount.toStringAsFixed(2)} ₺',
          style: const TextStyle(
            fontSize: 16,
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

  Widget _buildDeliveryItem(DeliveryEarning delivery) {
    final hour = delivery.timestamp.hour.toString().padLeft(2, '0');
    final minute = delivery.timestamp.minute.toString().padLeft(2, '0');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$hour:$minute',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${delivery.totalAmount.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (delivery.hasTipOrBonus)
                  Text(
                    _getTipBonusText(delivery),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTipBonusText(DeliveryEarning delivery) {
    if (delivery.tip > 0 && delivery.bonus > 0) {
      return '${delivery.tip.toStringAsFixed(2)} ₺ bahşiş + ${delivery.bonus.toStringAsFixed(2)} ₺ bonus';
    } else if (delivery.tip > 0) {
      return '${delivery.tip.toStringAsFixed(2)} ₺ bahşiş';
    } else if (delivery.bonus > 0) {
      return '${delivery.bonus.toStringAsFixed(2)} ₺ bonus';
    }
    return '';
  }

  Widget _buildDailyEarningsChart(WeeklyEarnings weeklyEarnings) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(weeklyEarnings.dailyEarnings.length, (index) {
          final daily = weeklyEarnings.dailyEarnings[index];
          final dayPercent = daily.totalEarnings / weeklyEarnings.maxDailyEarning;
          
          return _buildChartBar(
            day: _getDayName(daily.date.weekday),
            height: dayPercent * 150, // Max height 150
            value: daily.totalEarnings,
            isToday: index == weeklyEarnings.dailyEarnings.length - 1,
          );
        }),
      ),
    );
  }

  Widget _buildChartBar({
    required String day,
    required double height,
    required double value,
    required bool isToday,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${value.toStringAsFixed(0)}₺',
          style: TextStyle(
            fontSize: 10,
            color: isToday ? Theme.of(context).primaryColor : Colors.grey[600],
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: isToday
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isToday ? Theme.of(context).primaryColor : Colors.grey[600],
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyEarningsItem(DailyEarnings daily) {
    final dayName = _getDayName(daily.date.weekday);
    final isToday = daily.date.day == DateTime.now().day;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      color: isToday ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isToday
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                color: isToday ? Theme.of(context).primaryColor : Colors.grey[600],
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dayName, ${daily.date.day} ${_getMonthName(daily.date.month)}',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  Text(
                    '${daily.deliveryCount} teslimat',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${daily.totalEarnings.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isToday ? Theme.of(context).primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Row(
      children: [
        DropdownButton<String>(
          value: _selectedMonth,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMonth = newValue;
                // Normalde burada veri yeniden yüklenirdi
              });
            }
          },
          items: _months.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          underline: Container(height: 1, color: Colors.grey[300]),
          icon: const Icon(Icons.arrow_drop_down),
        ),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: _selectedYear,
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedYear = newValue;
                // Normalde burada veri yeniden yüklenirdi
              });
            }
          },
          items: [DateTime.now().year - 1, DateTime.now().year]
              .map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          underline: Container(height: 1, color: Colors.grey[300]),
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ],
    );
  }

  Widget _buildMonthlyPerformanceCard() {
    if (_monthlyEarnings == null) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Performans bilgileri yüklenemedi'),
        ),
      );
    }

    final dailyAverage = _monthlyEarnings!.totalEarnings / 30;
    final perDeliveryAverage = _monthlyEarnings!.deliveryCount > 0 
      ? _monthlyEarnings!.totalEarnings / _monthlyEarnings!.deliveryCount
      : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performans Özeti',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPerformanceItem(
              'Günlük Ortalama',
              '${dailyAverage.toStringAsFixed(2)} ₺',
              Icons.calendar_today,
            ),
            const Divider(),
            _buildPerformanceItem(
              'Teslimat Başına Kazanç',
              '${perDeliveryAverage.toStringAsFixed(2)} ₺',
              Icons.delivery_dining,
            ),
            const Divider(),
            _buildPerformanceItem(
              'En Yüksek Günlük Kazanç',
              '542.50 ₺',
              Icons.arrow_upward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats() {
    if (_monthlyEarnings == null) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('İstatistikler yüklenemedi'),
        ),
      );
    }

    final totalHours = _monthlyEarnings!.totalHours ?? 0;
    final totalDistance = _monthlyEarnings!.totalDistance ?? 0;
    final hourlyRate = totalHours > 0 
      ? _monthlyEarnings!.totalEarnings / totalHours
      : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ek İstatistikler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Toplam KM', '${totalDistance.toStringAsFixed(1)} km', Icons.map),
                _buildStatItem('Çalışma Saati', '${totalHours.toStringAsFixed(1)} saat', Icons.access_time),
                _buildStatItem('Saat Başı', '${hourlyRate.toStringAsFixed(2)} ₺', Icons.speed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

  String _getMonthName(int month) {
    return _months[month - 1];
  }

  String _getDayName(int weekday) {
    final days = ['', 'Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    return days[weekday];
  }
}