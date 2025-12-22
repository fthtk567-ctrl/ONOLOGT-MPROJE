import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer' as developer;

// Bildirim tipleri
enum NotificationType {
  orderCreated,
  login,
  system,
  test,
}

// Bildirim modeli
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? orderId;
  final String? platform;
  final Map<String, dynamic>? extraData;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.orderId,
    this.platform,
    this.extraData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'orderId': orderId,
      'platform': platform,
      'extraData': extraData,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'] ?? '', // Geriye uyumluluk için
      type: _parseNotificationType(map['type'] ?? 'system'),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: map['isRead'] ?? false,
      orderId: map['orderId'],
      platform: map['platform'],
      extraData: map['extraData'] is Map ? Map<String, dynamic>.from(map['extraData']) : null,
    );
  }

  static NotificationType _parseNotificationType(String typeStr) {
    switch (typeStr) {
      case 'NotificationType.orderCreated':
      case 'order':
        return NotificationType.orderCreated;
      case 'NotificationType.login':
      case 'login':
        return NotificationType.login;
      case 'NotificationType.system':
      case 'system':
        return NotificationType.system;
      case 'NotificationType.test':
      case 'test':
        return NotificationType.test;
      default:
        return NotificationType.system;
    }
  }
}

class NotificationHistoryService {
  static const String _notificationsKey = 'notification_history';
  static const int _maxNotifications = 100; // Maksimum saklanan bildirim sayısı

