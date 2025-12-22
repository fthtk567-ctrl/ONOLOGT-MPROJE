import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Risk Yönetimi Servisi
/// Sahtekarlık tespiti, şüpheli aktivite izleme
class SupabaseRiskService {
  static final _supabase = Supabase.instance.client;

  // ============================================
  // RİSK ALGILAMA
  // ============================================

  /// Risk uyarısı oluştur
  static Future<String?> createAlert({
    required String alertType, // 'suspicious_order', 'multiple_failures', 'high_refund_rate', 'unusual_pattern'
    required String severity, // 'low', 'medium', 'high', 'critical'
    String? userId,
    String? orderId,
    required String description,
    Map<String, dynamic>? metadata,
    String? aiAnalysis,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_RISK_ALERTS)
          .insert({
            'alert_type': alertType,
            'severity': severity,
            'user_id': userId,
            'order_id': orderId,
            'description': description,
            'metadata': metadata,
            'ai_analysis': aiAnalysis,
            'status': 'open',
          })
          .select()
          .single();
      
      print('⚠️ Risk uyarısı: $alertType - $severity');
      return response['id'];
    } catch (e) {
      print('❌ Risk uyarısı oluşturma hatası: $e');
      return null;
    }
  }

  /// Sipariş risk kontrolü
  static Future<Map<String, dynamic>> checkOrderRisk({
    required String userId,
    required String orderId,
    required double amount,
    String? deliveryAddress,
  }) async {
    final risks = <String>[];
    String severity = 'low';
    Map<String, dynamic> analysis = {};

    try {
      // 1. Son 24 saatte aynı kullanıcıdan kaç sipariş?
      final recentOrders = await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select()
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(Duration(hours: 24)).toIso8601String());

      if (recentOrders.length > 10) {
        risks.add('Son 24 saatte ${recentOrders.length} sipariş');
        severity = 'high';
      } else if (recentOrders.length > 5) {
        risks.add('Son 24 saatte ${recentOrders.length} sipariş');
        severity = 'medium';
      }

      // 2. Yüksek tutarlı sipariş?
      if (amount > 1000) {
        risks.add('Yüksek tutar: $amount TL');
        if (severity == 'low') severity = 'medium';
      }

      // 3. İptal edilen siparişler
      final cancelledOrders = await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select()
          .eq('user_id', userId)
          .eq('status', 'cancelled')
          .gte('created_at', DateTime.now().subtract(Duration(days: 30)).toIso8601String());

      if (cancelledOrders.length > 5) {
        risks.add('Son 30 günde ${cancelledOrders.length} iptal');
        severity = 'high';
      }

      // 4. Başarısız ödemeler
      final failedPayments = await _supabase
          .from(SupabaseConfig.TABLE_PAYMENT_TRANSACTIONS)
          .select()
          .eq('user_id', userId)
          .eq('status', 'failed')
          .gte('created_at', DateTime.now().subtract(Duration(days: 7)).toIso8601String());

      if (failedPayments.length > 3) {
        risks.add('Son 7 günde ${failedPayments.length} başarısız ödeme');
        if (severity != 'high') severity = 'medium';
      }

      analysis = {
        'total_orders_24h': recentOrders.length,
        'cancelled_orders_30d': cancelledOrders.length,
        'failed_payments_7d': failedPayments.length,
        'amount': amount,
      };

      // Risk uyarısı oluştur
      if (risks.isNotEmpty && severity != 'low') {
        await createAlert(
          alertType: 'suspicious_order',
          severity: severity,
          userId: userId,
          orderId: orderId,
          description: risks.join(', '),
          metadata: analysis,
          aiAnalysis: _generateRiskAnalysis(risks, analysis),
        );
      }

      return {
        'is_risky': risks.isNotEmpty,
        'severity': severity,
        'risks': risks,
        'analysis': analysis,
        'should_block': severity == 'critical',
        'should_review': severity == 'high',
      };
    } catch (e) {
      print('❌ Risk kontrolü hatası: $e');
      return {
        'is_risky': false,
        'severity': 'low',
        'risks': [],
        'analysis': {},
      };
    }
  }

  /// Merchant risk kontrolü
  static Future<Map<String, dynamic>> checkMerchantRisk(String merchantId) async {
    final risks = <String>[];
    String severity = 'low';

    try {
      // 1. İade oranı kontrolü
      final allOrders = await _supabase
          .from(SupabaseConfig.TABLE_ORDERS)
          .select()
          .eq('restaurant_id', merchantId)
          .gte('created_at', DateTime.now().subtract(Duration(days: 30)).toIso8601String());

      final refundedOrders = allOrders.where((o) => 
        o['status'] == 'cancelled' || o['status'] == 'refunded').length;

      final refundRate = allOrders.isNotEmpty ? 
        (refundedOrders / allOrders.length * 100) : 0.0;

      if (refundRate > 30) {
        risks.add('Yüksek iade oranı: ${refundRate.toStringAsFixed(1)}%');
        severity = 'high';
      } else if (refundRate > 20) {
        risks.add('Orta iade oranı: ${refundRate.toStringAsFixed(1)}%');
        severity = 'medium';
      }

      // 2. Müşteri şikayetleri kontrolü (ileride eklenebilir)
      // platformOrders tablosundan şikayet verileri çekilebilir

      // Risk uyarısı oluştur
      if (risks.isNotEmpty && severity != 'low') {
        await createAlert(
          alertType: 'high_refund_rate',
          severity: severity,
          userId: merchantId,
          description: risks.join(', '),
          metadata: {
            'total_orders': allOrders.length,
            'refunded_orders': refundedOrders,
            'refund_rate': refundRate,
          },
        );
      }

      return {
        'is_risky': risks.isNotEmpty,
        'severity': severity,
        'risks': risks,
        'refund_rate': refundRate,
        'total_orders': allOrders.length,
      };
    } catch (e) {
      print('❌ Merchant risk kontrolü hatası: $e');
      return {
        'is_risky': false,
        'severity': 'low',
        'risks': [],
      };
    }
  }

  // ============================================
  // UYARI YÖNETİMİ
  // ============================================

  /// Açık uyarıları getir
  static Future<List<Map<String, dynamic>>> getOpenAlerts({
    String? severity,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConfig.TABLE_RISK_ALERTS)
          .select()
          .eq('status', 'open');

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Uyarı getirme hatası: $e');
      return [];
    }
  }

  /// Uyarıyı çöz
  static Future<bool> resolveAlert({
    required String alertId,
    String? resolvedBy,
    String? resolution,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_RISK_ALERTS)
          .update({
            'status': 'resolved',
            'resolved_by': resolvedBy,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution': resolution,
          })
          .eq('id', alertId);
      
      print('✅ Uyarı çözüldü');
      return true;
    } catch (e) {
      print('❌ Uyarı çözme hatası: $e');
      return false;
    }
  }

  /// Kullanıcının risk geçmişi
  static Future<List<Map<String, dynamic>>> getUserAlerts(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_RISK_ALERTS)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Kullanıcı uyarıları getirme hatası: $e');
      return [];
    }
  }

  // ============================================
  // YARDIMCI FONKSİYONLAR
  // ============================================

  static String _generateRiskAnalysis(List<String> risks, Map<String, dynamic> data) {
    if (risks.isEmpty) return 'Risk tespit edilmedi';

    final analysis = StringBuffer('Risk Analizi:\n');
    for (var risk in risks) {
      analysis.writeln('- $risk');
    }

    if (data['total_orders_24h'] != null && data['total_orders_24h'] > 5) {
      analysis.writeln('\nÖneri: Kullanıcının sipariş geçmişini inceleyin.');
    }

    if (data['failed_payments_7d'] != null && data['failed_payments_7d'] > 2) {
      analysis.writeln('Öneri: Ödeme yöntemini doğrulayın.');
    }

    return analysis.toString();
  }
}
