import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';

/// İnteraktif Harita Konumu Seçme Widget'ı
/// Pin sürükleyerek konum seçebilir, adres otomatik doldurulur
class LocationPickerMap extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng location, String address, Map<String, dynamic>? addressComponents) onLocationSelected;

  const LocationPickerMap({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late LatLng _selectedLocation;
  late MapController _mapController;
  String _address = 'Konum seçiliyor...';
  bool _isLoadingAddress = false;
  Timer? _debounceTimer; // Debounce için timer

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _mapController = MapController();
    _getAddressFromLatLng(_selectedLocation);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Timer'ı temizle
    super.dispose();
  }

  /// Koordinatlardan adres bilgisi al (Nominatim API - Web uyumlu)
  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    
    try {
      // Nominatim API ile reverse geocoding (Web'de çalışır!)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'format=json&'
        'lat=${location.latitude}&'
        'lon=${location.longitude}&'
        'zoom=18&'
        'addressdetails=1&'
        'accept-language=tr' // Türkçe yanıt
      );

      debugPrint('🌍 Adres API isteği: $url');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'OnlogMerchantPanel/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📡 API Yanıt kodu: ${response.statusCode}');
      debugPrint('📄 API Yanıt: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Adres bilgisini al (güvenli)
        String address = '';
        Map<String, dynamic>? addressComponents;
        
        if (data.containsKey('display_name')) {
          address = data['display_name'] as String;
        }
        
        // Adres componentlerini al (il, ilçe, posta kodu vs.)
        if (data.containsKey('address')) {
          final addr = data['address'] as Map<String, dynamic>;
          addressComponents = {
            'city': addr['province'] ?? addr['city'] ?? addr['state'] ?? '', // İl
            'district': addr['town'] ?? addr['suburb'] ?? addr['county'] ?? '', // İlçe
            'postalCode': addr['postcode'] ?? '', // Posta kodu
            'road': addr['road'] ?? '',
            'neighbourhood': addr['neighbourhood'] ?? addr['suburb'] ?? '',
          };
          
          // Eğer address boşsa, parçalardan oluştur
          if (address.isEmpty) {
            final parts = <String>[];
            if (addr.containsKey('road')) parts.add(addr['road'] as String);
            if (addr.containsKey('suburb')) parts.add(addr['suburb'] as String);
            if (addr.containsKey('town')) parts.add(addr['town'] as String);
            if (addr.containsKey('province')) parts.add(addr['province'] as String);
            address = parts.join(', ');
          }
        }
        
        if (address.isEmpty) {
          address = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        }

        setState(() {
          _address = address;
          _isLoadingAddress = false;
        });

        debugPrint('✅ Adres bulundu: $address');
        debugPrint('📍 İl: ${addressComponents?['city']}, İlçe: ${addressComponents?['district']}');
        
        // Callback ile parent'a bildir (artık address components da var!)
        widget.onLocationSelected(location, address, addressComponents);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('❌ Adres alma hatası: $e');
      debugPrint('Stack: $stack');
      
      setState(() {
        _address = 'Konum: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
      
      // Yine de koordinatları gönder
      widget.onLocationSelected(location, _address, null);
    }
  }

  /// Haritada tıklanan noktayı işle
  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() => _selectedLocation = location);
    _getAddressFromLatLng(location);
  }

  /// Web için GPS konumu al (Geolocator paketi ile)
  Future<Map<String, double>?> _getCurrentPosition() async {
    try {
      // Konum izni kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Konum izni reddedildi');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Konum izni kalıcı olarak reddedildi');
        return null;
      }
      
      // Mevcut konumu al (web'de çalışır)
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      debugPrint('❌ Konum alma hatası: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 🗺️ Harita (onMapEvent ile merkez takibi)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15.0,
                onTap: _onMapTap,
                onMapEvent: (MapEvent event) {
                  // Harita hareket ettiğinde merkezi güncelle
                  if (event is MapEventMove || event is MapEventMoveEnd) {
                    final center = _mapController.camera.center;
                    
                    // Merkez değişti mi?
                    if ((_selectedLocation.latitude - center.latitude).abs() > 0.0001 ||
                        (_selectedLocation.longitude - center.longitude).abs() > 0.0001) {
                      
                      setState(() => _selectedLocation = center);
                      
                      // Sadece hareket BİTTİĞİNDE adres al (debounce ile)
                      if (event is MapEventMoveEnd) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                          _getAddressFromLatLng(center);
                        });
                      }
                    }
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // OpenStreetMap katmanı
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.onlog.merchant_panel',
                ),
              ],
            ),

            // 📍 SABİT ORTA PİN (harita altında, her zaman merkezde)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.red,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  // Pin'in ucunu göster
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            // 📍 Üstte adres bilgisi kartı
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Seçili Konum',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoadingAddress)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 💡 Altta kullanım talimatı
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pan_tool, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Haritayı kaydırarak tam konumunuzu belirleyin',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🎯 Mevcut konumumu bul butonu
            Positioned(
              bottom: 80,
              right: 16,
              child: Column(
                children: [
                  // GPS ile gerçek konumu al
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    heroTag: 'gps_location',
                    onPressed: () async {
                      try {
                        // Web'de Geolocation API kullan
                        debugPrint('📍 GPS konumu alınıyor...');
                        
                        // Browser geolocation API
                        final position = await _getCurrentPosition();
                        
                        if (position != null) {
                          final newLocation = LatLng(position['latitude']!, position['longitude']!);
                          setState(() => _selectedLocation = newLocation);
                          _mapController.move(newLocation, 18.0);
                          _getAddressFromLatLng(newLocation);
                          
                          debugPrint('✅ GPS konumu bulundu: ${position['latitude']}, ${position['longitude']}');
                          
                          // Kullanıcıya bilgi
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📍 Konumunuz bulundu!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ GPS hatası: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Konum izni gerekli veya bulunamadı'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  // Seçili konuma dön
                  FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    heroTag: 'center_location',
                    onPressed: () {
                      _mapController.move(_selectedLocation, 15.0);
                    },
                    child: const Icon(Icons.center_focus_strong, color: Colors.blue),
                  ),
                ],
              ),
            ),

            // ➕ Zoom butonları
            Positioned(
              bottom: 80,
              left: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    heroTag: 'zoom_in',
                    onPressed: () {
                      final zoom = _mapController.camera.zoom + 1;
                      _mapController.move(_selectedLocation, zoom);
                    },
                    child: const Icon(Icons.add, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    heroTag: 'zoom_out',
                    onPressed: () {
                      final zoom = _mapController.camera.zoom - 1;
                      _mapController.move(_selectedLocation, zoom);
                    },
                    child: const Icon(Icons.remove, color: Colors.black87),
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
