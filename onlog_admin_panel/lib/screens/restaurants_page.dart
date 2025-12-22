import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 İşletmeler'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _merchants.isEmpty
              ? const Center(child: Text('Henüz işletme yok'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _merchants.length,
                  itemBuilder: (context, index) {
                    final merchant = _merchants[index];
                    final isActive = merchant['is_active'] == true;
                    final status = merchant['status'] ?? 'pending';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.orange : Colors.grey,
                          child: const Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(merchant['business_name'] ?? merchant['full_name'] ?? 'İsimsiz İşletme'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(merchant['email'] ?? ''),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'approved' ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status == 'approved' ? 'Onaylı' : 'Bekliyor',
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isActive ? '🟢 Aktif' : '🔴 Pasif',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('📧 Email', merchant['email'] ?? '-'),
                                _buildDetailRow('📱 Telefon', merchant['business_phone'] ?? merchant['phone'] ?? '-'),
                                _buildDetailRow('📍 Adres', merchant['business_address'] ?? merchant['address'] ?? '-'),
                                _buildDetailRow('🏙️ Şehir', merchant['city'] ?? '-'),
                                _buildDetailRow('📊 Durum', status == 'approved' ? 'Onaylı' : 'Bekliyor'),
                                _buildDetailRow('⚡ Aktiflik', isActive ? 'Aktif' : 'Pasif'),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _toggleActive(merchant['id'], !isActive),
                                        icon: Icon(isActive ? Icons.block : Icons.check_circle),
                                        label: Text(isActive ? 'Pasif Yap' : 'Aktif Yap'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isActive ? Colors.red : Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: status == 'approved' 
                                            ? null 
                                            : () => _approveUser(merchant['id']),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Onayla'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _toggleActive(String userId, bool newActiveStatus) async {
    try {
      await SupabaseService.from('users')
          .update({'is_active': newActiveStatus})
          .eq('id', userId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newActiveStatus ? '✅ Kullanıcı aktif edildi' : '❌ Kullanıcı pasif edildi'),
          backgroundColor: newActiveStatus ? Colors.green : Colors.orange,
        ),
      );
      
      _loadMerchants(); // Refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approveUser(String userId) async {
    try {
      await SupabaseService.from('users')
          .update({'status': 'approved', 'is_active': true})
          .eq('id', userId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kullanıcı onaylandı ve aktif edildi'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadMerchants(); // Refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
