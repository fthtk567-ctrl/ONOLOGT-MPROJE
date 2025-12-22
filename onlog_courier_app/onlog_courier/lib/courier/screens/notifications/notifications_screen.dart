import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Demo bildirimler
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Yeni Teslimat Atandı',
      message: 'Şişli-Beşiktaş güzergahında yeni bir teslimat göreviniz var.',
      time: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      type: NotificationType.delivery,
    ),
    NotificationItem(
      id: '2',
      title: 'Ödeme Bildirimi',
      message: '350₺ tutarındaki haftalık ödemeniz hesabınıza aktarıldı.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.payment,
    ),
    NotificationItem(
      id: '3',
      title: 'Teslimat Hatırlatması',
      message: 'Teslimatı bekleyen 2 göreviniz bulunuyor.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.reminder,
    ),
    NotificationItem(
      id: '4',
      title: 'Sistem Bakımı',
      message: 'Bu gece 02:00-04:00 arası sistem bakımı nedeniyle uygulama geçici olarak hizmet veremeyecektir.',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.system,
    ),
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((notification) => notification.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimleri Temizle'),
        content: const Text('Tüm bildirimler silinecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: 'Tümünü Temizle',
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bildirim bulunmuyor',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      _notifications.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bildirim silindi'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: _getNotificationIcon(notification.type),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(notification.time),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      _markAsRead(notification.id);
                      // Bildirim detayını göster veya ilgili sayfaya yönlendir
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  _getNotificationIcon(notification.type),
                                  const SizedBox(width: 8),
                                  Text(
                                    notification.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(notification.message),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(notification.time),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // İlgili sayfaya yönlendir
                                  // Örneğin, teslimat bildirimi ise teslimat detaylarına git
                                },
                                child: const Text('İlgili Sayfaya Git'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    trailing: notification.isRead
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.delivery:
        return CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.delivery_dining, color: Colors.blue),
        );
      case NotificationType.payment:
        return CircleAvatar(
          backgroundColor: Colors.green[100],
          child: const Icon(Icons.attach_money, color: Colors.green),
        );
      case NotificationType.reminder:
        return CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: const Icon(Icons.alarm, color: Colors.orange),
        );
      case NotificationType.system:
        return CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.info, color: Colors.grey),
        );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      // Bir haftadan fazla ise tarih göster
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 0) {
      // Günler içinde ise kaç gün önce olduğunu göster
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      // Saatler içinde ise kaç saat önce olduğunu göster
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      // Dakikalar içinde ise kaç dakika önce olduğunu göster
      return '${difference.inMinutes} dakika önce';
    } else {
      // Az önce
      return 'Az önce';
    }
  }
}

enum NotificationType { delivery, payment, reminder, system }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? time,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}