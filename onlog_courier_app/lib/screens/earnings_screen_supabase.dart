import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class EarningsScreenSupabase extends StatefulWidget {
  final String courierId;

  const EarningsScreenSupabase({
    super.key,
    required this.courierId,
  });

  @override
  State<EarningsScreenSupabase> createState() => _EarningsScreenSupabaseState();
}

class _EarningsScreenSupabaseState extends State<EarningsScreenSupabase> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveries = [];
  double _totalEarnings = 0;
  double _pendingEarnings = 0;
  double _paidEarnings = 0;
  
  // Filtreleme
  String _selectedFilter = 'all'; // 'all', 'week', 'month', 'year'
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null).then((_) {
      _loadEarnings();
    });
  }

  Future<void> _loadEarnings({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _deliveries = [];
      });
    }
    
    try {
      // Tarih filtresi hesapla
      DateTime? filterDate;
      if (_selectedFilter == 'week') {
        filterDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (_selectedFilter == 'month') {
        filterDate = DateTime.now().subtract(const Duration(days: 30));
      } else if (_selectedFilter == 'year') {
        filterDate = DateTime.now().subtract(const Duration(days: 365));
      }
      
      // Sayfalama ile veri çek
      var queryBuilder = SupabaseService.from('delivery_requests').select();
      
      queryBuilder = queryBuilder.eq('courier_id', widget.courierId);
      
      // Tarih filtresi ekle
      if (filterDate != null) {
        queryBuilder = queryBuilder.filter('created_at', 'gte', filterDate.toIso8601String());
      }
      
      final deliveriesResponse = await queryBuilder
          .order('created_at', ascending: false)
          .range(_currentPage * _itemsPerPage, (_currentPage + 1) * _itemsPerPage - 1);
      
      final newDeliveries = List<Map<String, dynamic>>.from(deliveriesResponse);
      
      // Daha fazla veri var mı kontrol et
      _hasMore = newDeliveries.length == _itemsPerPage;
      
      // Kazançları hesapla (tüm veriler için)
      if (!loadMore) {
        _totalEarnings = 0;
        _pendingEarnings = 0;
        _paidEarnings = 0;
      }
      
      // Toplam kazanç için tüm kayıtları çek (filtre ile)
      var totalQueryBuilder = SupabaseService.from('delivery_requests').select();
      totalQueryBuilder = totalQueryBuilder.eq('courier_id', widget.courierId);
      
      if (filterDate != null) {
        totalQueryBuilder = totalQueryBuilder.filter('created_at', 'gte', filterDate.toIso8601String());
      }
      
      final allDeliveries = List<Map<String, dynamic>>.from(await totalQueryBuilder);
      
      for (var delivery in allDeliveries) {
        // courier_payment_due → Kuryeye ödenecek tutar
        final amount = (delivery['courier_payment_due'] ?? 0).toDouble();
        final paymentStatus = delivery['payment_status'] ?? 'pending';
        
        _totalEarnings += amount;
        if (paymentStatus == 'paid') {
          _paidEarnings += amount;
        } else {
          _pendingEarnings += amount;
        }
      }
      
      // Teslimat listesini güncelle
      List<Map<String, dynamic>> displayDeliveries = [];
      for (var delivery in newDeliveries) {
        final amount = (delivery['courier_payment_due'] ?? 0).toDouble();
        final paymentStatus = delivery['payment_status'] ?? 'pending';
        
        // Teslimat bilgisini ekle
        final pickupLocation = delivery['pickup_location'];
        String address = 'Adres bilgisi yok';
        if (pickupLocation != null && pickupLocation is Map) {
          address = 'Lat: ${pickupLocation['latitude']}, Lng: ${pickupLocation['longitude']}';
        }
        
        displayDeliveries.add({
          'id': delivery['id'],
          'amount': amount,
          'status': delivery['status'],
          'payment_status': paymentStatus,
          'created_at': delivery['created_at'],
          'delivery_address': address,
          'package_count': delivery['package_count'] ?? 1,
        });
      }
      
      setState(() {
        if (loadMore) {
          _deliveries.addAll(displayDeliveries);
          _currentPage++;
        } else {
          _deliveries = displayDeliveries;
        }
      });
      
      print('✅ Toplam kazanç: $_totalEarnings TL');
      print('✅ Ödenen: $_paidEarnings TL, Bekleyen: $_pendingEarnings TL');
      
    } catch (e) {
      print('❌ Kazanç yükleme hatası: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: CustomScrollView(
                slivers: [
                  // Modern SliverAppBar
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    backgroundColor: const Color(0xFF2E7D32),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -50,
                              bottom: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.payments, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Kazançlarım',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _loadEarnings,
                        tooltip: 'Yenile',
                      ),
                    ],
                  ),
                  
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Özet Kartları
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                    
                        // Para Çekme Butonu
                        if (_pendingEarnings > 0) ...[
                          _buildWithdrawButton(),
                          const SizedBox(height: 24),
                        ],
                    
                        // Teslimat Geçmişi Başlığı
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.3)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Teslimat Geçmişi',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${_deliveries.length} tamamlanmış teslimat',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Filtre Butonları
                        _buildFilterButtons(),
                        const SizedBox(height: 16),
                    
                        if (_deliveries.isEmpty)
                          _buildEmptyState()
                        else ...[
                          ..._deliveries.map((delivery) => _buildEarningCard(delivery)),
                          
                          // Daha Fazla Yükle Butonu
                          if (_hasMore)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: OutlinedButton.icon(
                                onPressed: () => _loadEarnings(loadMore: true),
                                icon: const Icon(Icons.arrow_downward_rounded),
                                label: const Text('Daha Fazla Yükle'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tümü', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Son 7 Gün', 'week'),
          const SizedBox(width: 8),
          _buildFilterChip('Son 30 Gün', 'month'),
          const SizedBox(width: 8),
          _buildFilterChip('Son 1 Yıl', 'year'),
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
        });
        _loadEarnings();
      },
      selectedColor: const Color(0xFF4CAF50),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        // Toplam Kazanç - Büyük Kart
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_deliveries.length} Teslimat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Toplam Kazancınız',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₺${_totalEarnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Bekleyen ve Ödenen - Yan Yana
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        color: Colors.orange[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bekleyen',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${_pendingEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ödendi',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${_paidEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWithdrawButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Para çekme işlemi
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    const Text('Para Çek'),
                  ],
                ),
                content: Text(
                  'Para çekme işlemi için admin ile iletişime geçiniz.\n\nBekleyen kazancınız: ₺${_pendingEarnings.toStringAsFixed(2)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Para Çek',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '₺${_pendingEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningCard(Map<String, dynamic> delivery) {
    final amount = (delivery['amount'] ?? 0).toDouble();
    final status = delivery['status'] ?? 'pending';
    final isPaid = status == 'completed';
    final createdAt = delivery['created_at'] != null
        ? DateTime.parse(delivery['created_at'])
        : DateTime.now();
    
    // ✅ Database: delivery_location (JSON object)
    String deliveryAddress = 'Adres bilgisi yok';
    final deliveryLocation = delivery['delivery_location'];
    if (deliveryLocation is Map && deliveryLocation['address'] != null) {
      deliveryAddress = deliveryLocation['address'].toString();
    } else if (delivery['delivery_address'] != null) {
      // Fallback: eski format
      deliveryAddress = delivery['delivery_address'].toString();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? Colors.blue.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPaid 
                      ? [Colors.blue[400]!, Colors.blue[600]!]
                      : [Colors.orange[400]!, Colors.orange[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isPaid ? Colors.blue : Colors.orange).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.access_time,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş #${delivery['order_id']?.toString().substring(0, 8) ?? 'N/A'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deliveryAddress,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.blue[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPaid ? Colors.blue[200]! : Colors.orange[200]!,
                      ),
                    ),
                    child: Text(
                      isPaid ? '✓ Ödendi' : '⏳ Bekliyor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? Colors.blue[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isPaid ? Colors.blue : Colors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kazanç',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz Kazanç Yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'İlk teslimatınızı tamamladığınızda\nkazançlarınız burada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
          ),
        ],
      ),
    );
  }
}
