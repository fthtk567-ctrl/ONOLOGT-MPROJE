import 'package:flutter/material.dart';
import '../widgets/delivery_card.dart';
import '../widgets/earnings_summary.dart';
import '../widgets/status_toggle.dart';
import '../../shared/models/delivery_task.dart';
import '../screens/delivery_details_screen.dart';
import '../screens/notifications/notifications_screen.dart';

class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({super.key});

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  bool isOnline = true;
  List<DeliveryTask> deliveries = [];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  void _loadDeliveries() {
    // Normalde bir API'den yüklenecek, şimdilik test verileri kullanıyoruz
    setState(() {
      deliveries = [
        DeliveryTask(
          id: '123456',
          pickupAddress: 'Ataşehir, İstanbul',
          deliveryAddress: 'Kadıköy, İstanbul',
          customerName: 'Ahmet Yılmaz',
          customerPhone: '0532 123 4567',
          status: DeliveryStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          price: 45.0,
        ),
        DeliveryTask(
          id: '123457',
          pickupAddress: 'Şişli, İstanbul',
          deliveryAddress: 'Beşiktaş, İstanbul',
          customerName: 'Ayşe Demir',
          customerPhone: '0533 765 4321',
          status: DeliveryStatus.assigned,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          price: 35.0,
        ),
      ];
    });
  }

  void _toggleOnlineStatus(bool status) {
    setState(() {
      isOnline = status;
    });
    // Normalde bir API'ye bu durum değişikliği bildirilecek
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isOnline ? 'Çevrimiçi oldunuz' : 'Çevrimdışı oldunuz'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewDeliveryDetails(DeliveryTask delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailsScreen(delivery: delivery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONLOG Kurye'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Bildirimler ekranına git
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildHomeScreen(),
    );
  }



  Widget _buildHomeScreen() {
    return Column(
      children: [
        // Online/Offline durum değiştirici
        StatusToggle(
          isOnline: isOnline,
          onToggle: _toggleOnlineStatus,
        ),

        // Günlük kazanç özeti
        EarningsSummary(
          dailyEarning: 350.0,
          deliveryCount: 8,
          totalDistance: 42.5,
        ),

        // Teslimat listesi
        Expanded(
          child: deliveries.isEmpty
              ? const Center(
                  child: Text('Aktif teslimat bulunmuyor'),
                )
              : ListView.builder(
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    return DeliveryCard(
                      delivery: deliveries[index],
                      onTap: () => _viewDeliveryDetails(deliveries[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}