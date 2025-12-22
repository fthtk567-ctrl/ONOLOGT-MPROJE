import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class CourierTrackingMap extends StatefulWidget {
  final List orders;
  final List couriers;
  final bool showCurrentLocation;
  final Function(String)? onOrderSelected;
  
  const CourierTrackingMap({
    super.key,
    this.orders = const [],
    this.couriers = const [],
    this.showCurrentLocation = true,
    this.onOrderSelected,
  });

  @override
  State<CourierTrackingMap> createState() => _CourierTrackingMapState();
}

class _CourierTrackingMapState extends State<CourierTrackingMap> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(41.0082, 28.9784); // İstanbul merkezi
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.showCurrentLocation) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Konum servisinin aktif olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Konum servisi kapalı');
        // Kullanıcıyı ayarlara yönlendir
        await Geolocator.openLocationSettings();
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // İzin durumunu kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Konum izin durumu: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('📍 İzin istendi, sonuç: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ Konum izni reddedildi');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Konum izni kalıcı olarak reddedildi');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      print('✅ Konum alınıyor...');
      // Daha hassas konum ayarları
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      print('📍 Konum alındı: ${position.latitude}, ${position.longitude}');
      
      setState(() {
        _currentPosition = position;
        _center = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Haritayı konuma odakla
      _mapController.move(_center, 16.0);
    } catch (e) {
      print('❌ Konum alınamadı: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.onlog.onlog_application_2',
            ),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        // Dış halka (animasyonlu)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                        ),
                        // İç konum noktası
                        Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        // Zoom kontrolleri
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: "zoom_in",
                backgroundColor: Colors.white,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom + 1);
                },
                child: const Icon(Icons.add, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "zoom_out",
                backgroundColor: Colors.white,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom - 1);
                },
                child: const Icon(Icons.remove, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              // Konumuma git butonu
              FloatingActionButton.small(
                heroTag: "my_location",
                backgroundColor: _currentPosition != null ? Colors.blue : Colors.grey,
                onPressed: _currentPosition != null ? () {
                  _mapController.move(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    17.0
                  );
                } : _getCurrentLocation,
                child: Icon(
                  _currentPosition != null ? Icons.my_location : Icons.location_searching,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Konum yenile butonu
              FloatingActionButton.small(
                heroTag: "refresh_location",
                backgroundColor: Colors.green,
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),
        if (_isLoadingLocation)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Konum alınıyor...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
