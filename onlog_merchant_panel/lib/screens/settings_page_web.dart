import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'account_settings_page_v2.dart';
import 'business_settings_page.dart';
import 'help_center_page.dart';
import 'privacy_policy_page.dart';
import 'about_page.dart';

/// ⚙️ Modern Web Ayarlar Sayfası
class SettingsPageWeb extends StatefulWidget {
  const SettingsPageWeb({super.key});

  @override
  State<SettingsPageWeb> createState() => _SettingsPageWebState();
}

class _SettingsPageWebState extends State<SettingsPageWeb> {
  late Future<MerchantIntegrationStatus> _integrationFuture;

  @override
  void initState() {
    super.initState();
    _integrationFuture = _loadIntegrationStatus();
  }

  Future<MerchantIntegrationStatus> _loadIntegrationStatus() async {
    final fallbackId = Supabase.instance.client.auth.currentUser?.id ?? '-';
    try {
      return await SupabaseMerchantIntegrationService.getStatusForCurrentMerchant();
    } catch (e) {
      debugPrint('Web settings integration status error: $e');
      return MerchantIntegrationStatus.unlinked(merchantId: fallbackId);
    }
  }

  Future<void> _refreshIntegrationStatus() async {
    final future = _loadIntegrationStatus();
    setState(() {
      _integrationFuture = future;
    });
    await future;
  }

