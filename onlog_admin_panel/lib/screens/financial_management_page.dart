import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class FinancialManagementPage extends StatefulWidget {
  const FinancialManagementPage({super.key});

  @override
  State<FinancialManagementPage> createState() => _FinancialManagementPageState();
}

class _FinancialManagementPageState extends State<FinancialManagementPage> {
  double _totalRevenue = 0;
  double _totalCommission = 0;
  int _totalDeliveries = 0;
  double _totalMerchantWallets = 0;
  double _totalCourierWallets = 0;
  int _totalTransactions = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    try {
      // Payment transactions'ı yükle
      final transactionsResponse = await SupabaseService.from('payment_transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      
      final allTransactionsResponse = await SupabaseService.from('payment_transactions')
          .select();
      
      // Merchant wallets toplamı
      final merchantWalletsResponse = await SupabaseService.from('merchant_wallets')
          .select('balance');
      
      // Courier wallets toplamı  
      final courierWalletsResponse = await SupabaseService.from('courier_wallets')
          .select('balance');
      
      // Teslim edilen siparişler
      final deliveredOrdersResponse = await SupabaseService.from('orders')
          .select()
          .eq('status', 'DELIVERED');

      double merchantTotal = 0;
      for (final wallet in merchantWalletsResponse) {
        merchantTotal += (wallet['balance'] ?? 0).toDouble();
      }
      
      double courierTotal = 0;
      for (final wallet in courierWalletsResponse) {
        courierTotal += (wallet['balance'] ?? 0).toDouble();
      }
      
      double revenue = 0;
      double commission = 0;
      
      for (final transaction in allTransactionsResponse) {
        final amount = (transaction['amount'] ?? 0).toDouble().abs();
        final type = transaction['type'] ?? '';
        
        if (type == 'orderPayment') {
          revenue += amount;
        } else if (type == 'commission') {
          commission += amount;
        }
      }
      
      setState(() {
        _totalRevenue = revenue;
        _totalCommission = commission;
        _totalDeliveries = deliveredOrdersResponse.length;
        _totalMerchantWallets = merchantTotal;
        _totalCourierWallets = courierTotal;
        _totalTransactions = allTransactionsResponse.length;
        _recentTransactions = List<Map<String, dynamic>>.from(transactionsResponse);
        _isLoading = false;
      });
      
      print('📊 Finansal veri yüklendi:');
      print('  - Toplam gelir: $_totalRevenue ₺');
      print('  - Komisyon: $_totalCommission ₺');
      print('  - Teslimat sayısı: $_totalDeliveries');
      print('  - Merchant cüzdan toplamı: $_totalMerchantWallets ₺');
      print('  - Courier cüzdan toplamı: $_totalCourierWallets ₺');
      
    } catch (e) {
      print('❌ Finansal veri yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Finansal Yönetim'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel Bakış',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Toplam Gelir',
                          '${_totalRevenue.toStringAsFixed(2)} ₺',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Komisyon',
                          '${_totalCommission.toStringAsFixed(2)} ₺',
                          Icons.percent,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Teslimat Sayısı',
                          _totalDeliveries.toString(),
                          Icons.local_shipping,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'İşlem Sayısı',
                          _totalTransactions.toString(),
                          Icons.receipt,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Merchant Cüzdanları',
                          '${_totalMerchantWallets.toStringAsFixed(2)} ₺',
                          Icons.account_balance_wallet,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Courier Cüzdanları',
                          '${_totalCourierWallets.toStringAsFixed(2)} ₺',
                          Icons.wallet,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Son İşlemler',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _recentTransactions.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Henüz işlem yok'),
                          ),
                        )
                      : Column(
                          children: _recentTransactions
                              .map((transaction) => _buildTransactionCard(transaction))
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] ?? 0).toDouble();
    final type = transaction['type'] ?? '';
    final status = transaction['status'] ?? '';
    final createdAt = transaction['created_at'] ?? '';
    
    IconData icon;
    Color color;
    String typeText;
    
    switch (type) {
      case 'orderPayment':
        icon = Icons.shopping_cart;
        color = Colors.green;
        typeText = 'Sipariş Ödemesi';
        break;
      case 'deliveryFee':
        icon = Icons.delivery_dining;
        color = Colors.blue;
        typeText = 'Teslimat Ücreti';
        break;
      case 'commission':
        icon = Icons.percent;
        color = Colors.orange;
        typeText = 'Komisyon';
        break;
      case 'withdrawal':
        icon = Icons.account_balance;
        color = Colors.red;
        typeText = 'Para Çekme';
        break;
      default:
        icon = Icons.payment;
        color = Colors.grey;
        typeText = 'Bilinmeyen';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(typeText),
        subtitle: Text('Durum: $status'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amount >= 0 ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
            Text(
              _formatDate(createdAt),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Tarih yok';
    }
  }
}
