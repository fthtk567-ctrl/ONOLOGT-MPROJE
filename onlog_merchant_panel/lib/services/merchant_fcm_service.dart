import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class MerchantFCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // VAPID key - Firebase Console > Project Settings > Cloud Messaging > Web Push certificates
  static const String _vapidKey = 'BEDNpHyY7N2v-mI2AxUDiSxI4KMTTQOPP09jrkLgaGnSkknJBH7BkJtjKyLKHYc56TFzl92_LdEmkCEC3nNLue8';
  
  /// FCM başlat ve token al
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // İzin iste
        final permission = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        
        // Token al
        final token = await _messaging.getToken(vapidKey: _vapidKey);
        
        if (token != null) {
          await _saveTokenToSupabase(token);
        }
      } else {
        // Mobile için
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        
        final token = await _messaging.getToken();
        
        if (token != null) {
          await _saveTokenToSupabase(token);
        }
      }
      
      // Token yenilendiğinde
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken);
      });
      
      // Foreground mesajları dinle
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Bildirim geldi - UI güncellenecek
      });
      
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ FCM başlatma hatası: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
  
  /// Token'ı Supabase'e kaydet
  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        debugPrint('⚠️ Kullanıcı giriş yapmamış, token kaydedilmedi');
        return;
      }
      
      await SupabaseService.from('users').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Token kaydetme hatası: $e');
      }
    }
  }
  
  /// Manuel token kaydet (login sonrası çağır)
  static Future<void> saveCurrentToken() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Token alma hatası: $e');
      }
    }
  }
    } catch (e) {
      debugPrint('❌ Token kaydetme hatası: $e');
      rethrow;  // 🔥 Hatayı yukarı fırlat ki görelim
    }
  }
}
