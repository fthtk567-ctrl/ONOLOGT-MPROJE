import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import '../services/notification_service.dart';
import '../services/trendyol_api_service.dart';
import 'dart:math';

/// Mock Sipariş Oluşturucu - Canlı Test İçin
class MockOrderGenerator {
  static final _random = Random();
  
  static final List<String> _customerNames = [
    'Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya', 'Fatma Çelik',
    'Ali Öztürk', 'Zeynep Aydın', 'Mustafa Arslan', 'Elif Şahin',
  ];
  
  // 🗺️ Gerçek İstanbul Koordinatları
  static final List<Map<String, dynamic>> _addressesWithCoords = [
    {
      'address': 'Kadıköy Mah. Bahariye Cad. No:45 D:3',
      'district': 'Kadıköy',
      'lat': 40.9908,
      'lng': 29.0251,
    },
    {
      'address': 'Beşiktaş Mah. Barbaros Bulvarı No:120 D:8',
      'district': 'Beşiktaş',
      'lat': 41.0425,
      'lng': 29.0089,
    },
    {
      'address': 'Şişli Mah. Nişantaşı Cad. No:67 D:12',
      'district': 'Şişli',
      'lat': 41.0490,
      'lng': 28.9934,
    },
    {
      'address': 'Bakırköy Mah. İncirli Cad. No:89 D:5',
      'district': 'Bakırköy',
      'lat': 40.9829,
      'lng': 28.8667,
    },
    {
      'address': 'Üsküdar Mah. Çamlıca Sok. No:34 D:7',
      'district': 'Üsküdar',
      'lat': 41.0220,
      'lng': 29.0213,
    },
    {
      'address': 'Sarıyer Mah. İstinye Cad. No:22 D:4',
      'district': 'Sarıyer',
      'lat': 41.1086,
      'lng': 29.0464,
    },
    {
      'address': 'Fatih Mah. Vatan Cad. No:156 D:9',
      'district': 'Fatih',
      'lat': 41.0128,
      'lng': 28.9496,
    },
    {
      'address': 'Maltepe Mah. Bağdat Cad. No:234 D:6',
      'district': 'Maltepe',
      'lat': 40.9333,
      'lng': 29.1333,
    },
  ];
  
  static final List<String> _foodItems = [
    'Köfte', 'Lahmacun', 'Pide', 'Pizza', 'Burger',
    'Döner', 'Tavuk Şiş', 'Adana Kebap', 'İskender',
    'Makarna', 'Salata', 'Çorba', 'Pilav',
  ];
  
  static final List<OrderPlatform> _platforms = [
    OrderPlatform.trendyol,
    OrderPlatform.yemeksepeti,
    OrderPlatform.getir,
    OrderPlatform.manuel,
  ];
  
  /// Rastgele sipariş oluştur
  static Order generateRandomOrder() {
    final platform = _platforms[_random.nextInt(_platforms.length)];
    final customerName = _customerNames[_random.nextInt(_customerNames.length)];
    
    // 🗺️ Gerçek koordinatlı adres seç
    final addressData = _addressesWithCoords[_random.nextInt(_addressesWithCoords.length)];
    
    // Rastgele 1-4 ürün ekle
    final itemCount = 1 + _random.nextInt(4);
    final items = List.generate(itemCount, (index) {
      final itemName = _foodItems[_random.nextInt(_foodItems.length)];
      final quantity = 1 + _random.nextInt(3);
      final price = 50.0 + _random.nextDouble() * 150.0;
      
      return OrderItem(
        name: itemName,
        quantity: quantity,
        price: price,
      );
    });
    
    final totalAmount = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    
    return Order(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
      platform: platform,
      customer: Customer(
        name: customerName,
        phone: '+90 5${_random.nextInt(10)}${_random.nextInt(10)} ${_random.nextInt(900) + 100} ${_random.nextInt(90) + 10} ${_random.nextInt(90) + 10}',
        address: Address(
          fullAddress: addressData['address'] as String,
          district: addressData['district'] as String,
          city: 'İstanbul',
          latitude: addressData['lat'] as double,  // ✅ Gerçek koordinat
          longitude: addressData['lng'] as double, // ✅ Gerçek koordinat
        ),
      ),
      items: items,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      orderTime: DateTime.now(),
      type: OrderType.food,
      priority: OrderPriority.normal,
    );
  }
  
