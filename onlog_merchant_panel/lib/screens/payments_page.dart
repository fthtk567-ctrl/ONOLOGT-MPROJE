import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:intl/intl.dart';

/// 💰 ÖDEMELER SAYFASI
/// Merchant'ın borç durumunu ve ödeme geçmişini gösterir
class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  bool _isLoading = true;
  
  // Wallet bilgileri
  double _totalDebt = 0.0;          // Toplam borç
  double _pendingDebt = 0.0;        // Bu hafta birikmiş borç
  double _totalEarnings = 0.0;      // Toplam satış
  double _totalCommissions = 0.0;   // Toplam komisyon
  double _totalPayments = 0.0;      // Toplam ödediği
  
  // İşlem geçmişi
  List<Map<String, dynamic>> _transactions = [];
  
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
      
      // Wallet bilgilerini çek
      final walletResponse = await SupabaseService.from('merchant_wallets')
          .select()
          .eq('merchant_id', currentUser.id)
          .maybeSingle();
      
      if (walletResponse != null) {
        setState(() {
          _totalDebt = (walletResponse['balance'] ?? 0.0).toDouble();
          _pendingDebt = (walletResponse['pending_balance'] ?? 0.0).toDouble();
          _totalEarnings = (walletResponse['total_earnings'] ?? 0.0).toDouble();
          _totalCommissions = (walletResponse['total_commissions'] ?? 0.0).toDouble();
          _totalPayments = (walletResponse['total_withdrawals'] ?? 0.0).toDouble();
        });
      }
      
      // Son işlemleri çek (delivery_requests tablosundan - tamamlanan teslimatlar)
      final deliveriesResponse = await SupabaseService.from('delivery_requests')
          .select('id, status, package_count, declared_amount, merchant_payment_due, system_commission, created_at, delivered_at, completed_at')
          .eq('merchant_id', currentUser.id)
          .eq('status', 'delivered') // Sadece tamamlananlar
          .order('created_at', ascending: false)
          .limit(50);
      
      // Delivery'leri transaction formatına çevir
      final List<Map<String, dynamic>> formattedTransactions = [];
      for (var delivery in deliveriesResponse) {
        formattedTransactions.add({
          'type': 'deliveryCommission',
          'amount': -(delivery['merchant_payment_due'] ?? 0.0),
          'commission_amount': delivery['merchant_payment_due'] ?? 0.0,
          'created_at': delivery['delivered_at'] ?? delivery['completed_at'] ?? delivery['created_at'],
          'status': 'completed',
          'order_id': null,
          'delivery_request_id': delivery['id'],
          'package_count': delivery['package_count'],
          'declared_amount': delivery['declared_amount'],
        });
      }
      
      setState(() {
        _transactions = formattedTransactions;
      });
      
    } catch (e) {
      print('❌ Ödeme verileri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('💰 Ödemeler ve Borç Durumu'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Borç durumu kartı
                    _buildDebtStatusCard(),
                    const SizedBox(height: 16),
                    
                    // İstatistikler
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    
                    // Açıklama
                    _buildInfoBanner(),
                    const SizedBox(height: 24),
                    
                    // İşlem geçmişi
                    _buildTransactionHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Borç Durumu Kartı
  Widget _buildDebtStatusCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade700, Colors.deepOrange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Borç Durumunuz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Bu hafta birikmiş borç
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⏳ Bu Hafta Birikmiş Borç',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_pendingDebt.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Haftalık ödeme gününde tahsil edilecek',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Toplam borç
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam Borç:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '${_totalDebt.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// İstatistik Kartları
  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '📊 Toplam Satış',
            '${_totalEarnings.toStringAsFixed(2)} ₺',
            Colors.blue,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '💸 Toplam Komisyon',
            '${_totalCommissions.toStringAsFixed(2)} ₺',
            Colors.orange,
            Icons.percent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bilgilendirme Banner
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ödemeler haftalık olarak tahsil edilir. '
              'Her teslimatın komisyonu otomatik olarak borcunuza eklenir.',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// İşlem Geçmişi
  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 İşlem Geçmişi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        if (_transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz işlem geçmişi yok',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? '';
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final commissionAmount = (transaction['commission_amount'] ?? 0.0).toDouble();
    final createdAt = DateTime.parse(transaction['created_at'].toString());
    final status = transaction['status'] ?? 'pending';
    final orderId = transaction['order_id'];
    final deliveryRequestId = transaction['delivery_request_id']; // 🆕 Teslimat ID
    
    // İkon ve renk
    IconData icon;
    Color color;
    String title;
    String subtitle;
    
    if (type == 'merchantPayment') {
      // Merchant bize ödeme yaptı (GELİR)
      icon = Icons.payment;
      color = Colors.green;
      title = '💵 Komisyon Ödemesi Yapıldı';
      subtitle = '${amount.toStringAsFixed(2)} ₺ ödendi';
    } else if (type == 'deliveryCommission') {
      // Teslimat komisyonu (delivery_requests'ten)
      icon = Icons.local_shipping;
      color = Colors.red;
      
      final packageCount = transaction['package_count'] ?? 1;
      final declaredAmount = (transaction['declared_amount'] ?? 0.0).toDouble();
      
      if (deliveryRequestId != null) {
        final shortId = deliveryRequestId.toString().substring(0, 8);
        title = '📦 Teslimat #$shortId';
      } else {
        title = '📦 Teslimat Komisyonu';
      }
      
      subtitle = '$packageCount paket • Tutar: ${declaredAmount.toStringAsFixed(2)} ₺ • Komisyon: ${commissionAmount.toStringAsFixed(2)} ₺';
    } else if (type == 'orderPayment') {
      // Sipariş komisyonu (GİDER - KESİNTİ)
      icon = Icons.local_shipping;
      color = Colors.red;
      
      // Teslimat ID'sini göster
      if (deliveryRequestId != null) {
        final shortId = deliveryRequestId.toString().substring(0, 8);
        title = '📦 Teslimat #$shortId';
      } else if (orderId != null) {
        final shortId = orderId.toString().substring(0, 8);
        title = '📦 Sipariş #$shortId';
      } else {
        title = '📦 Teslimat Komisyonu';
      }
      
      subtitle = 'Komisyon kesintisi: ${commissionAmount.toStringAsFixed(2)} ₺';
    } else if (type == 'commission') {
      // Genel komisyon kesintisi
      icon = Icons.percent;
      color = Colors.orange;
      title = '💸 Komisyon Kesintisi';
      subtitle = '${amount.abs().toStringAsFixed(2)} ₺ kesildi';
    } else {
      icon = Icons.receipt;
      color = Colors.grey;
      title = type;
      subtitle = '${amount.toStringAsFixed(2)} ₺';
    }
    
    // Durum badge
    Widget statusBadge;
    if (status == 'completed' || status == 'settled') {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '✅ Tamamlandı',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '⏳ Bekliyor',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // Tutarın yönü (+ gelir, - gider)
    final isIncome = type == 'merchantPayment' || amount > 0;
    final displayAmount = isIncome ? amount : -commissionAmount;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            // Tutar (sağda büyük)
            Text(
              '${isIncome ? "+" : ""}${displayAmount.toStringAsFixed(2)} ₺',
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                statusBadge,
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
