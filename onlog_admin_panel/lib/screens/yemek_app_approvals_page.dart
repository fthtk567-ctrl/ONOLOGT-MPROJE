import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlog_shared/onlog_shared.dart';

/// Yemek App bağlantı isteklerini onaylama sayfası
class YemekAppApprovalsPage extends StatefulWidget {
  const YemekAppApprovalsPage({super.key});

  @override
  State<YemekAppApprovalsPage> createState() => _YemekAppApprovalsPageState();
}

class _YemekAppApprovalsPageState extends State<YemekAppApprovalsPage> {
  bool _showPendingOnly = true;
  List<Map<String, dynamic>>? _cachedMappings;
  bool _isLoading = false;

  Future<List<Map<String, dynamic>>> _loadMappings() async {
    if (_isLoading) return _cachedMappings ?? [];
    
    setState(() => _isLoading = true);
    try {
      final mappings = await SupabaseMerchantIntegrationService.getAllMappings(
        pendingOnly: _showPendingOnly,
      );
      _cachedMappings = mappings;
      return mappings;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refreshMappings() {
    setState(() {
      _cachedMappings = null;
    });
  }

  Future<void> _approveMerchant(String mappingId, String restaurantName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bağlantıyı Onayla'),
        content: Text('$restaurantName için Yemek App entegrasyonunu onaylamak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SupabaseMerchantIntegrationService.approveMerchantMapping(mappingId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $restaurantName bağlantısı onaylandı'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        _refreshMappings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Onaylama başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectMerchant(String mappingId, String restaurantName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bağlantıyı Reddet'),
        content: Text('$restaurantName için Yemek App entegrasyonunu reddetmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SupabaseMerchantIntegrationService.rejectMerchantMapping(mappingId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $restaurantName bağlantısı reddedildi'),
            backgroundColor: Colors.orange,
          ),
        );
        _refreshMappings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Reddetme başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMerchant(String mappingId, String restaurantName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bağlantıyı Sil'),
        content: Text('$restaurantName için Yemek App bağlantısını kalıcı olarak silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SupabaseMerchantIntegrationService.deleteMerchantMapping(mappingId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $restaurantName bağlantısı silindi'),
            backgroundColor: Colors.red[800],
          ),
        );
        _refreshMappings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Silme başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label panoya kopyalandı'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Yemek App Bağlantı Onayları'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMappings,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Bekleyen'),
                        icon: Icon(Icons.pending_actions),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Tümü'),
                        icon: Icon(Icons.list),
                      ),
                    ],
                    selected: {_showPendingOnly},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showPendingOnly = newSelection.first;
                        _cachedMappings = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _cachedMappings == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _loadMappings(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && _cachedMappings == null) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Hata: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _refreshMappings,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tekrar Dene'),
                              ),
                            ],
                          ),
                        );
                      }

                      final mappings = snapshot.data ?? _cachedMappings ?? [];

                if (mappings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showPendingOnly ? Icons.check_circle_outline : Icons.link_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showPendingOnly
                              ? 'Bekleyen bağlantı isteği yok'
                              : 'Hiç bağlantı kaydı yok',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mappings.length,
                  itemBuilder: (context, index) {
                    final mapping = mappings[index];
                    return _buildMappingCard(mapping);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingCard(Map<String, dynamic> mapping) {
    final id = mapping['id'] as String;
    final yemekAppId = mapping['yemek_app_restaurant_id'] as String?;
    final onlogMerchantId = mapping['onlog_merchant_id'] as String?;
    final restaurantName = mapping['restaurant_name'] as String? ?? 'İsimsiz Restoran';
    final isActive = mapping['is_active'] as bool? ?? false;
    final createdAt = DateTime.tryParse(mapping['created_at']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(mapping['updated_at']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant, color: Color(0xFFFF9800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          isActive ? 'Aktif' : 'Onay Bekliyor',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Yemek App Restoran ID',
              yemekAppId ?? '-',
              onCopy: yemekAppId != null ? () => _copyToClipboard(yemekAppId, 'Yemek App ID') : null,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'ONLOG Merchant ID',
              onlogMerchantId ?? '-',
              onCopy: onlogMerchantId != null ? () => _copyToClipboard(onlogMerchantId, 'ONLOG Merchant ID') : null,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Oluşturulma',
              createdAt != null ? _formatDate(createdAt) : '-',
            ),
            if (updatedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Son Güncelleme',
                _formatDate(updatedAt),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                if (!isActive) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveMerchant(id, restaurantName),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (isActive) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectMerchant(id, restaurantName),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Pasif Et'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteMerchant(id, restaurantName),
                    icon: const Icon(Icons.delete),
                    label: const Text('Sil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onCopy}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: onCopy,
                  tooltip: 'Kopyala',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hour:$minute';
  }
}
