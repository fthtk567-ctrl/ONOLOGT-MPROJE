import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/trendyol_order_model.dart';
import 'trendyol_api_service.dart';
import 'notification_service.dart';

/// Trendyol Sipariş Polling Servisi
/// Her 30 saniyede bir yeni siparişleri kontrol eder
class TrendyolPollingService {
  // Singleton
  static final TrendyolPollingService _instance = TrendyolPollingService._internal();
  factory TrendyolPollingService() => _instance;
  TrendyolPollingService._internal();

  final _apiService = TrendyolApiService();
  
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  // Polling interval (30 saniye)
  static const Duration _pollingInterval = Duration(seconds: 30);
  
  // Son kontrol edilen sipariş ID'leri (duplicate önlemek için)
  final Set<String> _seenOrderIds = {};
  
  // Callback - Yeni sipariş geldiğinde tetiklenir
  Function(List<TrendyolOrderModel>)? onNewOrders;
  
  // Callback - Hata olduğunda tetiklenir
  Function(String)? onError;

  /// Polling'i başlat
  void startPolling() {
    if (_isPolling) {
      debugPrint('⚠️ [Trendyol Polling] Already running!');
      return;
    }

    debugPrint('▶️ [Trendyol Polling] Starting... (interval: $_pollingInterval)');
    _isPolling = true;
    
    // İlk çekme hemen yap
    _checkNewOrders();
    
    // Periyodik çekme
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _checkNewOrders();
    });
  }

  /// Polling'i durdur
  void stopPolling() {
    if (!_isPolling) return;
    
    debugPrint('⏸️ [Trendyol Polling] Stopping...');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  /// Yeni siparişleri kontrol et
  Future<void> _checkNewOrders() async {
    try {
      debugPrint('🔄 [Trendyol Polling] Checking for new orders...');
      
      // Created durumundaki siparişleri çek
      final newOrders = await _apiService.fetchNewOrders();
      
      if (newOrders.isEmpty) {
        debugPrint('✅ [Trendyol Polling] No new orders');
        return;
      }

      // Daha önce görülmemiş siparişleri filtrele
      final unseenOrders = newOrders.where((order) {
        return !_seenOrderIds.contains(order.id);
      }).toList();

      if (unseenOrders.isEmpty) {
        debugPrint('✅ [Trendyol Polling] ${newOrders.length} orders already seen');
        return;
      }

      // Yeni siparişleri kaydet
      for (final order in unseenOrders) {
        _seenOrderIds.add(order.id);
      }

      debugPrint('🎉 [Trendyol Polling] ${unseenOrders.length} NEW orders found!');
      
      // Bildirim gönder (her sipariş için)
      for (final order in unseenOrders) {
        await _sendNewOrderNotification(order);
      }

      // Callback tetikle
      onNewOrders?.call(unseenOrders);

    } catch (e) {
      debugPrint('❌ [Trendyol Polling] Error: $e');
      onError?.call(e.toString());
    }
  }

  /// Yeni sipariş bildirimi gönder
  Future<void> _sendNewOrderNotification(TrendyolOrderModel order) async {
    try {
      // Ses çal
      await NotificationService.playNewOrderSound();
      
      debugPrint('🔔 [Trendyol Polling] Notification sent for order ${order.orderNumber}');
      debugPrint('   Customer: ${order.customer.fullName}');
      debugPrint('   Amount: ₺${order.totalPrice.toStringAsFixed(2)}');
      debugPrint('   Payment: ${order.payment.paymentTypeText}');
    } catch (e) {
      debugPrint('❌ [Trendyol Polling] Notification error: $e');
    }
  }

  /// Manuel sipariş yenileme
  Future<void> refreshOrders() async {
    debugPrint('🔄 [Trendyol Polling] Manual refresh requested');
    await _checkNewOrders();
  }

  /// Görülen siparişleri temizle (test için)
  void clearSeenOrders() {
    _seenOrderIds.clear();
    debugPrint('🗑️ [Trendyol Polling] Seen orders cleared');
  }

  /// Polling durumunu kontrol et
  bool get isRunning => _isPolling;

  /// Görülen sipariş sayısı
  int get seenOrderCount => _seenOrderIds.length;

  /// Servisi temizle
  void dispose() {
    stopPolling();
    _seenOrderIds.clear();
  }
}
