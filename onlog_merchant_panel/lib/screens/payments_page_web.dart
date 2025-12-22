import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:intl/intl.dart';

/// 💰 Modern Web Ödemeler Sayfası
class PaymentsPageWeb extends StatefulWidget {
  const PaymentsPageWeb({super.key});

  @override
  State<PaymentsPageWeb> createState() => _PaymentsPageWebState();
}

class _PaymentsPageWebState extends State<PaymentsPageWeb> {
  bool _isLoading = true;
  
  double _totalDebt = 0.0;
  double _totalEarnings = 0.0;
  double _totalCommissions = 0.0;
  
  List<Map<String, dynamic>> _transactions = [];
  
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return;
      
      // Wallet bilgileri
      final walletResponse = await SupabaseService.from('merchant_wallets')
          .select()
          .eq('merchant_id', currentUser.id)
          .maybeSingle();
      
      if (walletResponse != null) {
        _totalDebt = (walletResponse['balance'] ?? 0.0).toDouble();
        _totalEarnings = (walletResponse['total_earnings'] ?? 0.0).toDouble();
        _totalCommissions = (walletResponse['total_commissions'] ?? 0.0).toDouble();
      }
      
      // Son işlemler
      final deliveriesResponse = await SupabaseService.from('delivery_requests')
          .select('id, package_count, declared_amount, merchant_payment_due, created_at, delivered_at')
          .eq('merchant_id', currentUser.id)
          .eq('status', 'delivered')
          .order('created_at', ascending: false)
          .limit(30);
      
      _transactions = (deliveriesResponse as List).map((d) => {
        'type': 'deliveryCommission',
        'amount': -(d['merchant_payment_due'] ?? 0.0),
        'commission_amount': d['merchant_payment_due'] ?? 0.0,
        'created_at': d['delivered_at'] ?? d['created_at'],
        'package_count': d['package_count'],
        'declared_amount': d['declared_amount'],
      }).toList();
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Ödeme verileri yüklenemedi: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50), size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Ödemeler',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // İstatistik Kartları
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                            'Toplam Kazanç',
                            _totalEarnings,
                            Icons.trending_up,
                            const Color(0xFF4CAF50),
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            'Komisyonlar',
                            _totalCommissions,
                            Icons.receipt,
                            const Color(0xFFFF9800),
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            'Net Bakiye',
                            _totalDebt,
                            Icons.account_balance,
                            _totalDebt >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                          )),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // İşlem Geçmişi
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  const Text(
                                    'İşlem Geçmişi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_transactions.length} işlem',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            _transactions.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(48),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                                          SizedBox(height: 16),
                                          Text(
                                            'Henüz işlem yok',
                                            style: TextStyle(color: Colors.grey, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _transactions.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final transaction = _transactions[index];
                                      return _buildTransactionRow(transaction);
                                    },
                                  ),
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
  
  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionRow(Map<String, dynamic> transaction) {
    final commissionAmount = (transaction['commission_amount'] ?? 0.0) as double;
    final packageCount = transaction['package_count'] ?? 1;
    final declaredAmount = (transaction['declared_amount'] ?? 0.0) as double;
    final date = DateTime.parse(transaction['created_at']);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt, color: Color(0xFFFF9800), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teslimat Komisyonu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$packageCount paket • ${_currencyFormat.format(declaredAmount)} tahsilat',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(date),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(commissionAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF44336),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Komisyon',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
