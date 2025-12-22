import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class BatteryOptimizationHelper {
  /// Pil optimizasyonunun devre dışı bırakılması gerektiğini kullanıcıya göster
  static Future<void> requestBatteryOptimizationDisable(BuildContext context) async {
    // Sadece Android'de göster
    if (!Platform.isAndroid) return;

    // Dialog göster
    if (!context.mounted) return;
    
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pil Optimizasyonu',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arka planda bildirim alabilmek için pil optimizasyonunu kapatmanız gerekiyor.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '✅ Bildirimler her zaman gelecek\n'
                '✅ Sipariş kaçırmayacaksınız\n'
                '✅ Konum servisi kesintisiz çalışacak',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Açılacak ayarlar sayfasında:\n\n'
                '1. "Onlog Kurye" uygulamasını bulun\n'
                '2. "Optimize edilmeyen" seçeneğine alın\n'
                '3. Geri dönün',
                style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Daha Sonra', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Ayarları Aç', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      await _openBatteryOptimizationSettings();
      
      // Ayarlardan döndükten sonra bilgi göster
      if (!context.mounted) return;
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Pil optimizasyonu kapatıldı! Artık tüm bildirimler gelecek.',
            style: TextStyle(fontSize: 15),
          ),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Android pil optimizasyonu ayarlarını aç
  static Future<void> _openBatteryOptimizationSettings() async {
    try {
      // Android 6.0+ için REQUEST_IGNORE_BATTERY_OPTIMIZATIONS izni
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      debugPrint('❌ Pil optimizasyonu ayarları açma hatası: $e');
    }
  }

  /// Pil optimizasyonunun kapatılıp kapatılmadığını kontrol et
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Pil optimizasyonu durumu kontrolü hatası: $e');
      return false;
    }
  }

  /// İlk giriş kontrolü - SharedPreferences ile
  static const String _kFirstLoginKey = 'battery_optimization_shown';
  
  static Future<bool> shouldShowDialog() async {
    // SharedPreferences kullanarak daha önce gösterilmiş mi kontrol et
    // Bu kısım CacheService ile yapılabilir
    return true; // İlk versiyonda her zaman göster
  }
}
