import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'utils/theme_provider.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart'; // ESKİ ÇALIŞAN DASHBOARD
import 'screens/couriers_page.dart';
import 'screens/orders_page.dart';
import 'screens/live_tracking_page.dart';
import 'screens/courier_control_page.dart';
import 'screens/restaurant_control_page.dart';
import 'screens/settings_page.dart';
import 'screens/financial_management_page.dart';
import 'screens/courier_earnings_management_page.dart';
import 'screens/merchant_commission_management_page.dart';
import 'screens/system_settings_page.dart';
import 'screens/pending_approvals_page.dart';
import 'screens/fix_old_data_page.dart';
import 'screens/delivery_requests_page.dart';
import 'screens/legal_management_page.dart';
import 'screens/yemek_app_approvals_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase'i initialize et
  await SupabaseService.initialize();
  debugPrint('✅ Admin Panel - Supabase başlatıldı');
  
  runApp(const ProviderScope(child: OnlogAdminApp()));
}

class OnlogAdminApp extends ConsumerWidget {
  const OnlogAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'ONLOG Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: OnlogTheme.lightTheme,
      darkTheme: OnlogTheme.darkTheme,
      themeMode: themeMode,
      home: SupabaseService.isLoggedIn
          ? const AdminLayout()
          : const LoginPage(),
    );
  }
}

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(), // ESKİ ÇALIŞAN DASHBOARD
    const PendingApprovalsPage(), // YENİ: Bekleyen Başvurular
    const FixOldDataPage(), // YENİ: Eski Verileri Düzelt
    const YemekAppApprovalsPage(), // YENİ: Yemek App Entegrasyon Onayları
    // KALDIRILDI: const RestaurantsPage(), - İşletme Kontrol sayfası var
    const CouriersPage(),
    const OrdersPage(),
    const DeliveryRequestsPage(), // YENİ: Teslimat İstekleri
    const LiveTrackingPage(),
    const CourierControlPage(),
    const RestaurantControlPage(),
    const LegalManagementPage(), // YENİ: Yasal Belge Yönetimi
    const FinancialManagementPage(),
    const CourierEarningsManagementPage(), // YENİ: Kurye Kazanç Yönetimi
    const MerchantCommissionManagementPage(), // YENİ: Restoran Komisyon Yönetimi
    const SystemSettingsPage(), // YENİ: Sistem Ayarları
    const SettingsPage(),
  ];

  final List<NavigationRailDestination> _destinations = [
    const NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.pending_actions_outlined),
      selectedIcon: Icon(Icons.pending_actions),
      label: Text('⏳ Bekleyen Başvurular'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.build_outlined),
      selectedIcon: Icon(Icons.build),
      label: Text('🔧 Veri Düzelt'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.link_outlined),
      selectedIcon: Icon(Icons.link),
      label: Text('🍴 Yemek App Bağlantıları'),
    ),
    // KALDIRILDI: Restoranlar menüsü - İşletme Kontrol sayfası kullanılıyor
    const NavigationRailDestination(
      icon: Icon(Icons.delivery_dining_outlined),
      selectedIcon: Icon(Icons.delivery_dining),
      label: Text('Kuryeler'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag),
      label: Text('Siparişler'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: Text('🚴 Teslimat İstekleri'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.radar),
      selectedIcon: Icon(Icons.radar),
      label: Text('📡 Canlı İzleme'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.settings_input_component),
      selectedIcon: Icon(Icons.settings_input_component),
      label: Text('🎛️ Kurye Kontrol'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.store_mall_directory),
      selectedIcon: Icon(Icons.store_mall_directory),
      label: Text('İşletme Kontrol'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.gavel_outlined),
      selectedIcon: Icon(Icons.gavel),
      label: Text('⚖️ Yasal Belgeler'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('💰 Finansal Yönetim'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.payments_outlined),
      selectedIcon: Icon(Icons.payments),
      label: Text('💵 Kurye Kazançları'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.percent_outlined),
      selectedIcon: Icon(Icons.percent),
      label: Text('📊 Komisyon Yönetimi'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings),
      label: Text('⚙️ Sistem Ayarları'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Ayarlar'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sol Menü (Navigation Rail)
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'ON',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ONLOG',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await SupabaseService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                ),
              ),
            ),
            destinations: _destinations,
            backgroundColor: Colors.grey[50],
          ),
          
          const VerticalDivider(thickness: 1, width: 1),
          
          // Ana İçerik Alanı
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
