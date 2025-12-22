import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import '../services/courier_assignment_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallCourierScreen extends StatefulWidget {
  final String merchantId;
  final String merchantName;
  final Map<String, dynamic> merchantLocation;

  const CallCourierScreen({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.merchantLocation,
  });

  @override
  State<CallCourierScreen> createState() => _CallCourierScreenState();
}

class _CallCourierScreenState extends State<CallCourierScreen> {
  int _packageCount = 1;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _incrementPackage() {
    if (_packageCount < 50) {
      setState(() => _packageCount++);
    }
  }

  void _decrementPackage() {
    if (_packageCount > 1) {
      setState(() => _packageCount--);
    }
  }

  Future<void> _callCourier() async {
    // 🔒 DOUBLE-CLICK KORUMASI
    if (_isLoading) return;
    
    // Tutar kontrolü - ZORUNLU!
    if (_amountController.text.trim().isEmpty) {
      _showError('Lütfen toplam tutarı giriniz!');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Geçerli bir tutar giriniz!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔵 KURYE ÇAĞIRILIYOR:');
      print('  merchantId: ${widget.merchantId}');
      print('  merchantName: ${widget.merchantName}');
      print('  merchantLocation: ${widget.merchantLocation}');
      print('  packageCount: $_packageCount');
      print('  declaredAmount: $amount TL');
      print('  notes: ${_notesController.text.trim()}');
      
      // MERCHANT'TAN KOMİSYON AYARLARINI ÇEK
      final merchantData = await SupabaseService.client
          .from('users')
          .select('commission_settings')
          .eq('id', widget.merchantId)
          .single();
      
      // Komisyon ayarları - users.commission_settings JSONB
      // Örnek: {"type": "percentage", "rate": 20.0} veya
      //        {"type": "fixed_per_package", "fixed_amount": 50.0}
      final commissionSettings = merchantData['commission_settings'] as Map<String, dynamic>?;
      
      double merchantCommissionRate;
      double merchantCommission;
      
      if (commissionSettings != null) {
        final type = commissionSettings['type'] ?? 'percentage';
        
        if (type == 'fixed_per_package' || type == 'perOrder') {
          // Paket başı sabit ücret (sanayi/toptan için)
          final fixedAmount = (commissionSettings['fixed_amount'] ?? commissionSettings['per_order_fee'] ?? 50.0).toDouble();
          merchantCommission = fixedAmount * _packageCount;
          merchantCommissionRate = 0.0; // Yüzde değil, sabit tutar
          print('📦 KOMİSYON TİPİ: Paket başı sabit - $fixedAmount TL/paket × $_packageCount paket = $merchantCommission TL');
        } else {
          // Yüzde bazlı komisyon (default - restoran/market için)
          merchantCommissionRate = (commissionSettings['commission_rate'] ?? commissionSettings['rate'] ?? 20.0).toDouble();
          merchantCommission = amount * (merchantCommissionRate / 100);
          print('📊 KOMİSYON TİPİ: Yüzde bazlı - %$merchantCommissionRate × $amount TL = $merchantCommission TL');
        }
      } else {
        // Ayar yoksa default: %20
        merchantCommissionRate = 20.0;
        merchantCommission = amount * 0.20;
        print('⚙️ KOMİSYON TİPİ: Default %20 (commission_settings null)');
      }
      
      // Kurye komisyonu: Esnaf için %18 (default - sonra commission_configs'den çekilebilir)
      final courierCommissionRate = 18.0;
      final courierCommission = amount * (courierCommissionRate / 100);
      final systemCommission = merchantCommission - courierCommission;
      
      print('💰 KOMİSYON HESAPLARI:');
      print('   Toplam Tutar: $amount TL');
      print('   Merchant Ödeyecek: $merchantCommission TL (${merchantCommissionRate > 0 ? "%$merchantCommissionRate" : "Sabit tutar"})');
      print('   Esnaf Kurye Alacak: $courierCommission TL (%$courierCommissionRate)');
      print('   Sistem Kazancı: $systemCommission TL');
      
      // 🤖 OTOMATİK KURYE ATAMASI
      print('\n🤖 OTOMATİK KURYE ATAMASI BAŞLIYOR...');
      final assignedCourierId = await CourierAssignmentService.findBestCourier(
        merchantLocation: widget.merchantLocation,
        merchantId: widget.merchantId, // 🆕 Aynı merchant kurye tercihi
      );
      
      if (assignedCourierId == null) {
        // 50 km içinde müsait kurye yok
        if (!mounted) return;
        _showError(
          'Yakınınızda (50 km içinde) müsait kurye bulunmuyor.\n'
          'Lütfen daha sonra tekrar deneyin veya destek ile iletişime geçin.'
        );
        setState(() => _isLoading = false);
        return;
      }
      
      print('✅ KURYE ATANDI: $assignedCourierId');
      
      // ✅ İŞLETME KONUM BİLGİLERİ (pickup_location - JSONB)
      final pickupLocationJson = jsonEncode({
        'latitude': widget.merchantLocation['lat'],
        'longitude': widget.merchantLocation['lng'],
        'address': widget.merchantLocation['address'] ?? widget.merchantName,
      });
      
      print('📍 pickupLocation (JSONB): $pickupLocationJson');
      
      // DELIVERY REQUEST OLUŞTUR (Courier App görecek!)
      final deliveryData = {
        'merchant_id': widget.merchantId,
        'courier_id': assignedCourierId, // 🔥 OTOMATİK ATANAN COURIER
        'package_count': _packageCount,
        'declared_amount': amount,
        'notes': _notesController.text.trim(),
        
        // ✅ YENİ EKLENENLER (Raporlama & Performans için)
        'merchant_name': widget.merchantName, // ✅ Merchant adı (JOIN gerektirmez)
        'pickup_location': pickupLocationJson, // ✅ İşletme konumu (JSONB)
        
        // delivery_location: NULL - Manuel teslimat, kurye müşteri ile konuşup gidecek
        
        'merchant_commission_rate': merchantCommissionRate,
        'merchant_payment_due': merchantCommission,
        'courier_commission_rate': courierCommissionRate,
        'courier_payment_due': courierCommission,
        'system_commission': systemCommission,
        'status': 'assigned', // 🔥 DİREKT 'assigned' olarak başla
        'created_at': DateTime.now().toIso8601String(),
      };
      
      print('📦 FULL deliveryData:');
      deliveryData.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
      
      final insertedDelivery = await SupabaseService.client
          .from('delivery_requests')
          .insert(deliveryData)
          .select('id')
          .single();
      
      print('✅ DELIVERY REQUEST OLUŞTURULDU!');
      
      // 🔔 KURYE BİLDİRİMİ - Edge Function ile HTTP POST
      try {
        print('📱 FCM bildirimi gönderiliyor...');
        
        // Direkt HTTP POST kullan (Web uyumlu) - TEST FUNCTION
        final url = Uri.parse('https://oilldflywtzbrmpylxx.supabase.co/functions/v1/send-notification-v2');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pbGxkZmx5d3R6YnJtcHlseHgiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc2MDY3MjgyOSwiZXhwIjoyMDc2MjQ4ODI5fQ.kwTQgWja1VJBNA4sXEbznmv9LMoyO_5rioaTaQXvKsM',
        };
        final body = {
          'userId': assignedCourierId,
          'title': 'Yeni Teslimat!',
          'body': 'Yeni bir teslimat talebiniz var',
          'icon': 'ic_stat_courier_app_icon', // 🔔 Notification icon
          'data': {
            'deliveryId': insertedDelivery['id'].toString(),
            'type': 'delivery',
          }
        };
        
        final response = await http.post(
          url,
          headers: headers,
          body: json.encode(body),
        );
        
        print('📤 Response status: ${response.statusCode}');
        print('📤 Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          print('✅ FCM bildirimi başarıyla gönderildi!');
        } else {
          print('⚠️ FCM bildirimi hatası: ${response.body}');
        }
      } catch (e) {
        print('❌ FCM bildirimi gönderilemedi: $e');
        // Hata olsa bile devam et - teslimat oluşturuldu
      }
      
      // Finansal işlem kaydı da oluştur (opsiyonel - raporlama için)
      try {
        await SupabaseService.client
            .from('financial_transactions')
            .insert({
          'user_id': widget.merchantId,
          'amount': merchantCommission,
          'type': 'merchant_commission_pending',
          'description': 'Kurye çağrısı - $_packageCount paket - $amount TL (Komisyon: %20)',
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ Finansal işlem kaydı oluşturuldu');
      } catch (e) {
        print('⚠️ Finansal işlem kaydı hatası: $e');
        // Hata olsa bile devam et
      }

      if (!mounted) return;
      
      // Başarı mesajı - BASİT
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 32),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Kurye Çağrısı Gönderildi!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📦 Paket Sayısı: $_packageCount', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('💰 Toplam Tutar: ${amount.toStringAsFixed(2)} TL', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sistem size en yakın ve en uygun kuryeleri otomatik olarak atadı. Kurye şu anda yola çıkıyor!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dialog kapat
                Navigator.pop(context); // Screen kapat
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('❌ HATA: $e');
      print('❌ StackTrace: $stackTrace');
      if (!mounted) return;
      _showError('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Uyarı'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🚴 Kurye Çağır'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Konum Bilgisi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Teslimat Konumu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.merchantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.merchantLocation['address'] ?? 'Adres bilgisi yok',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Paket Sayısı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Paket Sayısı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Azalt Butonu
                      IconButton(
                        onPressed: _decrementPackage,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 48,
                        color: _packageCount > 1 ? Colors.red : Colors.grey,
                      ),
                      
                      // Sayı Gösterimi
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!, width: 2),
                        ),
                        child: Text(
                          '$_packageCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      
                      // Arttır Butonu
                      IconButton(
                        onPressed: _incrementPackage,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 48,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paket',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tutar - ZORUNLU!
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Toplam Tutar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ZORUNLU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₺ ',
                      prefixStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.blue[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow[700]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.yellow[900]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kurye alacağı tutarı girmeyi unutmayın!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.yellow[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notlar (Opsiyonel)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note_outlined, color: Colors.purple[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Notlar (Opsiyonel)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Örn: Kırılabilir ürün var, dikkatli taşınsın',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Kurye Çağır Butonu
            ElevatedButton(
              onPressed: _isLoading ? null : _callCourier,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delivery_dining, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'KURYE ÇAĞIR - $_packageCount PAKET',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
