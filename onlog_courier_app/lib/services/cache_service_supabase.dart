import 'package:hive_flutter/hive_flutter.dart';
import '../models/cached_delivery.dart';
import 'package:onlog_shared/services/supabase_service.dart';

/// Offline çalışma için Local Cache Servisi (Supabase Edition)
/// 
/// - Supabase'den gelen teslimatları local'de saklar
/// - İnternet yokken bile çalışır
/// - Online olunca otomatik sync eder
class CacheServiceSupabase {
  static const String _deliveryBoxName = 'deliveries';
  static const String _settingsBoxName = 'settings';

  Box<CachedDelivery>? _deliveryBox;
  Box? _settingsBox;

  /// Hive'ı başlat
  Future<void> initialize() async {
    try {
      print('💾 Cache Service başlatılıyor...');
      
      await Hive.initFlutter();
      
      // Adapter'ı kaydet (generated code)
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CachedDeliveryAdapter());
      }

      // Box'ları aç
      _deliveryBox = await Hive.openBox<CachedDelivery>(_deliveryBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      print('✅ Cache Service hazır! ${_deliveryBox!.length} teslimat cache\'de');
    } catch (e) {
      print('❌ Cache Service başlatılamadı: $e');
    }
  }

  /// Teslimatı cache'e kaydet
  Future<void> cacheDelivery(String id, Map<String, dynamic> data) async {
    try {
      final delivery = CachedDelivery.fromSupabase(id, data);
      await _deliveryBox?.put(id, delivery);
      print('💾 Cache\'lendi: $id');
    } catch (e) {
      print('❌ Cache hatası: $e');
    }
  }

  /// Birden fazla teslimatı cache'e kaydet
  Future<void> cacheMultipleDeliveries(List<Map<String, dynamic>> deliveries) async {
    try {
      final batch = <String, CachedDelivery>{};
      for (var delivery in deliveries) {
        final id = delivery['id'] as String;
        final cached = CachedDelivery.fromSupabase(id, delivery);
        batch[id] = cached;
      }
      await _deliveryBox?.putAll(batch);
      print('💾 ${batch.length} teslimat cache\'lendi');
    } catch (e) {
      print('❌ Toplu cache hatası: $e');
    }
  }

  /// Cache'den teslimat al
  CachedDelivery? getCachedDelivery(String id) {
    return _deliveryBox?.get(id);
  }

  /// Tüm cache'lenmiş teslimatları al
  List<CachedDelivery> getAllCachedDeliveries() {
    return _deliveryBox?.values.toList() ?? [];
  }

  /// Kurye'ye atanmış teslimatları al
  List<CachedDelivery> getCourierDeliveries(String courierId) {
    return _deliveryBox?.values
        .where((d) => d.assignedCourierId == courierId)
        .toList() ?? [];
  }

  /// Bekleyen teslimatları al
  List<CachedDelivery> getPendingDeliveries() {
    return _deliveryBox?.values
        .where((d) => d.status == 'pending')
        .toList() ?? [];
  }

  /// Aktif teslimatları al (assigned, pickedUp, delivering)
  List<CachedDelivery> getActiveDeliveries(String courierId) {
    return _deliveryBox?.values
        .where((d) => 
          d.assignedCourierId == courierId &&
          ['assigned', 'pickedUp', 'delivering'].contains(d.status))
        .toList() ?? [];
  }

  /// Tamamlanmış teslimatları al
  List<CachedDelivery> getCompletedDeliveries(String courierId) {
    return _deliveryBox?.values
        .where((d) => 
          d.assignedCourierId == courierId &&
          d.status == 'delivered')
        .toList() ?? [];
  }

  /// Senkronize edilmemiş teslimatları al
  List<CachedDelivery> getUnsyncedDeliveries() {
    return _deliveryBox?.values
        .where((d) => !d.isSynced)
        .toList() ?? [];
  }

  /// Teslimat durumunu güncelle (offline'da da çalışır)
  Future<void> updateDeliveryStatus(
    String id,
    String newStatus, {
    DateTime? timestamp,
  }) async {
    try {
      final delivery = _deliveryBox?.get(id);
      if (delivery == null) {
        print('⚠️ Teslimat cache\'de bulunamadı: $id');
        return;
      }

      delivery.status = newStatus;
      delivery.lastUpdated = DateTime.now();
      delivery.isSynced = false; // Supabase'e sync gerekiyor

      // Timestamp'leri ayarla
      switch (newStatus) {
        case 'assigned':
          delivery.assignedAt = timestamp ?? DateTime.now();
          break;
        case 'pickedUp':
          delivery.pickedUpAt = timestamp ?? DateTime.now();
          break;
        case 'delivered':
          delivery.deliveredAt = timestamp ?? DateTime.now();
          break;
      }

      await delivery.save();
      print('💾 Durum güncellendi (offline): $id -> $newStatus');
    } catch (e) {
      print('❌ Durum güncelleme hatası: $e');
    }
  }

  /// Offline değişiklikleri Supabase'e sync et
  Future<void> syncWithSupabase() async {
    try {
      final unsynced = getUnsyncedDeliveries();
      if (unsynced.isEmpty) {
        print('✅ Tüm veriler senkronize');
        return;
      }

      print('🔄 ${unsynced.length} teslimat senkronize ediliyor...');

      for (var delivery in unsynced) {
        try {
          await SupabaseService.client
              .from('delivery_requests')
              .update(delivery.toSupabase())
              .eq('id', delivery.id);

          delivery.isSynced = true;
          await delivery.save();
          print('✅ Senkronize edildi: ${delivery.id}');
        } catch (e) {
          print('❌ Sync hatası (${delivery.id}): $e');
        }
      }

      print('✅ Senkronizasyon tamamlandı!');
    } catch (e) {
      print('❌ Sync hatası: $e');
    }
  }

  /// Cache'i temizle
  Future<void> clearCache() async {
    await _deliveryBox?.clear();
    print('🗑️ Cache temizlendi');
  }

  /// Eski teslimatları temizle (30 günden eski)
  Future<void> cleanOldDeliveries() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final toDelete = <String>[];

      _deliveryBox?.toMap().forEach((key, delivery) {
        if (delivery.lastUpdated.isBefore(thirtyDaysAgo) &&
            delivery.status == 'delivered') {
          toDelete.add(key);
        }
      });

      for (var key in toDelete) {
        await _deliveryBox?.delete(key);
      }

      print('🗑️ ${toDelete.length} eski teslimat temizlendi');
    } catch (e) {
      print('❌ Temizleme hatası: $e');
    }
  }

  /// Belirli bir teslimatı cache'den sil
  Future<void> removeDelivery(String id) async {
    await _deliveryBox?.delete(id);
    print('🗑️ Cache\'den silindi: $id');
  }

  /// Cache durumunu al (debug için)
  Map<String, dynamic> getCacheStats() {
    final deliveries = getAllCachedDeliveries();
    final unsynced = getUnsyncedDeliveries();
    
    return {
      'total': deliveries.length,
      'unsynced': unsynced.length,
      'pending': deliveries.where((d) => d.status == 'pending').length,
      'assigned': deliveries.where((d) => d.status == 'assigned').length,
      'pickedUp': deliveries.where((d) => d.status == 'pickedUp').length,
      'delivered': deliveries.where((d) => d.status == 'delivered').length,
    };
  }

  /// Settings'den veri al
  dynamic getSetting(String key) {
    return _settingsBox?.get(key);
  }

  /// Settings'e veri kaydet
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  /// Son senkronizasyon zamanını kaydet
  Future<void> updateLastSyncTime() async {
    await setSetting('lastSyncTime', DateTime.now().toIso8601String());
  }

  /// Son senkronizasyon zamanını al
  DateTime? getLastSyncTime() {
    final timeStr = getSetting('lastSyncTime') as String?;
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }
}
