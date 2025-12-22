import 'package:flutter/material.dart';

/// Bildirim Merkezi - Tüm bildirimlerin gösterildiği sayfa
class NotificationsCenterPage extends StatefulWidget {
  const NotificationsCenterPage({super.key});

  @override
  State<NotificationsCenterPage> createState() => _NotificationsCenterPageState();
}

class _NotificationsCenterPageState extends State<NotificationsCenterPage> {
  String _selectedFilter = 'Tümü';
  
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'new_order',
      'title': 'Yeni Sipariş',
      'message': '#1234 numaralı sipariş oluşturuldu',
      'time': '2 dk önce',
      'isRead': false,
      'icon': Icons.shopping_bag,
      'color': Colors.green,
    },
    {
      'id': '2',
      'type': 'courier_assigned',
      'title': 'Kurye Atandı',
      'message': 'Ahmet Yılmaz #1230 numaralı siparişi teslim alacak',
      'time': '5 dk önce',
      'isRead': false,
      'icon': Icons.delivery_dining,
      'color': Colors.blue,
    },
    {
      'id': '3',
      'type': 'order_delivered',
      'title': 'Sipariş Teslim Edildi',
      'message': '#1228 numaralı sipariş başarıyla teslim edildi',
      'time': '15 dk önce',
      'isRead': true,
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'id': '4',
      'type': 'payment_received',
      'title': 'Ödeme Alındı',
      'message': '₺250,00 tutarında ödeme hesabınıza yatırıldı',
      'time': '1 saat önce',
      'isRead': true,
      'icon': Icons.payment,
      'color': Colors.purple,
    },
    {
      'id': '5',
      'type': 'courier_delayed',
      'title': 'Gecikme Uyarısı',
      'message': '#1225 numaralı sipariş gecikmede',
      'time': '2 saat önce',
      'isRead': true,
      'icon': Icons.warning_amber,
      'color': Colors.orange,
    },
    {
      'id': '6',
      'type': 'system',
      'title': 'Sistem Güncellemesi',
      'message': 'Yeni özellikler eklendi! İnceleyin.',
      'time': '1 gün önce',
      'isRead': true,
      'icon': Icons.system_update,
      'color': Colors.blueGrey,
    },
    {
      'id': '7',
      'type': 'new_order',
      'title': 'Yeni Sipariş',
      'message': '#1229 numaralı sipariş oluşturuldu',
      'time': '1 gün önce',
      'isRead': true,
      'icon': Icons.shopping_bag,
      'color': Colors.green,
    },
    {
      'id': '8',
      'type': 'order_cancelled',
      'title': 'Sipariş İptal',
      'message': '#1227 numaralı sipariş müşteri tarafından iptal edildi',
      'time': '2 gün önce',
      'isRead': true,
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'Tümü') {
      return _notifications;
    } else if (_selectedFilter == 'Okunmamış') {
      return _notifications.where((n) => !n['isRead']).toList();
    } else if (_selectedFilter == 'Sipariş') {
      return _notifications.where((n) => n['type'].toString().contains('order')).toList();
    } else if (_selectedFilter == 'Kurye') {
      return _notifications.where((n) => n['type'].toString().contains('courier')).toList();
    }
    return _notifications;
  }

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF4CAF50),
        foregroundColor: isDark ? Colors.white : Colors.white,
        title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
              label: const Text('Tümünü Okundu İşaretle', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAll,
            tooltip: 'Tümünü Temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          // İstatistikler
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam',
                    _notifications.length.toString(),
                    Icons.notifications,
                    Colors.blue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Okunmamış',
                    _unreadCount.toString(),
                    Icons.markunread,
                    Colors.orange,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Bugün',
                    _notifications.where((n) => n['time'].toString().contains('dk') || n['time'].toString().contains('saat')).length.toString(),
                    Icons.today,
                    Colors.green,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          
          // Filtreler
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tümü', Icons.all_inbox),
                  const SizedBox(width: 8),
                  _buildFilterChip('Okunmamış', Icons.markunread),
                  const SizedBox(width: 8),
                  _buildFilterChip('Sipariş', Icons.shopping_bag),
                  const SizedBox(width: 8),
                  _buildFilterChip('Kurye', Icons.delivery_dining),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Bildirimler Listesi
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return _buildNotificationCard(notification, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF4CAF50)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark) {
    final isRead = notification['isRead'] as bool;
    
    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification['title']} silindi'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Geri Al',
              onPressed: () {
                setState(() {
                  _notifications.insert(_notifications.indexOf(notification), notification);
                });
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark 
              ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF2C2C2C))
              : (isRead ? Colors.white : const Color(0xFFF0F9F1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                : const Color(0xFF4CAF50).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (notification['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification['icon'] as IconData,
              color: notification['color'] as Color,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification['title'],
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                notification['message'],
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification['time'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.grey[600]),
            onSelected: (value) {
              if (value == 'mark_read') {
                setState(() {
                  notification['isRead'] = !notification['isRead'];
                });
              } else if (value == 'delete') {
                setState(() {
                  _notifications.remove(notification);
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(isRead ? Icons.markunread : Icons.done, size: 20),
                    const SizedBox(width: 12),
                    Text(isRead ? 'Okunmadı İşaretle' : 'Okundu İşaretle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              notification['isRead'] = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Bildirim Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz hiç bildiriminiz bulunmuyor',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tüm bildirimler okundu olarak işaretlendi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Bildirimleri Temizle'),
        content: const Text('Tüm bildirimler silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _notifications.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm bildirimler silindi'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
