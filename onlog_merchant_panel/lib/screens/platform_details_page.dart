import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PlatformDetailsPage extends StatefulWidget {
  final String platformName;
  final bool isActive;

  const PlatformDetailsPage({
    super.key,
    required this.platformName,
    required this.isActive,
  });

  @override
  State<PlatformDetailsPage> createState() => _PlatformDetailsPageState();
}

class _PlatformDetailsPageState extends State<PlatformDetailsPage> {
  final List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  
  String _selectedPeriod = 'Son 7 Gün';
  String _selectedStatus = 'Tümü';
  String _selectedSort = 'Tarihe Göre (Yeni)';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _showExcelView = false;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  void _loadOrders() async {
    // Test modunu kontrol et
    bool isTestMode = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      isTestMode = prefs.getBool('api_test_mode') ?? false;
    } catch (e) {
      isTestMode = false;
    }
    
    if (isTestMode) {
      print('🟡 TEST MODU: ${widget.platformName} sahte siparişleri gösteriliyor');
      _generateSampleOrders();
    } else {
      print('🔴 TEST MODU KAPALI: ${widget.platformName} gerçek API verileri');
      // Gerçek API'den sipariş verilerini yükle
      // Şimdilik boş liste
      _orders.clear();
    }
    
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        // Tarih filtresi
        if (_selectedPeriod != 'Tümü' && _selectedPeriod != 'Özel Tarih') {
          final orderDate = DateTime.parse(order['order_date']);
          final now = DateTime.now();
          
          switch (_selectedPeriod) {
            case 'Son 7 Gün':
              if (!orderDate.isAfter(now.subtract(const Duration(days: 7)))) return false;
              break;
            case 'Son 30 Gün':
              if (!orderDate.isAfter(now.subtract(const Duration(days: 30)))) return false;
              break;
          }
        } else if (_selectedPeriod == 'Özel Tarih' && _customStartDate != null && _customEndDate != null) {
          final orderDate = DateTime.parse(order['order_date']);
          if (orderDate.isBefore(_customStartDate!) || orderDate.isAfter(_customEndDate!)) {
            return false;
          }
        }

        // Durum filtresi
        if (_selectedStatus != 'Tümü') {
          if (order['status'] != _selectedStatus) return false;
        }

