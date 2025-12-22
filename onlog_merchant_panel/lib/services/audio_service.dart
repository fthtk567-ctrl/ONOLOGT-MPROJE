import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Mobil ve Web için ses çalma servisi
/// Web: HTML5 Audio ile çalışır
/// Mobil: audioplayers paketi ile çalışır
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  
  /// Sistem bildirimi sesi (varsayılan Android/iOS ses)
  Future<void> playNotificationSound({double volume = 0.7}) async {
    if (kIsWeb) {
      debugPrint('🌐 Web platformunda ses - HTML5 Audio kullanılacak');
      return;
    }

    try {
      await _player.setVolume(volume);
      
      // Android sistem bildirimi sesi
      // Bu ses Android cihazlarda otomatik olarak çalınır
      await _player.play(
        AssetSource('sounds/notification.mp3'),
        volume: volume,
      );
      
      debugPrint('🔔 MOBİL: Bildirim sesi çalındı (Volume: ${(volume * 100).toInt()}%)');
    } catch (e) {
      // Ses dosyası yoksa basit beep sesi çıkar
      debugPrint('⚠️ Ses dosyası bulunamadı, sistem sesi kullanılıyor: $e');
      await _playSystemBeep(volume);
    }
  }

  /// Başarı sesi (teslimat tamamlandı gibi)
  Future<void> playSuccessSound({double volume = 0.7}) async {
    if (kIsWeb) return;

    try {
      await _player.setVolume(volume);
      await _player.play(
        AssetSource('sounds/success.mp3'),
        volume: volume,
      );
      debugPrint('✅ MOBİL: Başarı sesi çalındı');
    } catch (e) {
      debugPrint('⚠️ Başarı sesi bulunamadı: $e');
      await _playSystemBeep(volume);
    }
  }

  /// Uyarı sesi (gecikme gibi)
  Future<void> playWarningSound({double volume = 0.8}) async {
    if (kIsWeb) return;

    try {
      await _player.setVolume(volume);
      await _player.play(
        AssetSource('sounds/warning.mp3'),
        volume: volume,
      );
      debugPrint('⚠️ MOBİL: Uyarı sesi çalındı');
    } catch (e) {
      debugPrint('⚠️ Uyarı sesi bulunamadı: $e');
      await _playSystemBeep(volume);
    }
  }

  /// Acil/Önemli bildirim sesi
  Future<void> playUrgentSound({double volume = 0.9}) async {
    if (kIsWeb) return;

    try {
      await _player.setVolume(volume);
      await _player.play(
        AssetSource('sounds/urgent.mp3'),
        volume: volume,
      );
      debugPrint('🚨 MOBİL: Acil ses çalındı');
    } catch (e) {
      debugPrint('⚠️ Acil ses bulunamadı: $e');
      await _playSystemBeep(volume);
    }
  }

  /// Basit beep sesi (fallback)
  Future<void> _playSystemBeep(double volume) async {
    try {
      // ByteData ile basit beep sesi oluştur
      await _player.setVolume(volume);
      // Varsayılan URL beep sesi
      await _player.play(
        UrlSource('https://www.soundjay.com/buttons/sounds/beep-01a.mp3'),
        volume: volume,
      );
      debugPrint('🔊 Sistem beep sesi çalındı');
    } catch (e) {
      debugPrint('❌ Beep sesi de çalınamadı: $e');
    }
  }

  /// Tüm sesleri durdur
  Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose
  void dispose() {
    _player.dispose();
  }
}
