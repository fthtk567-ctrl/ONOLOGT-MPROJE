import 'package:flutter/material.dart';
import '../../shared/models/delivery_task.dart';

class MapScreen extends StatefulWidget {
  final List<DeliveryTask>? deliveries;
  final DeliveryTask? activeDelivery;
  
  const MapScreen({
    super.key, 
    this.deliveries,
    this.activeDelivery,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = true;
  bool _showDirections = false;
  bool _showTraffic = false;
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    // Gerçekte harita yüklenir ve konumlandırılır
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activeDelivery != null
              ? 'Teslimat Rotası'
              : 'Teslimat Haritası',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showTraffic ? Icons.traffic : Icons.traffic_outlined,
              color: _showTraffic ? Colors.red : null,
            ),
            tooltip: 'Trafik Bilgisi',
            onPressed: () {
              setState(() {
                _showTraffic = !_showTraffic;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gerçekte burada bir Google Maps veya başka bir harita widgetı olacak
          Container(
            color: Colors.grey[200],
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map,
                          size: 100,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.activeDelivery != null
                              ? '${widget.activeDelivery!.merchantName} teslimatı için rota'
                              : 'Teslimat lokasyonları',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showDirections = !_showDirections;
                            });
                          },
                          child: Text(
                            _showDirections ? 'Rotayı Gizle' : 'Rotayı Göster',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Alt bilgi kartı
          if (widget.activeDelivery != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildDeliveryInfoCard(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Konum merkezle
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum merkezleniyor...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
  
  Widget _buildDeliveryInfoCard() {
    if (widget.activeDelivery == null) return Container();
    
    final delivery = widget.activeDelivery!;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.store,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.merchantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Teslimat #${delivery.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    delivery.distance != null
                        ? '${delivery.distance!.toStringAsFixed(1)} km'
                        : '? km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildAddressRow(
              'Alış',
              delivery.pickupAddress,
              Icons.location_on,
              Colors.blue,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: SizedBox(
                height: 30,
                child: VerticalDivider(
                  color: Colors.grey[300],
                  width: 20,
                  thickness: 2,
                ),
              ),
            ),
            _buildAddressRow(
              'Teslimat',
              delivery.deliveryAddress,
              Icons.flag,
              Colors.red,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.navigation),
                label: const Text('YOLU BAŞLAT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddressRow(
    String label,
    String address,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}