        return true;
      }).toList();

      // Sıralama
      switch (_selectedSort) {
        case 'Tarihe Göre (Yeni)':
          _filteredOrders.sort((a, b) => DateTime.parse(b['order_date']).compareTo(DateTime.parse(a['order_date'])));
          break;
        case 'Tarihe Göre (Eski)':
          _filteredOrders.sort((a, b) => DateTime.parse(a['order_date']).compareTo(DateTime.parse(b['order_date'])));
          break;
        case 'Tutara Göre (Yüksek)':
          _filteredOrders.sort((a, b) => (b['total_amount'] as double).compareTo(a['total_amount'] as double));
          break;
        case 'Tutara Göre (Düşük)':
          _filteredOrders.sort((a, b) => (a['total_amount'] as double).compareTo(b['total_amount'] as double));
          break;
      }
    });
  }

  void _generateSampleOrders() {
    final random = Random();
    final courierNames = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya', 'Fatma Şen', 'Ali Özkan'];
    final plates = ['34 ABC 123', '06 DEF 456', '35 GHI 789', '01 JKL 012', '07 MNO 345'];
    final addresses = ['Kadıköy/İstanbul', 'Çankaya/Ankara', 'Konak/İzmir', 'Merkez/Adana', 'Keçiören/Ankara'];
    final statuses = ['Beklemede', 'Hazırlanıyor', 'Yolda', 'Teslim Edildi'];

    for (int i = 0; i < 50; i++) {
      final orderDate = DateTime.now().subtract(Duration(days: random.nextInt(60)));
      _orders.add({
        'order_id': 'ORD${1000 + i}',
        'order_date': orderDate.toIso8601String(),
        'customer_name': 'Müşteri ${i + 1}',
        'total_amount': 50.0 + (random.nextDouble() * 200),
        'status': statuses[random.nextInt(statuses.length)],
        'courier_name': courierNames[random.nextInt(courierNames.length)],
        'courier_plate': plates[random.nextInt(plates.length)],
        'delivery_address': addresses[random.nextInt(addresses.length)],
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platformName} Detayları'),
        backgroundColor: widget.isActive ? Colors.green : Colors.orange,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showExcelView = !_showExcelView;
              });
            },
            icon: Icon(_showExcelView ? Icons.list : Icons.table_chart),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtreler
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPeriodFilter(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatusFilter(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSortFilter(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _resetFilters(),
                      child: const Text('Filtreleri Temizle'),
                    ),
                    const Spacer(),
                    Text('Toplam: ${_filteredOrders.length} sipariş'),
                  ],
                ),
              ],
            ),
          ),
          
          // İçerik
          Expanded(
            child: _showExcelView ? _buildExcelView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isExpanded: true,
          items: ['Tümü', 'Son 7 Gün', 'Son 30 Gün', 'Özel Tarih']
              .map((period) => DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
              if (value == 'Özel Tarih') {
                _showDateRangePicker();
              } else {
                _customStartDate = null;
                _customEndDate = null;
                _applyFilters();
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          items: ['Tümü', 'Beklemede', 'Hazırlanıyor', 'Yolda', 'Teslim Edildi']
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Widget _buildSortFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          isExpanded: true,
          items: [
            'Tarihe Göre (Yeni)',
            'Tarihe Göre (Eski)',
            'Tutara Göre (Yüksek)',
            'Tutara Göre (Düşük)',
          ].map((sort) => DropdownMenuItem(
                value: sort,
                child: Text(sort),
              ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSort = value!;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedDateRange = picked;
        _applyFilters();
      });
    } else {
      setState(() {
        _selectedPeriod = 'Son 7 Gün';
        _customStartDate = null;
        _customEndDate = null;
        _applyFilters();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedPeriod = 'Son 7 Gün';
      _selectedStatus = 'Tümü';
      _selectedSort = 'Tarihe Göre (Yeni)';
      _customStartDate = null;
      _customEndDate = null;
      _selectedDateRange = null;
      _applyFilters();
    });
  }

  Widget _buildListView() {
    if (_filteredOrders.isEmpty) {
      return const Center(
        child: Text('Sipariş bulunamadı'),
      );
    }

    return ListView.builder(
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text('Sipariş #${order['order_id']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Müşteri: ${order['customer_name']}'),
                Text('Tutar: ${order['total_amount'].toStringAsFixed(2)} ₺'),
                Text('Kurye: ${order['courier_name']}'),
                Text('Plaka: ${order['courier_plate']}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order['status']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order['status'],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            onTap: () {
              // Sipariş detayına git
            },
          ),
        );
      },
    );
  }

  Widget _buildExcelView() {
    if (_filteredOrders.isEmpty) {
      return const Center(
        child: Text('Sipariş bulunamadı'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Sipariş ID')),
            DataColumn(label: Text('Tarih')),
            DataColumn(label: Text('Müşteri')),
            DataColumn(label: Text('Tutar')),
            DataColumn(label: Text('Durum')),
            DataColumn(label: Text('Kurye')),
            DataColumn(label: Text('Plaka')),
            DataColumn(label: Text('Adres')),
          ],
          rows: _filteredOrders.map((order) {
            final index = _filteredOrders.indexOf(order);
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (states) => index % 2 == 0 ? Colors.grey[50] : null,
              ),
              cells: [
                DataCell(Text(order['order_id'])),
                DataCell(Text(DateTime.parse(order['order_date']).toString().split(' ')[0])),
                DataCell(Text(order['customer_name'])),
                DataCell(Text('${order['total_amount'].toStringAsFixed(2)} ₺')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order['status'],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                DataCell(Text(order['courier_name'])),
                DataCell(Text(order['courier_plate'])),
                DataCell(Text(order['delivery_address'])),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Beklemede':
        return Colors.orange;
      case 'Hazırlanıyor':
        return Colors.blue;
      case 'Yolda':
        return Colors.purple;
      case 'Teslim Edildi':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}



