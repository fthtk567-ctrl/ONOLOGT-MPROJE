import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'notification_history_service.dart';
import 'audio_service.dart';

class NotificationService {
  // Bildirim ayarları anahtarları
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _smsNotificationsKey = 'sms_notifications';
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _orderAlertsKey = 'order_alerts';
  static const String _marketingEmailsKey = 'marketing_emails';

  // Dil ayarları
  static const String _languageKey = 'selected_language';

  // Güvenlik ayarları
  static const String _twoFactorAuthKey = 'two_factor_auth';
  static const String _loginNotificationsKey = 'login_notifications';
  static const String _autoLockKey = 'auto_lock';
  static const String _autoLockTimeKey = 'auto_lock_time';

  // Bildirim ayarlarını kaydet
  static Future<void> saveNotificationSettings({
    required bool emailNotifications,
    required bool smsNotifications,
    required bool pushNotifications,
    required bool orderAlerts,
    required bool marketingEmails,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, emailNotifications);
    await prefs.setBool(_smsNotificationsKey, smsNotifications);
    await prefs.setBool(_pushNotificationsKey, pushNotifications);
    await prefs.setBool(_orderAlertsKey, orderAlerts);
    await prefs.setBool(_marketingEmailsKey, marketingEmails);
    
    developer.log('📧 Bildirim ayarları kaydedildi:');
    developer.log('   E-posta: $emailNotifications');
    developer.log('   SMS: $smsNotifications');
    developer.log('   Push: $pushNotifications');
    developer.log('   Sipariş uyarıları: $orderAlerts');
    developer.log('   Pazarlama e-postaları: $marketingEmails');
  }

