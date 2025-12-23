import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:intl/intl.dart';

/// 💰 Modern Kazançlar Sayfası
/// Profesyonel, net, anlaşılır tasarım
class ModernEarningsScreen extends StatefulWidget {
  final String courierId;

  const ModernEarningsScreen({super.key, required this.courierId});

  @override
  State<ModernEarningsScreen> createState() => _ModernEarningsScreenState();
}

class _ModernEarningsScreenState extends State<ModernEarningsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  double _totalEarnings = 0;
  double _availableBalance = 0;
  double _pendingPayments = 0;
  
  String _selectedPeriod = 'all'; // 'all', 'week', 'month'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Kurye cüzdanını çek
      final walletResponse = await SupabaseService.client
          .from('courier_wallets')
          .select('balance')
          .eq('courier_id', widget.courierId)
          .maybeSingle();
      
      _availableBalance = (walletResponse?['balance'] ?? 0.0).toDouble();
      
      // Teslimatları çek
      DateTime? filterDate;
      if (_selectedPeriod == 'week') {
        filterDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 'month') {
        filterDate = DateTime.now().subtract(const Duration(days: 30));
      }
      
      // Teslim edilmiş siparişleri çek (status = 'delivered')
      final allDeliveries = List<Map<String, dynamic>>.from(
        await SupabaseService.client
            .from('delivery_requests')
            .select('*')
            .eq('courier_id', widget.courierId)
            .eq('status', 'delivered') // ✅ Küçük harf!
            .order('created_at', ascending: false),
      );
      
      print('📦 Toplam ${allDeliveries.length} teslim edilmiş sipariş bulundu');
      if (allDeliveries.isNotEmpty) {
        print('İlk sipariş: ${allDeliveries[0]}');
      }
      
      // Client-side tarih filtresi
      List<Map<String, dynamic>> deliveries = allDeliveries;
      if (filterDate != null) {
        final nonNullFilterDate = filterDate; // Null-safety için
        deliveries = allDeliveries.where((delivery) {
          final deliveredAt = delivery['delivered_at'];
          if (deliveredAt == null) return false;
          final deliveryDate = DateTime.parse(deliveredAt);
          return deliveryDate.isAfter(nonNullFilterDate);
        }).toList();
      } else {
        deliveries = allDeliveries;
      }
      
      // Kazançları hesapla
      _totalEarnings = 0;
      _pendingPayments = 0;
      
      for (var delivery in deliveries) {
        final amount = (delivery['courier_payment_due'] ?? 0.0).toDouble();
        _totalEarnings += amount;
        
        final paymentStatus = delivery['payment_status'] ?? 'pending';
        if (paymentStatus == 'pending') {
          _pendingPayments += amount;
        }
      }
      
      _transactions = deliveries;
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Kazanç yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kazançlarım',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3436),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Bakiye Kartı
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildBalanceCard(),
                    ),
                  ),
                  
                  // İstatistik Kartları
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Toplam Kazanç',
                              '₺${_totalEarnings.toStringAsFixed(2)}',
                              Icons.trending_up_rounded,
                              const Color(0xFF00B894),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Bekleyen',
                              '₺${_pendingPayments.toStringAsFixed(2)}',
                              Icons.hourglass_empty_rounded,
                              const Color(0xFFFFA502),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Filtre Butonları
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildPeriodFilter(),
                    ),
                  ),
                  
                  // İşlem Listesi Başlığı
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            'Son İşlemler',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_transactions.length} işlem',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // İşlem Listesi
                  _transactions.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Henüz işlem yok',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Teslimat yaptıkça burada görünecek',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final transaction = _transactions[index];
                                return _buildTransactionItem(transaction);
                              },
                              childCount: _transactions.length,
                            ),
                          ),
                        ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF00A383)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Ödeme talep et
                  _showWithdrawDialog();
                },
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Çek',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Kullanılabilir Bakiye',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₺${_availableBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Row(
      children: [
        _filterChip('Tümü', 'all'),
        const SizedBox(width: 8),
        _filterChip('Bu Hafta', 'week'),
        const SizedBox(width: 8),
        _filterChip('Bu Ay', 'month'),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00B894) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00B894).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final amount = (transaction['courier_payment_due'] ?? 0.0).toDouble();
    final merchantName = transaction['merchant_name'] ?? 'Restoran';
    final deliveredAt = transaction['delivered_at'];
    final paymentStatus = transaction['payment_status'] ?? 'pending';
    
    final dateStr = deliveredAt != null
        ? DateFormat('dd MMM, HH:mm', 'tr_TR').format(DateTime.parse(deliveredAt))
        : 'Tarih yok';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: paymentStatus == 'paid'
                  ? const Color(0xFF00B894).withOpacity(0.1)
                  : const Color(0xFFFFA502).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              paymentStatus == 'paid'
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              color: paymentStatus == 'paid'
                  ? const Color(0xFF00B894)
                  : const Color(0xFFFFA502),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchantName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: paymentStatus == 'paid'
                            ? const Color(0xFF00B894).withOpacity(0.1)
                            : const Color(0xFFFFA502).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        paymentStatus == 'paid' ? 'Ödendi' : 'Bekliyor',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: paymentStatus == 'paid'
                              ? const Color(0xFF00B894)
                              : const Color(0xFFFFA502),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '+₺${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00B894),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Para Çek',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kullanılabilir bakiyeniz:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '₺${_availableBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00B894),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Para çekme işlemi 1-3 iş günü içinde IBAN\'ınıza yatırılacaktır.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Ödeme talep et
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Para çekme talebi oluşturuldu'),
                  backgroundColor: Color(0xFF00B894),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Talep Oluştur'),
          ),
        ],
      ),
    );
  }
}
