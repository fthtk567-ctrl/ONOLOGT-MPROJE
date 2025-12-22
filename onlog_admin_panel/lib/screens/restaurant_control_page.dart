import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class RestaurantControlPage extends StatefulWidget {
  const RestaurantControlPage({super.key});

  @override
  State<RestaurantControlPage> createState() => _RestaurantControlPageState();
}

class _RestaurantControlPageState extends State<RestaurantControlPage> {
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
          .order('created_at', ascending: false);
      
      setState(() {
        _merchants = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ İşletme yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMerchantStatus(String merchantId, bool currentStatus) async {
    try {
      await SupabaseService.from('users')
          .update({'is_active': !currentStatus})
          .eq('id', merchantId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? '✅ İşletme aktif edildi' : '❌ İşletme pasif edildi'),
          backgroundColor: !currentStatus ? Colors.green : Colors.orange,
        ),
      );
      _loadMerchants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎛️ İşletme Kontrol'),
        backgroundColor: Colors.orange,
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
                    final isActive = merchant['is_active'] == true;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.orange : Colors.grey,
                          child: const Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(merchant['business_name'] ?? 'İsimsiz'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(merchant['email'] ?? ''),
                            Text('Adres: ${merchant['business_address'] ?? '-'}'),
                            Text('Telefon: ${merchant['phone'] ?? '-'}'),
                          ],
                        ),
                        trailing: Switch(
                          value: isActive,
                          onChanged: (value) => _toggleMerchantStatus(merchant['id'], isActive),
                          activeThumbColor: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