  // Bildirim modeli
  static Map<String, dynamic> createNotification({
    required String id,
    required String title,
    required String message,
    required String type, // 'order', 'system', 'marketing', 'security'
    required DateTime timestamp,
    bool isRead = false,
    String? orderId,
    String? platform,
    Map<String, dynamic>? extraData,
  }) {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'orderId': orderId,
      'platform': platform,
      'extraData': extraData,
    };
  }

  // Bildirim ekle
  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? orderId,
    String? platform,
    Map<String, dynamic>? extraData,
  }) async {
    final notifications = await getNotifications();
    
    final newNotification = createNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      orderId: orderId,
      platform: platform,
      extraData: extraData,
    );

    notifications.insert(0, newNotification); // En yenisini başa ekle
    
    // Maksimum limit kontrol
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }
    
    await _saveNotifications(notifications);
    
    developer.log('📋 Bildirim geçmişe eklendi: $title');
  }

  // Tüm bildirimleri getir
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> notificationsList = json.decode(notificationsJson);
      return notificationsList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Bildirim geçmişi yüklenemedi: $e');
      return [];
    }
  }

  // Okunmamış bildirimleri getir
  static Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final notifications = await getNotifications();
    return notifications.where((notification) => !notification['isRead']).toList();
  }

  // Bildirim sayıları
  static Future<Map<String, int>> getNotificationCounts() async {
    final notifications = await getNotifications();
    final unreadNotifications = notifications.where((n) => !n['isRead']).toList();
    
    return {
      'total': notifications.length,
      'unread': unreadNotifications.length,
      'order': unreadNotifications.where((n) => n['type'] == 'order').length,
      'system': unreadNotifications.where((n) => n['type'] == 'system').length,
      'marketing': unreadNotifications.where((n) => n['type'] == 'marketing').length,
      'security': unreadNotifications.where((n) => n['type'] == 'security').length,
    };
  }

  // Bildirimi okundu olarak işaretle
  static Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();
    
    for (var notification in notifications) {
      if (notification['id'] == notificationId) {
        notification['isRead'] = true;
        break;
      }
    }
    
    await _saveNotifications(notifications);
    debugPrint('📖 Bildirim okundu olarak işaretlendi: $notificationId');
  }

  // Tüm bildirimleri okundu olarak işaretle
  static Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    
    for (var notification in notifications) {
      notification['isRead'] = true;
    }
    
    await _saveNotifications(notifications);
    debugPrint('📚 Tüm bildirimler okundu olarak işaretlendi');
  }

  // Bildirimi sil
  static Future<void> deleteNotification(String notificationId) async {
    final notifications = await getNotifications();
    notifications.removeWhere((notification) => notification['id'] == notificationId);
    await _saveNotifications(notifications);
    debugPrint('🗑️ Bildirim silindi: $notificationId');
  }

  // Tüm bildirimleri sil
  static Future<void> clearAllNotifications() async {
    await _saveNotifications([]);
    debugPrint('🧹 Tüm bildirimler temizlendi');
  }

  // Tip bazında bildirimleri filtrele
  static Future<List<Map<String, dynamic>>> getNotificationsByType(String type) async {
    final notifications = await getNotifications();
    return notifications.where((notification) => notification['type'] == type).toList();
  }

  // Tarih aralığında bildirimleri getir
  static Future<List<Map<String, dynamic>>> getNotificationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final notifications = await getNotifications();
    
    return notifications.where((notification) {
      final timestamp = DateTime.parse(notification['timestamp']);
      return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
    }).toList();
  }

  // Bugünkü bildirimleri getir
  static Future<List<Map<String, dynamic>>> getTodayNotifications() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await getNotificationsByDateRange(startOfDay, endOfDay);
  }

  // Bildirimleri kaydet (private)
  static Future<void> _saveNotifications(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, json.encode(notifications));
  }

  // Demo bildirimleri ekle
  static Future<void> addDemoNotifications() async {
    final demoNotifications = [
      {
        'title': 'Yeni Sipariş Alındı',
        'message': 'Trendyol\'dan #12345 numaralı sipariş - 54.00 TL',
        'type': 'order',
        'orderId': '12345',
        'platform': 'trendyol',
      },
      {
        'title': 'Sipariş Teslim Edildi',
        'message': 'Yemeksepeti #67890 siparişi başarıyla teslim edildi',
        'type': 'order',
        'orderId': '67890',
        'platform': 'yemeksepeti',
      },
      {
        'title': 'Sistem Güncellemesi',
        'message': 'Uygulama v2.1.0 güncellendi. Yeni özellikler eklendi.',
        'type': 'system',
      },
      {
        'title': 'Güvenlik Uyarısı',
        'message': 'Hesabınıza yeni bir cihazdan giriş yapıldı.',
        'type': 'security',
      },
      {
        'title': 'Özel Teklif',
        'message': 'Premium plan için %30 indirim! Bu fırsat kaçmaz.',
        'type': 'marketing',
      },
      {
        'title': 'Getir Siparişi',
        'message': 'Getir\'den #98765 numaralı sipariş - 23.50 TL',
        'type': 'order',
        'orderId': '98765',
        'platform': 'getir',
      },
    ];

    for (var demo in demoNotifications) {
      await addNotification(
        title: demo['title']!,
        message: demo['message']!,
        type: demo['type']!,
        orderId: demo['orderId'],
        platform: demo['platform'],
      );
      
      // Farklı zaman damgaları için kısa bekleme
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint('🎭 Demo bildirimler eklendi');
  }

  // Bildirim ikonunu getir
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return '📦';
      case 'system':
        return '⚙️';
      case 'security':
        return '🔒';
      case 'marketing':
        return '🎯';
      default:
        return '📢';
    }
  }

  // Bildirim rengini getir
  static String getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return '#4CAF50'; // Yeşil
      case 'system':
        return '#2196F3'; // Mavi
      case 'security':
        return '#FF9800'; // Turuncu
      case 'marketing':
        return '#9C27B0'; // Mor
      default:
        return '#757575'; // Gri
    }
  }

  // Yeni model ile bildirimleri getir
  static Future<List<NotificationItem>> getAllNotifications() async {
    final rawNotifications = await getNotifications();
    return rawNotifications.map((map) => NotificationItem.fromMap(map)).toList();
  }

  // Bildirim okunmadı olarak işaretle
  static Future<void> markAsUnread(String notificationId) async {
    final notifications = await getNotifications();
    
    final index = notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      notifications[index]['isRead'] = false;
      await _saveNotifications(notifications);
      debugPrint('📬 Bildirim okunmadı olarak işaretlendi: $notificationId');
    }
  }

  // Yeni model ile bildirim ekle
  static Future<void> addNotificationItem(NotificationItem notification) async {
    final notifications = await getNotifications();
    
    notifications.insert(0, notification.toMap());
    
    // Maksimum limit kontrol
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }
    
    await _saveNotifications(notifications);
    debugPrint('📋 NotificationItem geçmişe eklendi: ${notification.title}');
  }
}




