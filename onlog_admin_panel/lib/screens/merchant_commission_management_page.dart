import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class MerchantCommissionManagementPage extends StatefulWidget {
  const MerchantCommissionManagementPage({super.key});

  @override
  State<MerchantCommissionManagementPage> createState() => _MerchantCommissionManagementPageState();
}

class _MerchantCommissionManagementPageState extends State<MerchantCommissionManagementPage> {
  List<Map<String, dynamic>> _merchants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    try {
      final response = await SupabaseService.from('users')
          .select()
          .eq('role', 'merchant')
          .order('business_name', ascending: true);
      
      setState(() {
        _merchants = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ İşletme yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCommission(String merchantId, Map<String, dynamic> currentSettings, Map<String, dynamic> newSettings) async {
    try {
      // ⚠️ ÇOK ÖNEMLİ: commission_updated_at tarihini de güncelle!
      // Eski siparişler eski oranla hesaplanmalı!
      await SupabaseService.from('users')
          .update({
            'commission_settings': newSettings,
            'commission_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', merchantId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Komisyon güncellendi'), backgroundColor: Colors.green),
      );
      _loadMerchants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// commission_settings JSONB'den bilgi al
  String _getCommissionDisplay(Map<String, dynamic> merchant) {
    try {
      final settings = merchant['commission_settings'];
      if (settings == null || settings is! Map) return '❓ Belirsiz';
      
      final type = settings['type'];
      
      if (type == 'percentage') {
        final rate = settings['commission_rate'] ?? 0.0;
        return '%${rate.toStringAsFixed(0)}';
      } else if (type == 'perOrder') {
        final fee = settings['per_order_fee'] ?? 0.0;
        return '${fee.toStringAsFixed(0)}₺/sipariş';
      }
      
      return '❓ Belirsiz';
    } catch (e) {
      print('⚠️ Komisyon okuma hatası: $e');
      return '❌ Hata';
    }
  }

  /// Komisyon güncelleme tarihini göster
  String _getLastUpdateDate(Map<String, dynamic> merchant) {
    try {
      final updateDate = merchant['commission_updated_at'];
      if (updateDate == null) return 'Hiç güncellenmedi';
      
      final date = DateTime.parse(updateDate.toString());
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 İşletme Komisyonları'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _merchants.isEmpty
              ? const Center(child: Text('İşletme bulunamadı'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _merchants.length,
                  itemBuilder: (context, index) {
                    final merchant = _merchants[index];
                    final commissionDisplay = _getCommissionDisplay(merchant);
                    final lastUpdate = _getLastUpdateDate(merchant);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          child: Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(merchant['business_name'] ?? 'İsimsiz'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(merchant['email'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              '🕐 Son güncelleme: $lastUpdate',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              commissionDisplay,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(merchant),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> merchant) async {
    final settings = merchant['commission_settings'] ?? {};
    final currentType = settings['type'] ?? 'percentage';
    final currentRate = (settings['commission_rate'] ?? 15.0).toDouble();
    final currentPerOrderFee = (settings['per_order_fee'] ?? 0.0).toDouble();
    
    String selectedType = currentType;
    final rateController = TextEditingController(text: currentRate.toStringAsFixed(0));
    final feeController = TextEditingController(text: currentPerOrderFee.toStringAsFixed(0));
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Komisyon Ayarları Güncelle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ ÖNEMLİ UYARI',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Komisyon değişikliği SADECE YENİ SİPARİŞLERİ etkiler!\n\n'
                    'Mevcut siparişler eski oranla hesaplanmaya devam eder.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Komisyon Türü:'),
                RadioListTile<String>(
                  title: const Text('Yüzde (%)'),
                  value: 'percentage',
                  groupValue: selectedType,
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Sipariş Başı Sabit Ücret'),
                  value: 'perOrder',
                  groupValue: selectedType,
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                if (selectedType == 'percentage')
                  TextField(
                    controller: rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Komisyon Oranı',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (selectedType == 'perOrder')
                  TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sipariş Başı Ücret',
                      suffixText: '₺',
                      border: OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                // Yeni commission_settings JSONB oluştur
                final newSettings = <String, dynamic>{
                  ...Map<String, dynamic>.from(settings), // Tip güvenli cast
                  'type': selectedType,
                  'commission_rate': selectedType == 'percentage' 
                      ? (double.tryParse(rateController.text) ?? currentRate)
                      : null,
                  'per_order_fee': selectedType == 'perOrder'
                      ? (double.tryParse(feeController.text) ?? currentPerOrderFee)
                      : null,
                };
                
                _updateCommission(merchant['id'], Map<String, dynamic>.from(settings), newSettings);
                Navigator.pop(context);
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}