import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MerchantContactCard extends StatelessWidget {
  final Map<String, dynamic> merchantData;
  
  const MerchantContactCard({
    super.key,
    required this.merchantData,
  });

  Future<void> _callMerchant() async {
    final phone = merchantData['phone'] ?? merchantData['business_phone'];
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else {
        debugPrint('❌ Telefon numarası açılamadı: $phone');
      }
    }
  }

  Future<void> _openMap() async {
    final lat = merchantData['location']?['lat'];
    final lng = merchantData['location']?['lng'];
    
    if (lat != null && lng != null) {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
      );
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri);
      } else {
        debugPrint('❌ Harita açılamadı');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = merchantData['business_name'] ?? 'İşletme';
    final ownerName = merchantData['owner_name'] ?? '';
    final phone = merchantData['phone'] ?? merchantData['business_phone'] ?? '';
    final address = merchantData['business_address'] ?? '';
    
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.store, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (ownerName.isNotEmpty)
                        Text(
                          ownerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (address.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.red),
                title: const Text('Adres'),
                subtitle: Text(address),
                contentPadding: EdgeInsets.zero,
                trailing: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: _openMap,
                  tooltip: 'Haritada Göster',
                ),
              ),
            if (phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Telefon'),
                subtitle: Text(phone),
                contentPadding: EdgeInsets.zero,
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: _callMerchant,
                  tooltip: 'Ara',
                ),
              ),
          ],
        ),
      ),
    );
  }
}