import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

/// FCM Push Notification Service
/// Supabase + Firebase Cloud Messaging entegrasyonu
/// NOT: Firebase Database KULLANMIYOR, sadece FCM!
class SupabaseFCMService {
  final SupabaseClient _supabase = SupabaseService.client;

  // FCM Server Key - Firebase Console'dan alınacak
  // NOT: Legacy API artık çalışmıyor! HTTP v1 API gerekli
  // Ama önce basit çözüm: users tablosundan token al ve Flutter'ın firebase_messaging paketi kullan
  static const String _fcmServerKey = 'AIzaSyBWO_lr-73AxfBlulvRD0W_wA0fzuTHAXg';
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  /// FCM Token'ı Supabase'e kaydet
  Future<String?> saveToken({
    required String userId,
    required String fcmToken,
    required String deviceType, // 'android', 'ios', 'web'
    String? deviceId,
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      // ÖNEMLİ: Aynı token'a sahip DİĞER kullanıcıların token'ını SİL!
      // (Aynı telefonda farklı kullanıcılar login yaptıysa)
      await _supabase
          .from('users')
          .update({'fcm_token': null, 'updated_at': DateTime.now().toIso8601String()})
          .eq('fcm_token', fcmToken)
          .neq('id', userId);
      
      print('🧹 Eski tokenlar temizlendi');

      // Şimdi yeni kullanıcının token'ını kaydet
      await _supabase
          .from('users')
          .update({'fcm_token': fcmToken, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      print('✅ FCM Token kaydedildi: $userId - $deviceType');
      print('📱 Token: ${fcmToken.substring(0, 30)}...');
      return fcmToken;
    } catch (e) {
      print('❌ FCM Token kaydetme hatası: $e');
      return null;
    }
  }

  /// Kullanıcının tüm aktif token'larını getir
  Future<List<Map<String, dynamic>>> getUserTokens(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_fcm_tokens',
        params: {'p_user_id': userId},
      );

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Token getirme hatası: $e');
      return [];
    }
  }

  /// Role göre kullanıcıların token'larını getir (Admin kullanımı)
  Future<List<Map<String, dynamic>>> getTokensByRole(String role) async {
    try {
      final response = await _supabase.rpc(
        'get_tokens_by_role',
        params: {'p_role': role},
      );

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Role token getirme hatası: $e');
      return [];
    }
  }

  /// Token'ı pasif yap (logout, cihaz değiştirme)
  Future<bool> deactivateToken(String userId, String fcmToken) async {
    try {
      await _supabase
          .from('user_fcm_tokens')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('fcm_token', fcmToken);

      print('✅ Token deaktif edildi');
      return true;
    } catch (e) {
      print('❌ Token deaktif etme hatası: $e');
      return false;
    }
  }

  /// Tek bir kullanıcıya bildirim gönder
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String notificationType, // 'new_order', 'order_delivered', 'payment', 'general'
    Map<String, dynamic>? data,
    String? orderId,
  }) async {
    try {
      // Kullanıcının token'larını getir
      final tokens = await getUserTokens(userId);

      if (tokens.isEmpty) {
        print('⚠️ Kullanıcının aktif token\'ı yok: $userId');
        return false;
      }

      // Tüm cihazlara gönder
      bool allSuccess = true;
      for (final tokenData in tokens) {
        final success = await _sendFCMMessage(
          fcmToken: tokenData['fcm_token'],
          title: title,
          body: body,
          notificationType: notificationType,
          data: data,
        );

        if (!success) allSuccess = false;

        // Bildirim geçmişine kaydet
        await _saveNotificationHistory(
          userId: userId,
          title: title,
          body: body,
          notificationType: notificationType,
          orderId: orderId,
          data: data,
          status: success ? 'sent' : 'failed',
        );
      }

      return allSuccess;
    } catch (e) {
      print('❌ Kullanıcıya bildirim gönderme hatası: $e');
      return false;
    }
  }

  /// Role göre toplu bildirim gönder (Admin kullanımı)
  Future<Map<String, int>> sendNotificationToRole({
    required String role, // 'courier', 'merchant', 'admin'
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final tokens = await getTokensByRole(role);

      int successCount = 0;
      int failCount = 0;

      for (final tokenData in tokens) {
        final success = await _sendFCMMessage(
          fcmToken: tokenData['fcm_token'],
          title: title,
          body: body,
          notificationType: notificationType,
          data: data,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }

        // Bildirim geçmişine kaydet
        await _saveNotificationHistory(
          userId: tokenData['user_id'],
          title: title,
          body: body,
          notificationType: notificationType,
          data: data,
          status: success ? 'sent' : 'failed',
        );
      }

      print('✅ Toplu bildirim gönderildi - Başarılı: $successCount, Başarısız: $failCount');
      return {'success': successCount, 'failed': failCount};
    } catch (e) {
      print('❌ Toplu bildirim gönderme hatası: $e');
      return {'success': 0, 'failed': 0};
    }
  }

  /// FCM'e HTTP POST request gönder
  Future<bool> _sendFCMMessage({
    required String fcmToken,
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_fcmServerKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'priority': 'high',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'badge': '1',
          },
          'data': {
            'type': notificationType,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            ...?data,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': _getChannelId(notificationType),
              'sound': _getNotificationSound(notificationType),
              'priority': 'high',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM mesajı gönderildi');
        return true;
      } else {
        print('❌ FCM hatası: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ FCM mesaj gönderme hatası: $e');
      return false;
    }
  }

  /// Bildirim geçmişine kaydet
  Future<void> _saveNotificationHistory({
    required String userId,
    required String title,
    required String body,
    required String notificationType,
    String? orderId,
    Map<String, dynamic>? data,
    required String status,
  }) async {
    try {
      await _supabase.from('notification_history').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'notification_type': notificationType,
        'order_id': orderId,
        'data': data,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Bildirim geçmişi kaydetme hatası: $e');
    }
  }

  /// Bildirim tipine göre Android channel ID getir
  String _getChannelId(String notificationType) {
    switch (notificationType) {
      case 'new_order':
        return 'new_order_channel';
      case 'urgent':
        return 'urgent_order_channel';
      case 'order_delivered':
        return 'general_channel';
      case 'payment':
        return 'general_channel';
      default:
        return 'info_channel';
    }
  }

  /// Bildirim tipine göre ses dosyası getir
  String _getNotificationSound(String notificationType) {
    switch (notificationType) {
      case 'new_order':
        return 'new_order_sound';
      case 'urgent':
        return 'urgent_sound';
      default:
        return 'default';
    }
  }

  /// Kullanıcının okunmamış bildirim sayısı
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _supabase
          .from('notification_history')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'sent')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('❌ Okunmamış bildirim sayısı getirme hatası: $e');
      return 0;
    }
  }

  /// Bildirimi okundu olarak işaretle
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notification_history')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('❌ Bildirim okundu işaretleme hatası: $e');
      return false;
    }
  }

  /// Kullanıcının son bildirimleri
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('notification_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Bildirim geçmişi getirme hatası: $e');
      return [];
    }
  }
}