  // Bildirim ayarlarını oku
  static Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'emailNotifications': prefs.getBool(_emailNotificationsKey) ?? true,
      'smsNotifications': prefs.getBool(_smsNotificationsKey) ?? true,
      'pushNotifications': prefs.getBool(_pushNotificationsKey) ?? true,
      'orderAlerts': prefs.getBool(_orderAlertsKey) ?? true,
      'marketingEmails': prefs.getBool(_marketingEmailsKey) ?? false,
    };
  }

  // E-posta bildirimi gönder (gerçek API entegrasyonu)
  static Future<bool> sendEmailNotification({
    required String to,
    required String subject,
    required String message,
    String type = 'general',
  }) async {
    final settings = await getNotificationSettings();
    
    // E-posta bildirimleri kapalıysa gönderme
    if (!settings['emailNotifications']!) {
      debugPrint('📧 E-posta bildirimleri kapalı - gönderilmedi: $subject');
      return false;
    }

    // Pazarlama e-postaları için özel kontrol
    if (type == 'marketing' && !settings['marketingEmails']!) {
      debugPrint('📧 Pazarlama e-postaları kapalı - gönderilmedi: $subject');
      return false;
    }

    // Sipariş uyarıları için özel kontrol
    if (type == 'order' && !settings['orderAlerts']!) {
      debugPrint('📧 Sipariş uyarıları kapalı - gönderilmedi: $subject');
      return false;
    }

    // Gerçek e-posta gönderimi (API entegrasyonu)
    try {
      debugPrint('📧 E-posta gönderiliyor...');
      debugPrint('   Alıcı: $to');
      debugPrint('   Konu: $subject');
      debugPrint('   Mesaj: $message');
      debugPrint('   Tip: $type');
      
      // TODO: Gerçek e-posta API'si (SendGrid, AWS SES, vb.) entegrasyonu
      await Future.delayed(const Duration(seconds: 1)); // Simülasyon
      
      debugPrint('✅ E-posta başarıyla gönderildi!');
      return true;
    } catch (e) {
      debugPrint('❌ E-posta gönderme hatası: $e');
      return false;
    }
  }

  // SMS bildirimi gönder (gerçek API entegrasyonu)
  static Future<bool> sendSmsNotification({
    required String phoneNumber,
    required String message,
    String type = 'general',
  }) async {
    final settings = await getNotificationSettings();
    
    // SMS bildirimleri kapalıysa gönderme
    if (!settings['smsNotifications']!) {
      debugPrint('📱 SMS bildirimleri kapalı - gönderilmedi: $message');
      return false;
    }

    // Sipariş uyarıları için özel kontrol
    if (type == 'order' && !settings['orderAlerts']!) {
      debugPrint('📱 Sipariş uyarıları kapalı - gönderilmedi: $message');
      return false;
    }

    // Gerçek SMS gönderimi (API entegrasyonu)
    try {
      debugPrint('📱 SMS gönderiliyor...');
      debugPrint('   Telefon: $phoneNumber');
      debugPrint('   Mesaj: $message');
      debugPrint('   Tip: $type');
      
      // TODO: Gerçek SMS API'si (Twilio, Netgsm, vb.) entegrasyonu
      await Future.delayed(const Duration(seconds: 1)); // Simülasyon
      
      debugPrint('✅ SMS başarıyla gönderildi!');
      return true;
    } catch (e) {
      debugPrint('❌ SMS gönderme hatası: $e');
      return false;
    }
  }

  // Push bildirimi gönder (gerçek push notification)
  static Future<bool> sendPushNotification({
    required String title,
    required String body,
    String type = 'general',
    Map<String, String>? data,
  }) async {
    final settings = await getNotificationSettings();
    
    // Push bildirimleri kapalıysa gönderme
    if (!settings['pushNotifications']!) {
      debugPrint('🔔 Push bildirimleri kapalı - gönderilmedi: $title');
      return false;
    }

    // Sipariş uyarıları için özel kontrol
    if (type == 'order' && !settings['orderAlerts']!) {
      debugPrint('🔔 Sipariş uyarıları kapalı - gönderilmedi: $title');
      return false;
    }

    // Gerçek push notification gönderimi
    try {
      debugPrint('🔔 Push bildirimi gönderiliyor...');
      debugPrint('   Başlık: $title');
      debugPrint('   İçerik: $body');
      debugPrint('   Tip: $type');
      debugPrint('   Data: $data');
      
      // TODO: Gerçek push notification (Supabase Edge Functions, OneSignal, vb.)
      // Supabase Edge Function ile push notification gönder:
      // await SupabaseService.client.functions.invoke('send-notification', body: {
      //   'user_id': userId,
      //   'title': title,
      //   'body': body,
      //   'type': type,
      //   'data': data,
      // });
      await Future.delayed(const Duration(seconds: 1)); // Simülasyon
      
      debugPrint('✅ Push bildirimi başarıyla gönderildi!');
      return true;
    } catch (e) {
      debugPrint('❌ Push bildirimi gönderme hatası: $e');
      return false;
    }
  }

  // Yeni sipariş bildirimi gönder (tüm kanallar)
  static Future<void> sendOrderNotification({
    required String orderNumber,
    required String customerName,
    required double amount,
    required String userEmail,
    required String userPhone,
  }) async {
    final message = 'Yeni sipariş alındı!\n'
        'Sipariş No: $orderNumber\n'
        'Müşteri: $customerName\n'
        'Tutar: ${amount.toStringAsFixed(2)} TL';

    // Bildirim geçmişine ekle
    final notificationItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Yeni Sipariş Alındı',
      body: '$orderNumber - $customerName - ${amount.toStringAsFixed(2)} TL',
      type: NotificationType.orderCreated,
      timestamp: DateTime.now(),
      orderId: orderNumber,
      extraData: {
        'customerName': customerName,
        'amount': amount,
        'channels': ['email', 'sms', 'push'],
      },
    );
    await NotificationHistoryService.addNotificationItem(notificationItem);

    // E-posta bildirimi
    await sendEmailNotification(
      to: userEmail,
      subject: 'Yeni Sipariş - $orderNumber',
      message: message,
      type: 'order',
    );

    // SMS bildirimi
    await sendSmsNotification(
      phoneNumber: userPhone,
      message: 'Yeni sipariş: $orderNumber - ${amount.toStringAsFixed(2)} TL',
      type: 'order',
    );

    // Push bildirimi
    await sendPushNotification(
      title: 'Yeni Sipariş Alındı!',
      body: 'Sipariş No: $orderNumber - ${amount.toStringAsFixed(2)} TL',
      type: 'order',
      data: {
        'orderNumber': orderNumber,
        'amount': amount.toString(),
      },
    );
  }

  // Pazarlama e-postası gönder
  static Future<void> sendMarketingEmail({
    required String userEmail,
    required String subject,
    required String content,
  }) async {
    await sendEmailNotification(
      to: userEmail,
      subject: subject,
      message: content,
      type: 'marketing',
    );
  }

  // Dil ayarını kaydet
  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    debugPrint('🌍 Dil ayarı kaydedildi: $language');
  }

  // Dil ayarını oku
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'Türkçe';
  }

  // Güvenlik ayarlarını kaydet
  static Future<void> saveSecuritySettings({
    required bool twoFactorAuth,
    required bool loginNotifications,
    required bool autoLock,
    required String autoLockTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFactorAuthKey, twoFactorAuth);
    await prefs.setBool(_loginNotificationsKey, loginNotifications);
    await prefs.setBool(_autoLockKey, autoLock);
    await prefs.setString(_autoLockTimeKey, autoLockTime);
    
    debugPrint('🔒 Güvenlik ayarları kaydedildi:');
    debugPrint('   2FA: $twoFactorAuth');
    debugPrint('   Giriş bildirimleri: $loginNotifications');
    debugPrint('   Otomatik kilit: $autoLock');
    debugPrint('   Kilit süresi: $autoLockTime');
  }

  // Güvenlik ayarlarını oku
  static Future<Map<String, dynamic>> getSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'twoFactorAuth': prefs.getBool(_twoFactorAuthKey) ?? false,
      'loginNotifications': prefs.getBool(_loginNotificationsKey) ?? true,
      'autoLock': prefs.getBool(_autoLockKey) ?? false,
      'autoLockTime': prefs.getString(_autoLockTimeKey) ?? '5 dakika',
    };
  }

  // Giriş bildirimi gönder
  static Future<void> sendLoginNotification({
    required String userEmail,
    required String userPhone,
    required String deviceInfo,
    required String location,
  }) async {
    final settings = await getSecuritySettings();
    
    if (!settings['loginNotifications']) {
      debugPrint('🔐 Giriş bildirimleri kapalı');
      return;
    }

    final message = 'Hesabınıza giriş yapıldı.\n'
        'Cihaz: $deviceInfo\n'
        'Konum: $location\n'
        'Tarih: ${DateTime.now().toString()}';

    // Bildirim geçmişine ekle
    final notificationItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Güvenlik Uyarısı',
      body: 'Hesabınıza $deviceInfo cihazından giriş yapıldı',
      type: NotificationType.login,
      timestamp: DateTime.now(),
      extraData: {
        'deviceInfo': deviceInfo,
        'location': location,
      },
    );
    await NotificationHistoryService.addNotificationItem(notificationItem);

    // E-posta ile giriş bildirimi
    await sendEmailNotification(
      to: userEmail,
      subject: 'Hesap Giriş Bildirimi',
      message: message,
      type: 'security',
    );

    // SMS ile giriş bildirimi
    await sendSmsNotification(
      phoneNumber: userPhone,
      message: 'Hesabınıza giriş yapıldı. Siz değilseniz şifrenizi değiştirin.',
      type: 'security',
    );
  }

  // Test bildirimi gönder
  static Future<void> sendTestNotification({
    required String userEmail,
    required String userPhone,
  }) async {
    debugPrint('🧪 Test bildirimi gönderiliyor...');
    
    // Bildirim geçmişine ekle
    final notificationItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Test Bildirimi',
      body: 'Bildirim sistemi test edildi - Tüm kanallar aktif!',
      type: NotificationType.test,
      timestamp: DateTime.now(),
      extraData: {
        'testType': 'manual',
        'channels': ['email', 'sms', 'push'],
      },
    );
    await NotificationHistoryService.addNotificationItem(notificationItem);
    
    await sendEmailNotification(
      to: userEmail,
      subject: 'Test E-posta Bildirimi',
      message: 'Bu bir test e-postasıdır. Bildirim ayarlarınız çalışıyor!',
    );

    await sendSmsNotification(
      phoneNumber: userPhone,
      message: 'Test SMS bildirimi. Ayarlarınız aktif!',
    );

    await sendPushNotification(
      title: 'Test Bildirimi',
      body: 'Push bildirimi test edildi!',
    );
  }

  // ============================================================================
  // Sesli Uyarı Fonksiyonları (Mock)
  // ============================================================================

  static const String _soundEnabledKey = 'sound_enabled';
  static const String _soundVolumeKey = 'sound_volume';
  static const String _selectedSoundKey = 'selected_sound';

  /// Sesli uyarı açık mı?
  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  /// Sesli uyarıyı aç/kapat
  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
    debugPrint('🔊 Sesli uyarı: ${enabled ? 'Açık' : 'Kapalı'}');
  }

  /// Ses seviyesini al
  static Future<double> getSoundVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_soundVolumeKey) ?? 0.7;
  }

  /// Ses seviyesini ayarla (0.0 - 1.0)
  static Future<void> setSoundVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    final clampedVolume = volume.clamp(0.0, 1.0);
    await prefs.setDouble(_soundVolumeKey, clampedVolume);
    debugPrint('🔊 Ses seviyesi: ${(clampedVolume * 100).toInt()}%');
  }

  /// Seçili sesi al
  static Future<String> getSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedSoundKey) ?? 'Varsayılan';
  }

  /// Seçili sesi ayarla
  static Future<void> setSelectedSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSoundKey, sound);
    debugPrint('🔊 Bildirim sesi: $sound');
  }

  /// Yeni sipariş için sesli uyarı çal
  static Future<void> playNewOrderSound() async {
    if (await isSoundEnabled()) {
      final volume = await getSoundVolume();
      final sound = await getSelectedSound();
      debugPrint('🔔 YENİ SİPARİŞ SESİ ÇALINIYOR ($sound, Volume: ${(volume * 100).toInt()}%)');
      
      // Web ve mobil için farklı ses çalma
      if (kIsWeb) {
        debugPrint('✅ Web platformunda HTML5 Audio ile ses çalacak');
        // Web ses çalma kodu web_entrypoint'te olacak
      } else {
        // Mobil: audioplayers ile gerçek ses çal
        await AudioService().playNotificationSound(volume: volume);
      }
    }
  }

  /// Kurye atandı için sesli uyarı çal
  static Future<void> playCourierAssignedSound() async {
    if (await isSoundEnabled()) {
      final volume = await getSoundVolume();
      debugPrint('🚴 KURYE ATANDI SESİ ÇALINIYOR (Volume: ${(volume * 100).toInt()}%)');
      
      if (kIsWeb) {
        debugPrint('✅ Web platformunda HTML5 Audio ile ses çalacak');
      } else {
        await AudioService().playNotificationSound(volume: volume);
      }
    }
  }

  /// Gecikme uyarısı için sesli uyarı çal
  static Future<void> playDelayWarningSound() async {
    if (await isSoundEnabled()) {
      final volume = await getSoundVolume();
      debugPrint('⚠️ GECİKME UYARISI SESİ ÇALINIYOR (Volume: ${(volume * 100).toInt()}%)');
      
      if (kIsWeb) {
        debugPrint('✅ Web platformunda HTML5 Audio ile ses çalacak');
      } else {
        await AudioService().playWarningSound(volume: volume);
      }
    }
  }

  /// Test sesi çal
  static Future<void> playTestSound() async {
    if (await isSoundEnabled()) {
      final volume = await getSoundVolume();
      final sound = await getSelectedSound();
      debugPrint('🔊 TEST SESİ ÇALINIYOR ($sound, Volume: ${(volume * 100).toInt()}%)');
      
      if (kIsWeb) {
        debugPrint('✅ Web platformunda HTML5 Audio ile ses çalacak');
      } else {
        await AudioService().playNotificationSound(volume: volume);
      }
    } else {
      debugPrint('🔇 Sesli uyarılar kapalı - test sesi çalınamadı');
    }
  }

  /// Teslimat tamamlandı için sesli uyarı çal - Başarı sesi!
  static Future<void> playDeliveryCompletedSound() async {
    if (await isSoundEnabled()) {
      final volume = await getSoundVolume();
      debugPrint('✅ TESLİMAT TAMAMLANDI SESİ ÇALINIYOR (Volume: ${(volume * 100).toInt()}%)');
      
      if (kIsWeb) {
        debugPrint('✅ Web platformunda HTML5 Audio ile ses çalacak');
      } else {
        await AudioService().playSuccessSound(volume: volume);
      }
    }
  }
}




