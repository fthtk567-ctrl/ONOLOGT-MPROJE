import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Ödeme Servisi
/// İyzico, PayTR, Param entegrasyonları için Supabase backend
class SupabasePaymentService {
  static final _supabase = Supabase.instance.client;

  // ============================================
  // ÖDEME İŞLEMLERİ
  // ============================================

  /// Ödeme işlemi kaydet
  static Future<String?> createTransaction({
    required String transactionId,
    required String paymentProvider, // 'iyzico', 'paytr', 'param'
    required String userId,
    String? orderId,
    required double amount,
    String currency = 'TRY',
    String status = 'pending',
    String? paymentMethod,
    Map<String, dynamic>? providerResponse,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_PAYMENT_TRANSACTIONS)
          .insert({
            'transaction_id': transactionId,
            'payment_provider': paymentProvider,
            'user_id': userId,
            'order_id': orderId,
            'amount': amount,
            'currency': currency,
            'status': status,
            'payment_method': paymentMethod,
            'provider_response': providerResponse,
          })
          .select()
          .single();
      
      print('✅ Ödeme işlemi kaydedildi: $transactionId');
      return response['id'];
    } catch (e) {
      print('❌ Ödeme kaydetme hatası: $e');
      return null;
    }
  }

  /// Ödeme durumunu güncelle
  static Future<bool> updateTransactionStatus({
    required String transactionId,
    required String status, // 'success', 'failed', 'refunded'
    String? errorMessage,
    Map<String, dynamic>? providerResponse,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.TABLE_PAYMENT_TRANSACTIONS)
          .update({
            'status': status,
            'error_message': errorMessage,
            'provider_response': providerResponse,
            'completed_at': status == 'success' ? DateTime.now().toIso8601String() : null,
          })
          .eq('transaction_id', transactionId);
      
      print('✅ Ödeme durumu güncellendi: $status');
      return true;
    } catch (e) {
      print('❌ Ödeme durum güncelleme hatası: $e');
      return false;
    }
  }

  /// Kullanıcının ödeme geçmişi
  static Future<List<Map<String, dynamic>>> getUserTransactions({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.TABLE_PAYMENT_TRANSACTIONS)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Ödeme geçmişi getirme hatası: $e');
      return [];
    }
  }

  // ============================================
  // MERCHANT CÜZDAN YÖNETİMİ
  // ============================================

  /// Merchant cüzdanını oluştur veya getir
  static Future<Map<String, dynamic>?> getOrCreateWallet(String merchantId) async {
    try {
      // Önce mevcut cüzdanı kontrol et
      try {
        final existing = await _supabase
            .from(SupabaseConfig.TABLE_MERCHANT_WALLETS)
            .select()
            .eq('merchant_id', merchantId)
            .single();
        return existing;
      } catch (_) {
        // Cüzdan yoksa oluştur
        final newWallet = await _supabase
            .from(SupabaseConfig.TABLE_MERCHANT_WALLETS)
            .insert({
              'merchant_id': merchantId,
              'balance': 0.00,
              'pending_balance': 0.00,
              'total_earnings': 0.00,
              'total_withdrawn': 0.00,
            })
            .select()
            .single();
        
        print('✅ Yeni cüzdan oluşturuldu');
        return newWallet;
      }
    } catch (e) {
      print('❌ Cüzdan getirme/oluşturma hatası: $e');
      return null;
    }
  }

  /// Cüzdana para ekle (sipariş ödemesi)
  static Future<bool> addToWallet({
    required String merchantId,
    required double amount,
    required String type, // 'order_payment', 'refund'
    String? description,
    String? relatedOrderId,
  }) async {
    try {
      final wallet = await getOrCreateWallet(merchantId);
      if (wallet == null) return false;

      final newBalance = (wallet['balance'] ?? 0.0) + amount;
      
      // Cüzdan bakiyesini güncelle
      await _supabase
          .from(SupabaseConfig.TABLE_MERCHANT_WALLETS)
          .update({
            'balance': newBalance,
            'total_earnings': (wallet['total_earnings'] ?? 0.0) + amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('merchant_id', merchantId);

      // İşlem kaydı oluştur
      await _supabase.from(SupabaseConfig.TABLE_WALLET_TRANSACTIONS).insert({
        'wallet_id': wallet['id'],
        'type': type,
        'amount': amount,
        'balance_after': newBalance,
        'description': description,
        'related_order_id': relatedOrderId,
      });

      print('✅ Cüzdana $amount TL eklendi');
      return true;
    } catch (e) {
      print('❌ Cüzdan güncelleme hatası: $e');
      return false;
    }
  }

  /// Cüzdandan para çek
  static Future<bool> withdrawFromWallet({
    required String merchantId,
    required double amount,
    String? description,
  }) async {
    try {
      final wallet = await getOrCreateWallet(merchantId);
      if (wallet == null) return false;

      final currentBalance = wallet['balance'] ?? 0.0;
      if (currentBalance < amount) {
        print('❌ Yetersiz bakiye');
        return false;
      }

      final newBalance = currentBalance - amount;
      
      // Cüzdan bakiyesini güncelle
      await _supabase
          .from(SupabaseConfig.TABLE_MERCHANT_WALLETS)
          .update({
            'balance': newBalance,
            'total_withdrawn': (wallet['total_withdrawn'] ?? 0.0) + amount,
            'last_payout_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('merchant_id', merchantId);

      // İşlem kaydı oluştur
      await _supabase.from(SupabaseConfig.TABLE_WALLET_TRANSACTIONS).insert({
        'wallet_id': wallet['id'],
        'type': 'withdrawal',
        'amount': -amount,
        'balance_after': newBalance,
        'description': description,
      });

      print('✅ Cüzdandan $amount TL çekildi');
      return true;
    } catch (e) {
      print('❌ Para çekme hatası: $e');
      return false;
    }
  }

  /// Cüzdan işlem geçmişi
  static Future<List<Map<String, dynamic>>> getWalletTransactions({
    required String merchantId,
    int limit = 100,
  }) async {
    try {
      final wallet = await getOrCreateWallet(merchantId);
      if (wallet == null) return [];

      final response = await _supabase
          .from(SupabaseConfig.TABLE_WALLET_TRANSACTIONS)
          .select()
          .eq('wallet_id', wallet['id'])
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ İşlem geçmişi getirme hatası: $e');
      return [];
    }
  }

  // ============================================
  // KOMİSYON YÖNETİMİ
  // ============================================

  /// Komisyon hesapla
  static Future<double> calculateCommission({
    required double orderAmount,
    String? merchantId,
    String? platform,
  }) async {
    try {
      // Önce merchant'a özel komisyon ayarı var mı?
      if (merchantId != null) {
        final merchantConfig = await _supabase
            .from(SupabaseConfig.TABLE_COMMISSION_CONFIGS)
            .select()
            .eq('merchant_id', merchantId)
            .eq('is_active', true)
            .maybeSingle();

        if (merchantConfig != null) {
          return _calculateCommissionAmount(
            orderAmount,
            merchantConfig['commission_type'],
            merchantConfig['commission_rate'],
            merchantConfig['min_commission'],
            merchantConfig['max_commission'],
          );
        }
      }

      // Global komisyon ayarını kullan
      final globalConfig = await _supabase
          .from(SupabaseConfig.TABLE_COMMISSION_CONFIGS)
          .select()
          .isFilter('merchant_id', null)
          .eq('is_active', true)
          .maybeSingle();

      if (globalConfig != null) {
        return _calculateCommissionAmount(
          orderAmount,
          globalConfig['commission_type'],
          globalConfig['commission_rate'],
          globalConfig['min_commission'],
          globalConfig['max_commission'],
        );
      }

      // Default: 15%
      return orderAmount * 0.15;
    } catch (e) {
      print('❌ Komisyon hesaplama hatası: $e');
      return orderAmount * 0.15;
    }
  }

  static double _calculateCommissionAmount(
    double amount,
    String type,
    double? rate,
    double? min,
    double? max,
  ) {
    double commission = type == 'percentage' 
        ? (amount * (rate ?? 15.0) / 100)
        : (rate ?? 0.0);

    if (min != null && commission < min) commission = min;
    if (max != null && commission > max) commission = max;

    return commission;
  }
}
