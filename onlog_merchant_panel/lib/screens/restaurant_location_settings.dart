import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

/// 🏪 Restoran Konum Ayarları
/// 
/// Kullanıcı restoran konumunu manuel girebilir veya cihaz konumunu kullanabilir
class RestaurantLocationSettings extends StatefulWidget {
  const RestaurantLocationSettings({super.key});

  @override
  State<RestaurantLocationSettings> createState() => _RestaurantLocationSettingsState();
}

class _RestaurantLocationSettingsState extends State<RestaurantLocationSettings> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  
  // Popüler İstanbul Konumları
  final List<Map<String, dynamic>> _presetLocations = [
    {'name': 'Kadıköy - Moda', 'lat': 40.9908, 'lng': 29.0251, 'address': 'Moda Mahallesi, Kadıköy/İstanbul'},
    {'name': 'Beşiktaş', 'lat': 41.0425, 'lng': 29.0089, 'address': 'Beşiktaş Merkez, İstanbul'},
    {'name': 'Şişli', 'lat': 41.0490, 'lng': 28.9934, 'address': 'Şişli Merkez, İstanbul'},
    {'name': 'Bakırköy', 'lat': 40.9829, 'lng': 28.8667, 'address': 'Bakırköy Merkez, İstanbul'},
    {'name': 'Üsküdar', 'lat': 41.0220, 'lng': 29.0213, 'address': 'Üsküdar Merkez, İstanbul'},
    {'name': 'Fatih - Sultanahmet', 'lat': 41.0128, 'lng': 28.9496, 'address': 'Sultanahmet, Fatih/İstanbul'},
    {'name': 'Taksim', 'lat': 41.0370, 'lng': 28.9857, 'address': 'Taksim Meydanı, Beyoğlu/İstanbul'},
    {'name': 'Maltepe', 'lat': 40.9333, 'lng': 29.1333, 'address': 'Maltepe Merkez, İstanbul'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }
  
  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _latController.text = prefs.getDouble('restaurant_lat')?.toString() ?? '';
      _lngController.text = prefs.getDouble('restaurant_lng')?.toString() ?? '';
      _addressController.text = prefs.getString('restaurant_address') ?? '';
      _isLoading = false;
    });
  }
  
  Future<void> _saveLocation() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Geçersiz koordinatlar! Lütfen sayı girin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Koordinat sınırları kontrolü (İstanbul için)
    if (lat < 40.0 || lat > 42.0 || lng < 27.0 || lng > 30.0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Koordinat Uyarısı'),
          content: const Text('Girdiğiniz koordinatlar İstanbul dışında görünüyor. Devam etmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('restaurant_lat', lat);
    await prefs.setDouble('restaurant_lng', lng);
    await prefs.setString('restaurant_address', _addressController.text);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('✅ Restoran konumu kaydedildi!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, LatLng(lat, lng));
    }
  }
  
  void _usePresetLocation(Map<String, dynamic> location) {
    setState(() {
      _latController.text = location['lat'].toString();
      _lngController.text = location['lng'].toString();
      _addressController.text = location['address'];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 Restoran Konumu'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Açıklama
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Web tarayıcıda GPS hassasiyeti düşüktür. Restoranınızın tam konumunu aşağıdaki yöntemlerle girebilirsiniz.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Hızlı Seçim
                  const Text(
                    '📍 Hızlı Konum Seçimi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetLocations.map((location) {
                      return ActionChip(
                        avatar: const Icon(Icons.location_on, size: 18),
                        label: Text(location['name']),
                        onPressed: () => _usePresetLocation(location),
                        backgroundColor: Colors.green.shade50,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  // Manuel Giriş
                  const Text(
                    '✏️ Manuel Koordinat Girişi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _latController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enlem (Latitude)',
                      hintText: 'Örn: 40.9908',
                      prefixIcon: const Icon(Icons.north),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Google Maps\'ten kopyalayabilirsiniz',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _lngController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Boylam (Longitude)',
                      hintText: 'Örn: 29.0251',
                      prefixIcon: const Icon(Icons.east),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Google Maps\'ten kopyalayabilirsiniz',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Adres (Opsiyonel)',
                      hintText: 'Restoran adresinizi yazın',
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Google Maps Yönergesi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Google Maps\'ten Koordinat Nasıl Alınır?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Google Maps\'te restoranınızı bulun\n'
                          '2. Konuma sağ tıklayın\n'
                          '3. İlk satırdaki sayıları kopyalayın (örn: 40.9908, 29.0251)\n'
                          '4. Virgülden önceki sayı = Enlem\n'
                          '5. Virgülden sonraki sayı = Boylam',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Kaydet Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveLocation,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Konumu Kaydet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