  /// Test bildirimi göster
  static Future<void> showNewOrderNotification(BuildContext context, Order order) async {
    // Sesli uyarı çal
    await NotificationService.playNewOrderSound();
    
    // Görsel bildirim
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🔔 YENİ SİPARİŞ!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.customer.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} ürün • ₺${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '📍 ${order.customer.address}',
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'GÖRÜNTÜLE',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Sipariş detayına git
          },
        ),
      ),
    );
  }
  
  /// Dialog ile mock sipariş oluşturma
  static void showMockOrderDialog(BuildContext context, {
    required Function(Order) onOrderCreated,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16), // OVERFLOW FIX: küçük padding
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // 8 → 6 (overflow fix)
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.science, color: Color(0xFF4CAF50), size: 20), // 24 → 20
            ),
            const SizedBox(width: 8), // 12 → 8 (overflow fix)
            const Flexible( // OVERFLOW FIX: Expanded → Flexible
              child: Text(
                'Test Siparişi Oluştur',
                style: TextStyle(fontSize: 16), // font boyutu ekle
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hangi türde test siparişi oluşturulsun?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), // 15 → 14 (overflow fix)
              ),
              const SizedBox(height: 16), // 20 → 16 (overflow fix)
              
              // Rastgele Mock Sipariş
              _buildOrderTypeCard(
                context,
                icon: Icons.shuffle,
                iconColor: const Color(0xFF4CAF50),
                title: 'Rastgele Sipariş',
                subtitle: 'Mock veri ile anlık sipariş',
                badge: 'HIZLI',
                badgeColor: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  final order = generateRandomOrder();
                  onOrderCreated(order);
                  showNewOrderNotification(context, order);
                },
              ),
              const SizedBox(height: 10), // 12 → 10 (overflow fix)
              
              // Trendyol Test Siparişi
              _buildOrderTypeCard(
                context,
                icon: Icons.store,
                iconColor: const Color(0xFFFF6000),
                title: 'Trendyol Test Siparişi',
                subtitle: 'Gerçek API ile test (STAGE)',
                badge: 'GERÇEK',
                badgeColor: Colors.orange,
                onTap: () async {
                  // Ana dialog'u kapat
                  Navigator.pop(context);
                  
                  // Test işlemini başlat
                  _createTrendyolTestOrder(context);
                },
              ),
              
              const SizedBox(height: 12), // 16 → 12 (overflow fix)
              Container(
                padding: const EdgeInsets.all(10), // 12 → 10 (overflow fix)
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 18), // 20 → 18
                    const SizedBox(width: 10), // 12 → 10 (overflow fix)
                    const Expanded(
                      child: Text(
                        'Sesli uyarı çalacak ve bildirim gösterilecek',
                        style: TextStyle(fontSize: 12), // 13 → 12 (overflow fix)
                      ),
                    ),
                  ],
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
        ],
      ),
    );
  }

  /// Sipariş türü kartı
  static Widget _buildOrderTypeCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12), // 16 → 12 (overflow fix)
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), // 12 → 10 (overflow fix)
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24), // 28 → 24 (overflow fix)
            ),
            const SizedBox(width: 12), // 16 → 12 (overflow fix)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible( // OVERFLOW FIX: title'a Flexible
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14, // 15 → 14 (overflow fix)
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6), // 8 → 6 (overflow fix)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 8 → 6
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9, // 10 → 9 (overflow fix)
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3), // 4 → 3 (overflow fix)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12, // 13 → 12 (overflow fix)
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20), // 24 → 20
          ],
        ),
      ),
    );
  }

  /// Trendyol test siparişi oluştur (ayrı fonksiyon - context sorununu çözmek için)
  static Future<void> _createTrendyolTestOrder(BuildContext context) async {
    // Loading mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Trendyol test siparişi oluşturuluyor...'),
          ],
        ),
        duration: Duration(seconds: 30), // Uzun süre açık kalsın
        backgroundColor: Colors.blue,
      ),
    );
    
    try {
      // Test credentials ayarla
      TrendyolApiService().setTestCredentials();
      
      // Test siparişi oluştur
      final orderNumber = await TrendyolApiService().createSimpleTestOrder();
      
      // Loading snackbar'ı kapat
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      // Kısa bekle - SnackBar değişimi için
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;
      
      if (orderNumber != null) {
        debugPrint('✅ Order created: $orderNumber');
        // Web platformunda mock order mı kontrol et
        final isMockOrder = orderNumber.startsWith('MOCK-');
        
        // Başarılı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isMockOrder ? Icons.warning : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMockOrder 
                          ? 'Trendyol MOCK Test Siparişi'
                          : 'Trendyol Test Siparişi Oluşturuldu!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isMockOrder
                          ? 'Sipariş No: $orderNumber\n⚠️ Web - CORS nedeniyle mock\n📱 Gerçek API testi için mobil kullanın'
                          : 'Sipariş No: $orderNumber\n~30 saniye içinde polling servisi çekecek',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: isMockOrder 
              ? Colors.orange 
              : const Color(0xFF4CAF50),
            duration: Duration(seconds: isMockOrder ? 8 : 6),
          ),
        );
      } else {
        debugPrint('❌ Order is null - showing error');
        // Hata mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Test siparişi oluşturulamadı! API hatası (500)'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Exception caught: $e');
      // Loading snackbar'ı kapat
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      // Kısa bekle
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;
      
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

