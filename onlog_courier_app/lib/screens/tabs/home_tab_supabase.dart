import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/ultra_modern_order_card.dart'; // 🎨 Ultra modern kart
import '../delivery_details_screen_supabase.dart';
import '../../services/location_service.dart';

/// Kurye Ana Sayfa (Supabase Version)
/// Firebase yerine tamamen Supabase kullanır
class HomeTabSupabase extends StatefulWidget {
  final String courierId;
  final String courierName;

  const HomeTabSupabase({
    super.key,
    required this.courierId,
    required this.courierName,
  });

  @override
  State<HomeTabSupabase> createState() => _HomeTabSupabaseState();
}

class _HomeTabSupabaseState extends State<HomeTabSupabase> {
  bool _isOnline = false;
  bool _isInitialized = false; // İlk yükleme kontrolü
  bool _isLoadingStatus = true; // 🔧 Durum yüklenirken loading göster
  
  @override
  void initState() {
    super.initState();
    _initializeOnce();
  }

  /// SADECE İLK KEZ database'den durum çek
  void _initializeOnce() async {
    if (_isInitialized) {
      print('⏩ Sayfa zaten başlatılmış, database sorgusu atlanıyor');
      return;
    }
    
    print('🔄 İLK BAŞLATMA - Database\'den son durum çekiliyor...');
    
    try {
      // Database'den kurye'nin SON durumunu çek
      final response = await SupabaseService.client
          .from('users')
          .select('is_available')
          .eq('id', widget.courierId)
          .single();
      
      final isAvailableInDB = response['is_available'] ?? false;
      print('📥 Database\'den gelen durum: is_available = $isAvailableInDB');
      
      if (!mounted) return;
      
      setState(() {
        _isOnline = isAvailableInDB;
        _isInitialized = true; // Artık tekrar database sorgusu yok
        _isLoadingStatus = false; // 🔧 Yükleme bitti
      });
      
      // Global LocationService'i database durumu ile senkronize et
      if (isAvailableInDB) {
        print('🟢 Kullanıcı çevrimiçiydi - LocationService başlatılıyor...');
        
        // GPS kontrolü ekle
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('❌ GPS kapalı - Kullanıcı çevrimiçi olamaz');
          // GPS kapalıysa durumu offline yap
          await SupabaseUserService.updateCourierAvailability(
            courierId: widget.courierId,
            isAvailable: false,
          );
          
          if (!mounted) return;
          
          setState(() {
            _isOnline = false;
          });
          // Kullanıcıya uyarı göster
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              _showGpsRequiredDialog();
            }
          });
          return;
        }
        
        await LocationService.startPersistentLocationService(widget.courierId);
      } else {
        print('🔴 Kullanıcı çevrimdışıydı - LocationService pasif');
        LocationService.setDutyStatus(false);
      }
      
      print('✅ İLK BAŞLATMA TAMAMLANDI - _isOnline: $_isOnline');
    } catch (e) {
      print('❌ Database durumu çekilemedi: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isOnline = false;
        _isLoadingStatus = false; // 🔧 Hata durumunda da yükleme bitti
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    // StreamSubscription cancel kaldırıldı - global LocationService kendi yönetir
    super.dispose();
  }

  // ============================================
  // COURIER STATUS
  // ============================================

  // _loadCourierStatus() metodu tamamen kaldırıldı
  // Artık sadece Global LocationService durumunu okuyoruz
  // Supabase sorgulama sadece manual toggle ile yapılıyor

  Future<void> _toggleOnlineStatus() async {
    print('🔄 Online/Offline toggle başlatıldı - Mevcut durum: $_isOnline');
    final newStatus = !_isOnline;
    print('🎯 Yeni durum: $newStatus');
    
    // Aktif olurken konum izni kontrolü
    if (newStatus) {
      print('📍 Aktif olma işlemi - konum izni kontrol ediliyor...');
      
      // 1. GPS Servisi Kontrolü (Telefonun GPS'i açık mı?)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ GPS servisi kapalı');
        _showGpsRequiredDialog();
        return;
      }
      print('✅ GPS servisi açık');
      
      // 2. Uygulama İzni Kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        print('❌ Konum izni reddedildi');
        _showError('Konum izni gerekli!');
        return;
      }
      print('✅ Konum izni alındı: $permission');
    }

    print('🔄 Supabase\'de durum güncelleniyor...');
    // Supabase'de durumu güncelle
    final success = await SupabaseUserService.updateCourierAvailability(
      courierId: widget.courierId,
      isAvailable: newStatus,
    );
    print('📥 Supabase güncelleme sonucu: $success');

    if (success) {
      setState(() {
        _isOnline = newStatus;
      });
      print('✅ UI durumu güncellendi - _isOnline: $_isOnline');

      if (newStatus) {
        print('🔍 Aktif olmaya geçiş - Global LocationService başlatılıyor...');
        final locationSuccess = await LocationService.startPersistentLocationService(widget.courierId);
        print('✅ Global LocationService başlatma sonucu: $locationSuccess');
        _showSuccess('Çevrimiçi oldunuz!');
      } else {
        print('🔍 Pasif olmaya geçiş - Global LocationService durduruluyor...');
        LocationService.setDutyStatus(false);
        print('✅ Global LocationService durduruldu');
        _showSuccess('Çevrimdışı oldunuz');
      }
    } else {
      print('❌ Supabase güncelleme başarısız');
      _showError('Durum güncellenemedi');
    }
    
    print('🏁 Online/Offline toggle tamamlandı');
  }

  // ============================================
  // LOCATION UPDATES
  // ============================================

  // Eski location metodları kaldırıldı - artık global LocationService kullanılıyor

  // ============================================
  // UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: _isOnline
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Teslimatlarım',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _isOnline ? 'Aktif - Siparişler geliyor' : 'Çevrimdışı',
              style: TextStyle(
                fontSize: 11,
                color: _isOnline ? Colors.green[700] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(maxWidth: 120), // Overflow önleme
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isOnline ? Colors.green[200]! : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _isOnline ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isOnline ? Colors.green[700] : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.8, // Switch boyutunu küçült
                  child: Switch(
                    value: _isOnline,
                    onChanged: _isLoadingStatus ? null : (_) => _toggleOnlineStatus(), // 🔧 Loading sırasında disabled
                    activeThumbColor: Colors.green,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoadingStatus 
        ? const Center(child: CircularProgressIndicator()) // 🔧 Loading durumu
        : (_isOnline ? _buildOnlineView() : _buildOfflineView()),
    );
  }

  Widget _buildOfflineView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[100]!, Colors.grey[50]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.power_settings_new,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Çevrimdışısınız',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sipariş almak için çevrimiçi olmanız gerekiyor',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _toggleOnlineStatus,
                icon: const Icon(Icons.power_settings_new, size: 24),
                label: const Text(
                  'Çevrimiçi Ol',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 350), // Genişlik sınırı
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Çevrimiçi olduğunuzda yeni siparişler size ulaşacak',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildOnlineView() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Listeyi yenile
      },
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.client
            .from('delivery_requests')
            .stream(primaryKey: ['id'])
            .eq('courier_id', widget.courierId)
            .order('created_at', ascending: false),
        builder: (context, myOrdersSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.client
                .from('delivery_requests')
                .stream(primaryKey: ['id'])
                .eq('status', 'pending')
                .order('created_at', ascending: false),
            builder: (context, pendingSnapshot) {
              if (myOrdersSnapshot.connectionState == ConnectionState.waiting ||
                  pendingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (myOrdersSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Hata: ${myOrdersSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Yeniden Dene'),
                      ),
                    ],
                  ),
                );
              }

              final myActiveOrders = (myOrdersSnapshot.data ?? [])
                  .where((o) => 
                      ['assigned', 'accepted', 'picked_up'].contains(o['status']) &&
                      o['rejected_at'] == null  // ❌ RED EDİLENLERİ GÖSTERME!
                  )
                  .toList();
              final pendingRequests = pendingSnapshot.data ?? [];

              if (myActiveOrders.isEmpty && pendingRequests.isEmpty) {
                return _buildNoOrdersView();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AKTIF SİPARİŞLERİM
                    if (myActiveOrders.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[50]!, Colors.green[100]!.withOpacity(0.3)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Aktif Siparişlerim',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${myActiveOrders.length} sipariş devam ediyor',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${myActiveOrders.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...myActiveOrders.map((order) {
                        return UltraModernOrderCard( // 🎨 Modern kart
                          order: order,
                          onTap: () {
                            // Sipariş detay sayfasına git
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryDetailsScreenSupabase(
                                  orderId: order['id'],
                                  courierId: widget.courierId,
                                ),
                              ),
                            ).then((_) => setState(() {})); // Geri dönünce listeyi yenile
                          },
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // BEKLEYEN ÇAĞRILAR
                    if (pendingRequests.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[50]!, Colors.orange[100]!.withOpacity(0.3)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange[200]!, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Yeni Kurye Çağrıları',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pendingRequests.length} yeni çağrı bekliyor',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${pendingRequests.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...pendingRequests.map((order) {
                        return UltraModernOrderCard( // 🎨 Modern kart
                          order: order,
                          onTap: () => _acceptOrder(order['id']),
                        );
                      }),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delivery_dining,
            size: 100,
            color: Colors.green.shade200,
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz sipariş yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni siparişler burada görünecek',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ORDER ACTIONS
  // ============================================

  Future<void> _acceptOrder(String orderId) async {
    try {
      await SupabaseService.from('delivery_requests')
          .update({
            'status': 'assigned',
            'courier_id': widget.courierId,
            'assigned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      _showSuccess('✅ Sipariş kabul edildi!');
    } catch (e) {
      _showError('❌ Hata: $e');
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showGpsRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamasın
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.gps_off, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'GPS Kapalı!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kurye uygulamasını kullanmak için telefonunuzun GPS\'ini açmanız gerekiyor.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 GPS Nasıl Açılır?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Ekranı yukarıdan aşağı kaydırın\n'
                    '2. "Konum" simgesine dokunun\n'
                    '3. Veya Ayarlar > Konum > GPS Aç',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // GPS ayarlarını aç
              await Geolocator.openLocationSettings();
            },
            child: Text(
              'AYARLARA GİT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // GPS açık mı kontrol et
              bool isEnabled = await Geolocator.isLocationServiceEnabled();
              if (isEnabled) {
                Navigator.pop(context);
                _showSuccess('✅ GPS açık! Şimdi mesaiye başlayabilirsiniz.');
              } else {
                _showError('⚠️ GPS hala kapalı! Lütfen GPS\'i açın.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'GPS AÇTIM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