  Future<void> _copyMerchantId(String merchantId) async {
    await Clipboard.setData(ClipboardData(text: merchantId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Merchant ID panoya kopyalandı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _statusColor(MerchantIntegrationStatus status) {
    if (!status.isLinked) return Colors.grey;
    return status.isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
  }

  String _statusText(MerchantIntegrationStatus status) {
    if (!status.isLinked) return 'Bağlı Değil';
    return status.isActive ? 'Aktif' : 'Pasif';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                const Row(
                  children: [
                    Icon(Icons.settings, color: Color(0xFF4CAF50), size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Ayarlar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Grid Layout - 2 sütun
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sol Sütun
                    Expanded(
                      child: Column(
                        children: [
                          _buildSettingsCard(
                            context,
                            title: 'Hesap Ayarları',
                            icon: Icons.account_circle,
                            iconColor: const Color(0xFF4CAF50),
                            items: [
                              _SettingsItem(
                                icon: Icons.person_outline,
                                title: 'Profil Ayarları',
                                subtitle: 'Ad, soyad, e-posta değiştir',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AccountSettingsPageV2()),
                                ),
                              ),
                              _SettingsItem(
                                icon: Icons.store_outlined,
                                title: 'İşletme Bilgileri',
                                subtitle: 'Çalışma saatleri, adres, iletişim',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BusinessSettingsPage()),
                                ),
                              ),
                              _SettingsItem(
                                icon: Icons.lock_outline,
                                title: 'Güvenlik',
                                subtitle: 'Şifre değiştir, güvenlik ayarları',
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Şifre değiştirme özelliği yakında eklenecek'),
                                    backgroundColor: Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSettingsCard(
                            context,
                            title: 'Uygulama',
                            icon: Icons.phone_android,
                            iconColor: const Color(0xFF2196F3),
                            items: [
                              _SettingsItem(
                                icon: Icons.notifications_active,
                                title: 'Bildirimler',
                                subtitle: 'Push bildirimleri her zaman aktif',
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Aktif',
                                        style: TextStyle(
                                          color: Color(0xFF4CAF50),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Bildirimler otomatik olarak aktiftir'),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ),
                                ),
                              ),
                              _SettingsItem(
                                icon: Icons.language,
                                title: 'Dil',
                                subtitle: 'Türkçe',
                                trailing: Chip(
                                  label: const Text(
                                    'TR',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.grey[200],
                                  padding: EdgeInsets.zero,
                                ),
                                onTap: null, // Devre dışı
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Sağ Sütun
                    Expanded(
                      child: Column(
                        children: [
                          _buildIntegrationCard(context),
                          const SizedBox(height: 24),
                          _buildSettingsCard(
                            context,
                            title: 'Destek & Yardım',
                            icon: Icons.support_agent,
                            iconColor: const Color(0xFF9C27B0),
                            items: [
                              _SettingsItem(
                                icon: Icons.help_outline,
                                title: 'Yardım Merkezi',
                                subtitle: 'SSS, kullanım kılavuzu',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                                ),
                              ),
                              _SettingsItem(
                                icon: Icons.privacy_tip_outlined,
                                title: 'Gizlilik Politikası',
                                subtitle: 'Veri koruma ve gizlilik',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                                ),
                              ),
                              _SettingsItem(
                                icon: Icons.description_outlined,
                                title: 'Kullanım Şartları',
                                subtitle: 'Hizmet koşulları',
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kullanım şartları sayfası hazırlanıyor'),
                                    backgroundColor: Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSettingsCard(
                            context,
                            title: 'Hakkında',
                            icon: Icons.info,
                            iconColor: const Color(0xFF607D8B),
                            items: [
                              _SettingsItem(
                                icon: Icons.info_outline,
                                title: 'Uygulama Bilgisi',
                                subtitle: 'Versiyon 1.0.0 • ONLOG',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AboutPage()),
                                ),
                              ),
                              _SettingsItem(
                                icon: Icons.rate_review_outlined,
                                title: 'Geri Bildirim',
                                subtitle: 'Önerilerinizi paylaşın',
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📧 Geri bildirimleriniz için: destek@onlog.com.tr'),
                                    backgroundColor: Color(0xFF4CAF50),
                                    duration: Duration(seconds: 3),
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
                const SizedBox(height: 32),
                
                // Çıkış Yap Butonu
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Çıkış Yap'),
                            content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Çıkış Yap'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true && context.mounted) {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Çıkış Yap',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntegrationCard(BuildContext context) {
    return Container(
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
      child: FutureBuilder<MerchantIntegrationStatus>(
        future: _integrationFuture,
        builder: (context, snapshot) {
          final fallbackId = Supabase.instance.client.auth.currentUser?.id ?? '-';
          final status = snapshot.data ?? MerchantIntegrationStatus.unlinked(merchantId: fallbackId);
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.link, color: Color(0xFFFF9800), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Yemek App Entegrasyonu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isLoading ? null : _refreshIntegrationStatus,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Durumu yenile',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Bağlantı durumu yükleniyor...'),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKeyValueRow(
                        label: 'ONLOG Merchant ID',
                        value: status.merchantId,
                        trailing: OutlinedButton.icon(
                          onPressed: status.merchantId == '-' ? null : () => _copyMerchantId(status.merchantId),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Kopyala'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              _statusText(status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: _statusColor(status),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Son güncelleme: ${_formatDate(status.updatedAt ?? status.createdAt)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (status.isLinked) ...[
                        _buildKeyValueRow(
                          label: 'Yemek App Restoran ID',
                          value: status.yemekAppRestaurantId ?? '-',
                        ),
                        if (status.restaurantName != null) ...[
                          const SizedBox(height: 12),
                          _buildKeyValueRow(
                            label: 'Restoran Adı',
                            value: status.restaurantName!,
                          ),
                        ],
                        if (status.isPendingActivation) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Yemek App ekibi entegrasyonu henüz aktifleştirmemiş görünüyor. Lütfen destek ekibimizle iletişime geçin.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Yemek App panelinde "ONLOG Merchant ID" alanına yukarıdaki kodu girerek veri paylaşımını yönetebilirsiniz.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Henüz Yemek App bağlantısı yapılmamış. Yemek App panelindeki "ONLOG Merchant ID" alanına bu ekrandaki kodu yazarak restoranınızı bağlayabilirsiniz.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKeyValueRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_SettingsItem> items,
  }) {
    return Container(
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
          // Kart Başlığı
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Ayar Öğeleri
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.vertical(
                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: item.onTap == null ? Colors.grey[400] : const Color(0xFF4CAF50),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: item.onTap == null ? Colors.grey[400] : const Color(0xFF2C3E50),
                                  ),
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (item.trailing != null)
                            item.trailing!
                          else if (item.onTap != null)
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast) Divider(height: 1, indent: 60, color: Colors.grey[200]),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
