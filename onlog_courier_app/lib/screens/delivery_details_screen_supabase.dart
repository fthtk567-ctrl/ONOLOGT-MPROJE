import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'qr_scanner_screen.dart';

class DeliveryDetailsScreenSupabase extends StatefulWidget {
  final String orderId;
  final String courierId;

  const DeliveryDetailsScreenSupabase({
    super.key,
    required this.orderId,
    required this.courierId,
  });

  @override
  State<DeliveryDetailsScreenSupabase> createState() =>
      _DeliveryDetailsScreenSupabaseState();
}

class _DeliveryDetailsScreenSupabaseState
    extends State<DeliveryDetailsScreenSupabase> {
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _merchantData;
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;
  
  // 🔐 QR + GPS Doğrulama
  bool _qrVerified = false;
  bool _gpsVerified = false;
  String? _scannedQrHash;
  Position? _currentPosition;
  File? _deliveryPhoto;
  double? _gpsDistance;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  /// 📞 TELEFON ARAMASI YAP
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Telefon uygulaması açılamadı')),
        );
      }
    }
  }

  /// ❌ TESLİMATI REDDET
  Future<void> _rejectDelivery() async {
    // Ret nedeni seçimi için dialog göster
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teslimatı Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ret nedeninizi seçin:'),
            const SizedBox(height: 16),
            _buildReasonButton(context, '📍 Adres Hatalı/Bulunamıyor'),
            _buildReasonButton(context, '📞 Müşteriye Ulaşılamıyor'),
            _buildReasonButton(context, '⏰ Çok Uzak/Zamanım Yok'),
            _buildReasonButton(context, '📦 Paket Hasarlı'),
            _buildReasonButton(context, '❌ Diğer'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      _confirmAndReject(reason);
    }
  }

  Widget _buildReasonButton(BuildContext context, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[50],
          foregroundColor: Colors.orange[900],
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: () => Navigator.pop(context, reason),
        child: Text(reason),
      ),
    );
  }

  /// ✅ REDDETME ONAYLAMA & İŞLEM
  Future<void> _confirmAndReject(String reason) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Emin misiniz?'),
        content: Text(
          'Bu teslimatı reddetmek istediğinize emin misiniz?\n\n'
          'Sebep: $reason\n\n'
          'Bu işlem geri alınamaz ve performans puanınızı etkileyebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, Reddet'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processRejection(reason);
    }
  }

  /// 🔄 REDDETME İŞLEMİNİ YÜRÜT
  Future<void> _processRejection(String reason) async {
    setState(() => _isUpdating = true);

    try {
      // 1. Teslimat durumunu güncelle
      await SupabaseService.client
          .from('delivery_requests')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'rejected_by': widget.courierId,
            'rejected_at': DateTime.now().toIso8601String(),
            'courier_id': null, // Kuryeyi kaldır
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.orderId);

      // 2. Kurye rejection_count'u artır
      await SupabaseService.client.rpc('increment_courier_rejection', params: {
        'courier_id': widget.courierId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    '✅ Teslimat reddedildi. Sistem yeni kurye arayacak.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context); // Detay sayfasından çık
      }
    } catch (e) {
      print('❌ Reddetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  /// 🚨 SORUN BİLDİR
  Future<void> _reportProblem() async {
    final problem = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Sorun Bildir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ne tür bir sorun yaşıyorsunuz?'),
            const SizedBox(height: 16),
            _buildProblemButton(context, '📍 Adres Yanlış/Eksik'),
            _buildProblemButton(context, '📞 Müşteri Telefonu Çalışmıyor'),
            _buildProblemButton(context, '🏠 Müşteri Evde Yok'),
            _buildProblemButton(context, '📦 Paket Bilgisi Uyuşmuyor'),
            _buildProblemButton(context, '💳 Ödeme Sorunu'),
            _buildProblemButton(context, '🚗 Araç Arızası'),
            _buildProblemButton(context, '🔧 Diğer'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (problem != null && mounted) {
      _submitProblemReport(problem);
    }
  }

  Widget _buildProblemButton(BuildContext context, String problem) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red[900],
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: () => Navigator.pop(context, problem),
        child: Text(problem),
      ),
    );
  }

  /// 📝 SORUN RAPORUNU GÖNDER
  Future<void> _submitProblemReport(String problem) async {
    // Detay notu iste
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detay Ekle (İsteğe Bağlı)'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Sorunu detaylandırın...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Atla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );

    if (note != null) {
      await _saveProblemReport(problem, note);
    }
  }

  Future<void> _saveProblemReport(String problem, String note) async {
    try {
      // Problem raporunu veritabanına kaydet
      await SupabaseService.client.from('delivery_problems').insert({
        'delivery_request_id': widget.orderId,
        'courier_id': widget.courierId,
        'merchant_id': _orderData?['merchant_id'],
        'problem_type': problem,
        'problem_note': note.isEmpty ? null : note,
        'status': 'reported',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sorun bildirildi. Destek ekibi inceleyecek.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Problem raporu kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Sorun bildirilemedi: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Sipariş detaylarını al - PostGIS kolonları GeoJSON olarak çek
      final orderResponse = await SupabaseService.client
          .from('delivery_requests')
          .select('*, pickup_location:pickup_location::json, delivery_location:delivery_location::json')
          .eq('id', widget.orderId);
      
      // Liste dönüyorsa ilk elementi al
      final orderData = (orderResponse as List).isNotEmpty 
          ? (orderResponse as List).first as Map<String, dynamic>
          : <String, dynamic>{};

      // Mağaza bilgilerini al
      final merchantResponse = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', orderData['merchant_id']);
      
      final merchantData = (merchantResponse as List).isNotEmpty
          ? (merchantResponse as List).first as Map<String, dynamic>
          : <String, dynamic>{};

      setState(() {
        _orderData = orderData;
        _merchantData = merchantData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == 'picked_up') {
        updates['picked_up_at'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'delivered') {
        updates['delivered_at'] = DateTime.now().toIso8601String();
        
        // 🆕 Teslim edildiğinde kurye artık müsait
        await SupabaseService.client
            .from('users')
            .update({'is_busy': false})
            .eq('id', widget.courierId);
      }

      await SupabaseService.client
          .from('delivery_requests')
          .update(updates)
          .eq('id', widget.orderId);

      await _loadOrderDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Durum güncellendi: ${_getStatusText(newStatus)}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('❌ UPDATE HATASI: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Güncelleme başarısız: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'assigned':
        return 'Atandı';
      case 'accepted':
        return 'Kabul Edildi';
      case 'picked_up':
        return 'Toplandı';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
      case 'accepted':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'assigned':
      case 'accepted':
        return Icons.assignment_turned_in;
      case 'picked_up':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Hata: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadOrderDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yeniden Dene'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatusTimeline(),
                          const SizedBox(height: 20),
                          _buildAddressSection(),
                          const SizedBox(height: 20),
                          _buildMerchantSection(),
                          const SizedBox(height: 20),
                          _buildPaymentSection(),
                          const SizedBox(height: 20),
                          _buildNotesSection(),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    final status = _orderData?['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: statusColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _orderData?['order_number'] ?? 'ONL-${_orderData?['id']?.toString().substring(0, 8) ?? ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              _getStatusText(status),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor,
                statusColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              _getStatusIcon(status),
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final status = _orderData?['status'] ?? 'pending';
    final createdAt = _orderData?['created_at'];
    final pickedUpAt = _orderData?['picked_up_at'];
    final deliveredAt = _orderData?['delivered_at'];

    final steps = [
      {'status': 'assigned', 'label': 'Kabul Edildi', 'time': createdAt},
      {'status': 'picked_up', 'label': 'Toplandı', 'time': pickedUpAt},
      {'status': 'delivered', 'label': 'Teslim Edildi', 'time': deliveredAt},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teslimat Durumu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final stepStatus = step['status'] as String;
              final isCompleted = _isStatusCompleted(status, stepStatus);
              final isCurrent = status == stepStatus;
              final time = step['time'];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isCurrent
                                  ? Colors.blue
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: isCompleted || isCurrent
                              ? [
                                  BoxShadow(
                                    color: (isCompleted ? Colors.green : Colors.blue)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : isCurrent
                                  ? Icons.radio_button_checked
                                  : Icons.circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (index < steps.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: isCompleted ? Colors.green : Colors.grey[300],
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isCompleted || isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isCompleted || isCurrent
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                          if (time != null)
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(DateTime.parse(time)),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _isStatusCompleted(String currentStatus, String checkStatus) {
    const statusOrder = [
      'pending',
      'assigned',
      'accepted',
      'picked_up',
      'delivered'
    ];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final checkIndex = statusOrder.indexOf(checkStatus);
    return currentIndex >= checkIndex;
  }

  Widget _buildAddressSection() {
    final pickupAddress = _orderData?['pickup_address'] ?? {};
    final deliveryAddress = _orderData?['delivery_address'] ?? {};
    
    // PostGIS pickup_location'dan koordinat çek (GeoJSON formatında geliyor)
    final pickupLocation = _orderData?['pickup_location'];
    Map<String, double>? pickupCoords;
    
    print('🔍 DEBUG pickup_location: $pickupLocation');
    print('🔍 DEBUG pickup_location type: ${pickupLocation.runtimeType}');
    
    if (pickupLocation != null) {
      if (pickupLocation is Map) {
        // Simple JSON format: {"latitude": ..., "longitude": ...}
        if (pickupLocation.containsKey('latitude') && pickupLocation.containsKey('longitude')) {
          pickupCoords = {
            'lat': (pickupLocation['latitude'] as num).toDouble(),
            'lng': (pickupLocation['longitude'] as num).toDouble(),
          };
          print('✅ Pickup coords (simple JSON): $pickupCoords');
        } 
        // GeoJSON format: {"type": "Point", "coordinates": [lng, lat]}
        else if (pickupLocation.containsKey('coordinates')) {
          final coords = pickupLocation['coordinates'];
          pickupCoords = {
            'lat': (coords[1] as num).toDouble(),
            'lng': (coords[0] as num).toDouble(),
          };
          print('✅ Pickup coords (GeoJSON): $pickupCoords');
        }
      } else if (pickupLocation is String) {
        // PostGIS text format: "POINT(lng lat)"
        final regex = RegExp(r'POINT\(([0-9.-]+)\s+([0-9.-]+)\)');
        final match = regex.firstMatch(pickupLocation);
        if (match != null) {
          pickupCoords = {
            'lng': double.parse(match.group(1)!),
            'lat': double.parse(match.group(2)!),
          };
          print('✅ Pickup coords (PostGIS string): $pickupCoords');
        }
      }
    }
    
    // delivery_location'dan koordinat çek
    final deliveryLocation = _orderData?['delivery_location'];
    Map<String, double>? deliveryCoords;
    if (deliveryLocation != null) {
      if (deliveryLocation is Map) {
        // Simple JSON format: {"latitude": ..., "longitude": ...}
        if (deliveryLocation.containsKey('latitude') && deliveryLocation.containsKey('longitude')) {
          deliveryCoords = {
            'lat': (deliveryLocation['latitude'] as num).toDouble(),
            'lng': (deliveryLocation['longitude'] as num).toDouble(),
          };
        }
        // GeoJSON format
        else if (deliveryLocation.containsKey('coordinates')) {
          final coords = deliveryLocation['coordinates'];
          deliveryCoords = {
            'lat': (coords[1] as num).toDouble(),
            'lng': (coords[0] as num).toDouble(),
          };
        }
      } else if (deliveryLocation is String) {
        final regex = RegExp(r'POINT\(([0-9.-]+)\s+([0-9.-]+)\)');
        final match = regex.firstMatch(deliveryLocation);
        if (match != null) {
          deliveryCoords = {
            'lng': double.parse(match.group(1)!),
            'lat': double.parse(match.group(2)!),
          };
        }
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adresler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildAddressCard(
              'Alış Noktası',
              pickupAddress['full_address'] ?? _merchantData?['business_address'] ?? 'Adres bilgisi yok',
              pickupAddress['contact_name'] ?? _merchantData?['business_name'] ?? '',
              pickupAddress['phone'] ?? _merchantData?['business_phone'] ?? '',
              Icons.store,
              Colors.blue,
              coordinates: pickupCoords, // 🔥 KOORDINAT EKLE
            ),
            const SizedBox(height: 16),
            _buildAddressCard(
              'Teslimat Noktası',
              deliveryAddress['full_address'] ?? 'Adres bilgisi yok',
              deliveryAddress['contact_name'] ?? '',
              deliveryAddress['phone'] ?? '',
              Icons.location_on,
              Colors.red,
              coordinates: deliveryCoords, // 🔥 KOORDINAT EKLE
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    String title,
    String address,
    String contactName,
    String phone,
    IconData icon,
    Color color, {
    Map<String, double>? coordinates, // 🔥 YENİ PARAMETRE
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (contactName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            contactName,
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              phone,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone_enabled),
                            iconSize: 20,
                            color: Colors.green,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _makePhoneCall(phone),
                            tooltip: 'Ara',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // 🔥 YOL TARİFİ BUTONU
          if (coordinates != null && coordinates['lat'] != 0.0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(coordinates['lat']!, coordinates['lng']!),
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Yol Tarifi Al'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // 🔥 GOOGLE MAPS YOL TARİFİ
  void _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Harita açılamadı';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harita açılamadı: $e')),
        );
      }
    }
  }

  Widget _buildMerchantSection() {
    final merchantName = _merchantData?['business_name'] ?? 'Bilinmeyen Mağaza';
    final merchantPhone = _merchantData?['phone'] ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mağaza Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (merchantPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          merchantPhone,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                if (merchantPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone),
                    color: Colors.green,
                    onPressed: () => _makePhoneCall(merchantPhone),
                    tooltip: 'Mağazayı Ara',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    final amount = _orderData?['declared_amount'] ?? 0.0;
    final commission = _orderData?['merchant_commission'] ?? 0.0;
    final paymentStatus = _orderData?['payment_status'] ?? 'pending';
    final status = _orderData?['status'] ?? '';
    
    // Teslimat tamamlanmadıysa kazanç henüz hesaplanmamış
    final isDelivered = status == 'delivered';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ödeme Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow('Tutar', '₺${amount.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildPaymentRow(
              'Kazanç',
              isDelivered 
                ? '₺${commission.toStringAsFixed(2)}'
                : 'Teslimat sonrası hesaplanacak',
              isHighlighted: isDelivered,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: paymentStatus == 'paid'
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    paymentStatus == 'paid'
                        ? Icons.check_circle
                        : Icons.schedule,
                    size: 16,
                    color:
                        paymentStatus == 'paid' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    paymentStatus == 'paid' ? 'Ödendi' : 'Bekliyor',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: paymentStatus == 'paid'
                          ? Colors.green[700]
                          : Colors.orange[700],
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

  Widget _buildPaymentRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: isHighlighted ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    final notes = _orderData?['notes'] ?? '';
    if (notes.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Notlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notes,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _orderData?['status'] ?? 'pending';

    return Column(
      children: [
        // ═══════════════════════════════════════════════════
        // 🔵 STATUS: ASSIGNED (Atandı - Henüz kabul etmedi)
        // ═══════════════════════════════════════════════════
        if (status == 'assigned')
          Column(
            children: [
              // ✅ KABUL ET BUTONU (Yeşil - Büyük)
              _buildActionButton(
                '✓ KABUL ET',
                Icons.check_circle,
                Colors.green,
                () => _acceptDelivery(),
              ),
              const SizedBox(height: 12),
              
              // ❌ REDDET BUTONU (Kırmızı - Outlined)
              _buildActionButton(
                '✗ REDDET',
                Icons.cancel_outlined,
                Colors.red,
                () => _showRejectDialog(),
                isOutlined: true,
              ),
            ],
          ),
        
        // ═══════════════════════════════════════════════════
        // 🟢 STATUS: ACCEPTED (Kabul etti - Paketi almadı)
        // ═══════════════════════════════════════════════════
        if (status == 'accepted')
          Column(
            children: [
              _buildActionButton(
                '📦 Toplandı Olarak İşaretle',
                Icons.shopping_bag,
                Colors.blue,
                () => _updateOrderStatus('picked_up'),
              ),
              const SizedBox(height: 12),
              
              // 🚨 SORUN BİLDİR BUTONU
              _buildActionButton(
                '🚨 Sorun Bildir',
                Icons.report_problem,
                Colors.orange,
                () => _reportProblem(),
                isOutlined: true,
              ),
              const SizedBox(height: 12),
              
              // ⚠️ İPTAL (Uyarılı - Ceza riski var!)
              TextButton.icon(
                onPressed: () => _showCancelWithPenaltyDialog(),
                icon: const Icon(Icons.warning, color: Colors.orange),
                label: const Text(
                  'İptal Et (Ceza Uygulanabilir)',
                  style: TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ),
            ],
          ),
        
        // ═══════════════════════════════════════════════════
        // 🟡 STATUS: PICKED_UP (Paket alındı - Teslimatta)
        // ═══════════════════════════════════════════════════
        if (status == 'picked_up')
          Column(
            children: [
              //  FOTOĞRAF ÇEK BUTONU
              if (_deliveryPhoto == null) ...[
                _buildActionButton(
                  'Teslimat Fotoğrafı Çek (Zorunlu)',
                  Icons.camera_alt,
                  Colors.orange,
                  _takeDeliveryPhoto,
                ),
                const SizedBox(height: 12),
              ],
              
              // ✅ Fotoğraf çekildi işareti
              if (_deliveryPhoto != null) ...[
                _buildVerificationStatus(
                  '✓ Fotoğraf Çekildi',
                  Colors.green,
                  Icons.check_circle,
                ),
                const SizedBox(height: 12),
              ],
              
              // ✅ TESLİM ET BUTONU (Sadece fotoğraf zorunlu)
              _buildActionButton(
                'Teslim Edildi Olarak İşaretle',
                Icons.flag,
                _deliveryPhoto != null ? Colors.green : Colors.grey,
                _deliveryPhoto != null ? () => _updateOrderStatus('delivered') : null,
              ),
              const SizedBox(height: 12),
              
              // 🚨 SORUN BİLDİR BUTONU
              _buildActionButton(
                '🚨 Sorun Bildir',
                Icons.report_problem,
                Colors.orange,
                () => _reportProblem(),
                isOutlined: true,
              ),
              
              // ⚠️ PAKET ALINDIKTAN SONRA İPTAL İMKANSIZ!
              // (Kurye paketi teslim etmek ZORUNDA - İade senaryosu farklı)
            ],
          ),
      ],
    );
  }
  
  // 🔐 Doğrulama durumu göster
  Widget _buildVerificationStatus(String text, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 📱 QR KOD TARAMA
  Future<void> _scanQrCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );
    
    if (result != null) {
      await _verifyQrCode(result);
    }
  }
  
  // ✅ QR KOD DOĞRULA
  Future<void> _verifyQrCode(String scannedData) async {
    setState(() => _isUpdating = true);
    
    try {
      // QR'dan gelen veri: "orderId|amount|hash" formatında olmalı
      final parts = scannedData.split('|');
      if (parts.length != 3) {
        throw 'Geçersiz QR kod formatı';
      }
      
      final orderId = parts[0];
      // final amount = parts[1]; // Gelecekte kullanılabilir
      final hash = parts[2];
      
      // Sipariş ID eşleşiyor mu?
      if (orderId != widget.orderId) {
        throw 'Bu QR kod başka bir siparişe ait!';
      }
      
      // Backend'de hash doğrula
      final response = await SupabaseService.client
          .rpc('verify_qr_code', params: {
        'p_order_id': orderId,  // QR'dan gelen order ID'yi kullan
        'p_scanned_hash': hash,
      });
      
      final isValid = response[0]['is_valid'] as bool;
      final message = response[0]['message'] as String;
      
      if (isValid) {
        setState(() {
          _qrVerified = true;
          _scannedQrHash = hash;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw message;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Doğrulama Hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }
  
  // 📸 TESLİMAT FOTOĞRAFI ÇEK
  Future<void> _takeDeliveryPhoto() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (photo != null) {
        setState(() {
          _deliveryPhoto = File(photo.path);
        });
        
        // 📤 SUPABASE STORAGE'A YÜKLE
        try {
          final fileName = '${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          // Upload to Supabase Storage
          await SupabaseService.client.storage
              .from('delivery-photos')
              .upload(fileName, File(photo.path));
          
          // Get public URL
          final photoUrl = SupabaseService.client.storage
              .from('delivery-photos')
              .getPublicUrl(fileName);
          
          // Save URL to database
          await SupabaseService.client
              .from('delivery_requests')
              .update({'delivery_photo_url': photoUrl})
              .eq('id', widget.orderId);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Fotoğraf yüklendi ve kaydedildi'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fotoğraf yükleme hatası: $uploadError'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // ✅ TESLİMATI TAMAMLA (QR + GPS + Fotoğraf ile)
  Future<void> _completeDeliveryWithVerification() async {
    if (!_qrVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Önce QR kodu taratmalısınız!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_deliveryPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Önce teslimat fotoğrafı çekmelisiniz!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isUpdating = true);
    
    try {
      // 1. Mevcut GPS konumunu al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() => _currentPosition = position);
      
      // 2. GPS doğrula (backend'de merchant lokasyonu ile karşılaştır)
      final gpsResponse = await SupabaseService.client
          .rpc('verify_gps_location', params: {
        'p_order_id': widget.orderId,
        'p_delivery_lat': position.latitude,
        'p_delivery_lng': position.longitude,
      });
      
      final gpsValid = gpsResponse[0]['is_valid'] as bool;
      final distance = gpsResponse[0]['distance_meters'] as num;
      final gpsMessage = gpsResponse[0]['message'] as String;
      
      setState(() {
        _gpsVerified = gpsValid;
        _gpsDistance = distance.toDouble();
      });
      
      // 3. Fotoğrafı Supabase Storage'a yükle (simüle - gerçek uygulamada upload yapılır)
      final photoUrl = 'delivery_photos/${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // TODO: Supabase Storage'a upload
      
      // 4. Teslimatı tamamla
      final completionResponse = await SupabaseService.client
          .rpc('complete_delivery_with_verification', params: {
        'p_order_id': widget.orderId,
        'p_courier_id': widget.courierId,
        'p_delivery_lat': position.latitude,
        'p_delivery_lng': position.longitude,
        'p_photo_url': photoUrl,
      });
      
      final success = completionResponse[0]['success'] as bool;
      final message = completionResponse[0]['message'] as String;
      final requiresApproval = completionResponse[0]['requires_admin_approval'] as bool;
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Detayları yenile
          await _loadOrderDetails();
        } else if (requiresApproval) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text('Admin Onayı Gerekli'),
                ],
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        } else {
          throw message;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teslimat tamamlama hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: _isUpdating ? null : onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: _isUpdating || onPressed == null ? null : onPressed,
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(icon),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: onPressed == null ? Colors.grey : color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════
  // ✅ KABUL ET FONKSİYONU (assigned → accepted)
  // ═══════════════════════════════════════════════════
  Future<void> _acceptDelivery() async {
    setState(() => _isUpdating = true);
    
    try {
      await SupabaseService.client
          .from('delivery_requests')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.orderId);
      
      // 🆕 Kurye meşgul olarak işaretle
      await SupabaseService.client
          .from('users')
          .update({'is_busy': true})
          .eq('id', widget.courierId);
      
      await _loadOrderDetails();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    '✅ Teslimat kabul edildi! Mağazaya gidebilirsiniz.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Kabul işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }
  
  // ═══════════════════════════════════════════════════
  // ❌ REDDET FONKSİYONU (assigned → rejected → başka kuryeye gider)
  // ═══════════════════════════════════════════════════
  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Teslimatı Reddet'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu teslimatı reddetmek istediğinizden emin misiniz?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Red nedenleri:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('• Çok uzak\n• Meşgulüm\n• Yanlış atandım\n• Diğer nedenler'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectDelivery();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════
  // ⚠️ CEZA RİSKLİ İPTAL (accepted → cancelled)
  // ═══════════════════════════════════════════════════
  void _showCancelWithPenaltyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Dikkat!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ CEZA RİSKİ VAR!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Bu teslimatı zaten kabul ettiniz. İptal ederseniz:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '❌ 10 dakika yeni iş alamazsınız\n'
              '❌ Performans puanınız düşer\n'
              '❌ Merchant memnuniyetsizliği kaydedilir',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
            SizedBox(height: 12),
            Text(
              'Yine de iptal etmek istiyor musunuz?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelWithPenalty();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('İptal Et (Ceza Kabul)'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _cancelWithPenalty() async {
    setState(() => _isUpdating = true);
    
    try {
      // ⛔ Teslimatı iptal et + Kurye ceza al
      await SupabaseService.client
          .from('delivery_requests')
          .update({
            'status': 'cancelled',
            'cancelled_by': widget.courierId,
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancellation_reason': 'courier_cancelled_after_accept',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.orderId);
      
      // 🔴 Kuryeye 10 dakika ceza
      final penaltyUntil = DateTime.now().add(const Duration(minutes: 10));
      await SupabaseService.client
          .from('users')
          .update({
            'penalty_until': penaltyUntil.toIso8601String(),
            'is_available': false, // Geçici olarak devre dışı
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.courierId);
      
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⛔ Teslimat iptal edildi. 10 dakika yeni iş alamazsınız!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ İptal işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }
}
