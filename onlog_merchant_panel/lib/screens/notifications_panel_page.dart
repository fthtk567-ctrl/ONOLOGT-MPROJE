import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';

/// Bildirimler Paneli - Teslimat durumu güncellemeleri
class NotificationsPanelPage extends StatefulWidget {
  final String merchantId;

  const NotificationsPanelPage({
    super.key,
    required this.merchantId,
  });

  @override
  State<NotificationsPanelPage> createState() => _NotificationsPanelPageState();
}

class _NotificationsPanelPageState extends State<NotificationsPanelPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  Set<String> _readNotifications = {}; // Okunmuş bildirimler

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    _loadReadNotifications();
    _loadNotifications();
  }

  /// Okunmuş bildirimleri yükle (SharedPreferences'tan)
  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('read_notifications_${widget.merchantId}') ?? [];
    setState(() {
      _readNotifications = readList.toSet();
    });
  }

  /// Bildirim okundu olarak işaretle
  Future<void> _markAsRead(String notificationId) async {
    _readNotifications.add(notificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_notifications_${widget.merchantId}', _readNotifications.toList());
    setState(() {});
  }

  /// Tümünü okundu işaretle
  Future<void> _markAllAsRead() async {
    for (var notification in _notifications) {
      final id = notification['id'];
      if (id != null) {
        _readNotifications.add(id.toString());
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_notifications_${widget.merchantId}', _readNotifications.toList());
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tüm bildirimler okundu olarak işaretlendi'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadNotifications() async {
    try {
      // Son 48 saat içindeki teslimatlari çek
      final twoDaysAgo = DateTime.now().subtract(const Duration(hours: 48)).toIso8601String();
      
      final deliveries = await SupabaseService.client
          .from('delivery_requests')
          .select('''
            *,
            courier:users!courier_id(owner_name, full_name)
          ''')
          .eq('merchant_id', widget.merchantId)
          .gte('created_at', twoDaysAgo) // Son 48 saat içinde oluşturulanlar
          .order('created_at', ascending: false) // En yeni önce
          .limit(20); // Maksimum 20 teslimat

      setState(() {
        _notifications = deliveries;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Bildirim yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getNotificationTitle(String status) {
    switch (status) {
      case 'PENDING':
        return '📦 Yeni Teslimat Talebi Oluşturuldu';
      case 'ASSIGNED':
        return '🚀 Kurye Atandı';
      case 'ACCEPTED':
        return '✅ Kurye Teslimatı Kabul Etti';
      case 'PICKED_UP':
        return '📍 Paket Alındı, Yolda';
      case 'DELIVERED':
        return '🎉 Teslimat Başarıyla Tamamlandı';
      case 'rejected':
        return '🔄 Kurye Reddetti - Yeni Kurye Aranıyor';
      case 'cancelled':
      case 'CANCELLED':
        return '❌ Teslimat İptal Edildi';
      default:
        return '📬 Teslimat Durumu Güncellendi';
    }
  }

  String _getNotificationMessage(Map<String, dynamic> delivery) {
    final status = delivery['status'] as String;
    final packageCount = delivery['package_count'] ?? 1;
    final amount = delivery['declared_amount'] ?? 0;
    
    // Kurye adını al (JOIN'den gelen courier objesi veya courier_name field'ı)
    String courierName = 'Bir kurye';
    if (delivery['courier'] != null) {
      final courier = delivery['courier'] as Map<String, dynamic>;
      courierName = courier['owner_name'] ?? courier['full_name'] ?? 'Kurye';
    } else if (delivery['courier_name'] != null) {
      courierName = delivery['courier_name'];
    }

    switch (status) {
      case 'PENDING':
        return '$packageCount paket için kurye aranıyor. Toplam: ${amount.toStringAsFixed(2)} TL';
      case 'ASSIGNED':
        return '$courierName teslimatınıza atandı. $packageCount paket, ${amount.toStringAsFixed(2)} TL';
      case 'ACCEPTED':
        return '$courierName teslimatı kabul etti ve yola çıkmak üzere';
      case 'PICKED_UP':
        return '$courierName paketi aldı ve teslimat adresine doğru yola çıktı';
      case 'DELIVERED':
        return 'Teslimat tamamlandı. $packageCount paket müşteriye ulaştırıldı';
      case 'rejected':
        return '$courierName teslimatı reddetti. Sistem otomatik olarak yeni kurye arıyor...';
      case 'cancelled':
      case 'CANCELLED':
        return 'Teslimat iptal edildi. Müsait kurye bulunamadı. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Teslimat durumu güncellendi';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return Colors.blue;
      case 'PICKED_UP':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'rejected':
        return Colors.amber; // Sarı - Yeniden atanıyor
      case 'cancelled':
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.schedule;
      case 'ASSIGNED':
        return Icons.person_add;
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'PICKED_UP':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.done_all;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) {
      final id = n['id'];
      return id != null && !_readNotifications.contains(id.toString());
    }).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('🔔 Bildirimler${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        backgroundColor: Colors.deepOrange,
        actions: [
          if (_notifications.isNotEmpty && unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text(
                'Tümünü Okundu İşaretle',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bildirim yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Teslimat durumu değişiklikleri burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final status = notification['status'] as String? ?? 'PENDING';
    final createdAt = DateTime.parse(notification['created_at'] as String);
    final timeAgo = timeago.format(createdAt, locale: 'tr');
    final notificationId = notification['id']?.toString() ?? '';
    final isRead = _readNotifications.contains(notificationId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      color: isRead ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.grey.shade300 : _getStatusColor(status).withOpacity(0.3),
          width: isRead ? 0.5 : 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          _markAsRead(notificationId);
          _showNotificationDetail(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sol: Durum ikonu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(isRead ? 0.05 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status).withOpacity(isRead ? 0.5 : 1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Orta: Bildirim içeriği
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getNotificationTitle(status),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: isRead ? Colors.grey.shade700 : const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getNotificationMessage(notification),
                      style: TextStyle(
                        fontSize: 14,
                        color: isRead ? Colors.grey.shade600 : Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Detaylar için tıklayın',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Sağ: Ok ikonu
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bildirim detayı popup
  void _showNotificationDetail(Map<String, dynamic> notification) {
    final status = notification['status'] as String;
    final packageCount = notification['package_count'] ?? 1;
    final amount = notification['declared_amount'] ?? 0;
    final notes = notification['notes'] ?? '';
    final createdAt = DateTime.parse(notification['created_at'] as String);
    
    // Kurye adını al
    String courierName = 'Henüz atanmadı';
    if (notification['courier'] != null) {
      final courier = notification['courier'] as Map<String, dynamic>;
      courierName = courier['owner_name'] ?? courier['full_name'] ?? 'Belirtilmemiş';
    } else if (notification['courier_name'] != null) {
      courierName = notification['courier_name'];
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getNotificationTitle(status),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('📦 Paket Sayısı', '$packageCount adet'),
              const Divider(height: 24),
              _detailRow('💰 Toplam Tutar', '${amount.toStringAsFixed(2)} TL'),
              const Divider(height: 24),
              _detailRow('👤 Kurye', courierName),
              const Divider(height: 24),
              _detailRow('📊 Durum', _getStatusText(status)),
              const Divider(height: 24),
              _detailRow('🕐 Tarih', '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'),
              if (notes.isNotEmpty) ...[
                const Divider(height: 24),
                _detailRow('📝 Notlar', notes),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    // Status değerini büyük harfe çevir (database'den küçük harfle gelebiliyor)
    final statusUpper = status.toUpperCase();
    
    switch (statusUpper) {
      case 'PENDING':
        return 'Kurye Bekleniyor';
      case 'ASSIGNED':
        return 'Kurye Atandı';
      case 'ACCEPTED':
        return 'Kabul Edildi';
      case 'PICKED_UP':
        return 'Yolda';
      case 'DELIVERED':
        return 'Teslim Edildi';
      case 'REJECTED':
        return 'Kurye Reddetti - Yeni Kurye Aranıyor';
      case 'CANCELLED':
        return 'İptal Edildi';
      default:
        return status;
    }
  }
}
