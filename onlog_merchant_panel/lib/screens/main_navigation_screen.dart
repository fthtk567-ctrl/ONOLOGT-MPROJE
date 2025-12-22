import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'merchant_home_page_v2.dart';
import 'merchant_dashboard_web.dart';
import 'account_settings_page_v2.dart';
import 'business_settings_page.dart';
import 'orders_page.dart';
import 'orders_page_web.dart';
import 'reports_page.dart';
import 'live_map_page.dart';
import 'live_map_page_web.dart';
import 'payments_page.dart';
import 'payments_page_web.dart';
import 'delivery_problems_page.dart';
import 'settings_page_web.dart';
import 'help_center_page.dart';
import 'privacy_policy_page.dart';
import 'about_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;
  String? _restaurantId;
  String? _restaurantName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('🔍 _loadUserData başladı');
      final user = Supabase.instance.client.auth.currentUser;
      print('👤 Current user: ${user?.email}');
      
      if (user == null) {
        print('❌ Kullanıcı null - login\'e yönlendiriliyor');
        // Kullanıcı yoksa login'e yönlendir
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      print('📥 Supabase\'dan kullanıcı verisi çekiliyor: ${user.id}');
      final userResponse = await SupabaseService.from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      print('📄 userResponse: $userResponse');
      if (userResponse == null) {
        throw Exception('Kullanıcı verisi bulunamadı');
      }

      final userData = userResponse;
      print('📊 userData: $userData');
      
      // RestaurantId ayrı bir field olarak aranmıyor artık - user'ın kendi ID'si kullanılıyor
      final restaurantId = user.id;  // Kullanıcının kendi ID'si
      final restaurantName = userData['business_name'] as String? ?? 
                            userData['owner_name'] as String? ?? 
                            'İşletme';
      
      print('🏪 restaurantId: $restaurantId');
      print('🏪 restaurantName: $restaurantName');

      if (mounted) {
        setState(() {
          _restaurantId = restaurantId;
          _restaurantName = restaurantName;
          _isLoading = false;
        });
        print('✅ State güncellendi - restaurantId: $_restaurantId, restaurantName: $_restaurantName');
      }
    } catch (e, stackTrace) {
      print('❌ Kullanıcı verisi yüklenirken hata: $e');
      print('📚 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Widget> get _pages {
    // 🖥️ Web için her zaman yeni dashboard
    final bool useWebUI = kIsWeb;
    
    return [
      // Dashboard
      useWebUI
          ? MerchantDashboardWeb(
              restaurantId: _restaurantId ?? 'demo_restaurant',
              restaurantName: _restaurantName ?? 'Demo İşletme',
            )
          : MerchantHomePageV2(
              restaurantId: _restaurantId ?? 'demo_restaurant',
              restaurantName: _restaurantName ?? 'Demo İşletme',
            ),
      // Siparişler
      useWebUI ? const OrdersPageWeb() : const OrdersPage(),
      // Canlı harita
      useWebUI ? const LiveMapPageWeb() : const LiveMapPage(),
      // Ödemeler
      useWebUI ? const PaymentsPageWeb() : const PaymentsPage(),
      DeliveryProblemsPage(merchantId: _restaurantId ?? 'demo_restaurant'), // Sorunlar
      const ReportsPage(),
      // Ayarlar
      useWebUI ? const SettingsPageWeb() : const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 🖥️ WEB/DESKTOP: Sidebar ile profesyonel layout
    if (kIsWeb || MediaQuery.of(context).size.width > 900) {
      return _buildWebLayout();
    }

    // 📱 MOBILE: Bottom navigation ile mevcut tasarım
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Siparişler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Canlı Harita',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Ödemeler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              activeIcon: Icon(Icons.report_problem),
              label: 'Sorunlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Raporlar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }

  // 🖥️ WEB/DESKTOP LAYOUT
  Widget _buildWebLayout() {
    return Scaffold(
      body: Row(
        children: [
          // 📋 SIDEBAR
          _buildSidebar(),
          
          // 📄 MAIN CONTENT
          Expanded(
            child: _pages[currentIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF1A1F36),
      child: Column(
        children: [
          // 🏢 Logo & Restaurant Name
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _restaurantName ?? 'ONLOG',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const Divider(color: Color(0xFF2A3149), height: 1),
          
          // 📱 Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildSidebarItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Siparişler',
                  index: 1,
                ),
                _buildSidebarItem(
                  icon: Icons.map_outlined,
                  title: 'Canlı Harita',
                  index: 2,
                ),
                _buildSidebarItem(
                  icon: Icons.payment_outlined,
                  title: 'Ödemeler',
                  index: 3,
                ),
                _buildSidebarItem(
                  icon: Icons.warning_amber_outlined,
                  title: 'Sorunlar',
                  index: 4,
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_outlined,
                  title: 'Raporlar',
                  index: 5,
                ),
                
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Color(0xFF2A3149)),
                ),
                const SizedBox(height: 8),
                
                _buildSidebarItem(
                  icon: Icons.settings_outlined,
                  title: 'Ayarlar',
                  index: 6,
                ),
              ],
            ),
          ),
          
          // 👤 User Profile at Bottom
          const Divider(color: Color(0xFF2A3149), height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2A3149),
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _restaurantName ?? 'İşletme',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Esnaf Paneli',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  tooltip: 'Çıkış Yap',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[400],
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => setState(() => currentIndex = index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// ============================================================================
// PLACEHOLDER PAGES - Sonra dolduracağız
// ============================================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
      debugPrint('Merchant integration status error: $e');
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
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context,
            title: 'Hesap',
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: 'Profil Ayarları',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountSettingsPageV2()),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.store_outlined,
                title: 'İşletme Bilgileri',
                subtitle: 'Çalışma saatleri, adres, iletişim',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessSettingsPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildIntegrationSection(context),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            title: 'Uygulama',
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                subtitle: 'Push bildirimleri her zaman aktif',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Bildirimler otomatik olarak aktiftir'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            title: 'Destek',
            items: [
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'Yardım Merkezi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'Hakkında',
                subtitle: 'Versiyon 1.0.0',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış Yap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Platform Bağlantıları',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        FutureBuilder<MerchantIntegrationStatus>(
          future: _integrationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Yemek App bağlantısı kontrol ediliyor...'),
                    ],
                  ),
                ),
              );
            }

            final fallbackId = Supabase.instance.client.auth.currentUser?.id ?? '-';
            final status = snapshot.data ??
                MerchantIntegrationStatus.unlinked(merchantId: fallbackId);

            return _buildIntegrationCard(status);
          },
        ),
      ],
    );
  }

  Widget _buildIntegrationCard(MerchantIntegrationStatus status) {
    final merchantId = status.merchantId;
    final statusColor = _statusColor(status);
    final statusText = _statusText(status);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link, color: Color(0xFFFF9800)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Yemek App Entegrasyonu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _refreshIntegrationStatus,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Durumu yenile',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildIntegrationRow(
              label: 'ONLOG Merchant ID',
              value: merchantId,
              trailing: OutlinedButton.icon(
                onPressed: merchantId == '-' ? null : () => _copyMerchantId(merchantId),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Kopyala'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: statusColor,
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
              _buildIntegrationRow(
                label: 'Yemek App Restoran ID',
                value: status.yemekAppRestaurantId ?? '-',
              ),
              if (status.restaurantName != null) ...[
                const SizedBox(height: 8),
                _buildIntegrationRow(
                  label: 'Restoran Adı',
                  value: status.restaurantName!,
                ),
              ],
              if (status.isPendingActivation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Yemek App ekibi entegrasyonu henüz aktifleştirmemiş görünüyor. Lütfen ekibimizle iletişime geçin.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Henüz Yemek App bağlantısı kurulmadı. Yemek App panelinde "ONLOG Merchant ID" alanına yukarıdaki kodu girerek entegrasyonu tamamlayabilirsiniz.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationRow({
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

  Widget _buildSettingsSection(BuildContext context, {required String title, required List<_SettingsItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: items.map((item) {
              final isLast = item == items.last;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: const Color(0xFF4CAF50)),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                    onTap: item.onTap,
                  ),
                  if (!isLast) Divider(height: 1, indent: 56, color: Colors.grey[200]),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
}

// NOT: Web/Desktop için sidebar özelliği ileride eklenecek.
// Şimdilik web'de sadece dashboard görünümü değişiyor (MerchantDashboardWeb).


