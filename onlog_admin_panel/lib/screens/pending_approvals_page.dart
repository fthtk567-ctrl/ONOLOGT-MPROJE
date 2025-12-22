import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class PendingApprovalsPage extends StatefulWidget {
  const PendingApprovalsPage({super.key});

  @override
  State<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends State<PendingApprovalsPage> {
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
  }

  Future<void> _loadPendingApprovals() async {
    try {
      final response = await SupabaseService.from('users')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      setState(() {
        _pendingUsers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Bekleyen başvurular yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(String userId, String role) async {
    print('🔵 ONAYLAMA BAŞLADI - User ID: $userId, Role: $role');
    
    try {
      // Önce mevcut user'ı kontrol et
      final currentUser = SupabaseService.client.auth.currentUser;
      print('👤 Current User ID: ${currentUser?.id}');
      print('📧 Current User Email: ${currentUser?.email}');
      
      // JWT token'ı al
      final session = SupabaseService.client.auth.currentSession;
      print('🔑 JWT Token role: ${session?.user.userMetadata?['role']}');
      
      print('📤 Supabase UPDATE sorgusu gönderiliyor...');
      
      final response = await SupabaseService.from('users')
          .update({'status': 'approved', 'is_active': true})
          .eq('id', userId)
          .select(); // Response'u görmek için
      
      print('✅ Supabase yanıtı: $response');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${role == 'merchant' ? 'İşletme' : 'Kurye'} onaylandı!'), backgroundColor: Colors.green),
      );
      
      print('🔄 Listeyi yeniliyorum...');
      _loadPendingApprovals();
    } catch (e, stackTrace) {
      print('❌ ONAYLAMA HATASI: $e');
      print('📋 Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Onaylama hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      await SupabaseService.from('users')
          .update({'status': 'rejected', 'is_active': false})
          .eq('id', userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Başvuru reddedildi'), backgroundColor: Colors.orange),
      );
      _loadPendingApprovals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Reddetme hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏳ Bekleyen Başvurular'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('🎉 Bekleyen başvuru yok!', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];
                    final role = user['role'] ?? 'unknown';
                    final isMerchant = role == 'merchant';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isMerchant ? Colors.orange : Colors.green,
                                  child: Icon(
                                    isMerchant ? Icons.store : Icons.delivery_dining,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMerchant 
                                            ? (user['business_name'] ?? 'İsimsiz İşletme')
                                            : (user['full_name'] ?? 'İsimsiz Kurye'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        isMerchant ? '🏪 İşletme' : '🚴 Kurye',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('📧 Email', user['email'] ?? '-'),
                            _buildInfoRow('📞 Telefon', user['phone'] ?? '-'),
                            if (isMerchant) ...[
                              _buildInfoRow('📍 Adres', user['address'] ?? '-'),
                              _buildInfoRow('🏢 Tür', _getBusinessType(user)),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approveUser(user['id'], role),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Onayla'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _rejectUser(user['id']),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reddet'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// commission_settings içinden business_type bilgisini oku
  String _getBusinessType(Map<String, dynamic> user) {
    try {
      final commissionSettings = user['commission_settings'];
      if (commissionSettings != null && commissionSettings is Map) {
        final businessType = commissionSettings['business_type'];
        if (businessType != null) {
          // İşletme türünü Türkçe'ye çevir
          return _translateBusinessType(businessType.toString());
        }
      }
    } catch (e) {
      print('⚠️ business_type okuma hatası: $e');
    }
    return '-';
  }

  /// İşletme türlerini Türkçe'ye çevir
  String _translateBusinessType(String type) {
    const typeMap = {
      'restaurant': '🍽️ Restoran',
      'cafe': '☕ Kafe',
      'market': '🛒 Market',
      'grocery': '🥗 Manav / Şarküteri',
      'hardware': '🔧 Hırdavat',
      'pharmacy': '💊 Eczane',
      'butcher': '🥩 Kasap',
      'florist': '🌸 Çiçekçi',
      'petshop': '🐾 Pet Shop',
      'industrial': '🏭 Sanayici / Toptancı',
      'other': '📦 Diğer',
    };
    return typeMap[type] ?? type;
  }
}
