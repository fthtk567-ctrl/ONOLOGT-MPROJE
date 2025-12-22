import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Bildirim ayarları
  bool _deliveryNotifications = true;
  bool _paymentNotifications = true;
  bool _systemNotifications = true;
  bool _promotionalNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Bildirim kategorileri
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bildirim Kategorileri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SwitchListTile(
            title: const Text('Teslimat Bildirimleri'),
            subtitle: const Text('Yeni teslimatlar, durumlar ve hatırlatmalar'),
            value: _deliveryNotifications,
            onChanged: (value) {
              setState(() {
                _deliveryNotifications = value;
              });
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('Ödeme Bildirimleri'),
            subtitle: const Text('Kazançlar, ödeme durumları ve transferler'),
            value: _paymentNotifications,
            onChanged: (value) {
              setState(() {
                _paymentNotifications = value;
              });
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('Sistem Bildirimleri'),
            subtitle: const Text('Güvenlik uyarıları ve uygulama güncellemeleri'),
            value: _systemNotifications,
            onChanged: (value) {
              setState(() {
                _systemNotifications = value;
              });
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('Promosyon Bildirimleri'),
            subtitle: const Text('Kampanyalar, bonuslar ve özel teklifler'),
            value: _promotionalNotifications,
            onChanged: (value) {
              setState(() {
                _promotionalNotifications = value;
              });
            },
          ),
          
          const Divider(),
          
          // Bildirim özellikleri
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Bildirim Özellikleri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SwitchListTile(
            title: const Text('Bildirim Sesi'),
            subtitle: const Text('Bildirimler için ses çal'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('Titreşim'),
            subtitle: const Text('Bildirimler için titreşim kullan'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          
          const Divider(),
          
          // Rahatsız etme modu
          ListTile(
            title: const Text('Rahatsız Etme Saatleri'),
            subtitle: const Text('Bildirimlerin sessiz kalacağı zaman aralığını belirleyin'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showDoNotDisturbDialog();
            },
          ),
          
          const SizedBox(height: 20),
          
          // Tüm bildirimleri temizle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                _showClearNotificationsDialog();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Tüm Bildirimleri Temizle'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ayarları sıfırla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () {
                _resetSettings();
              },
              child: const Text('Ayarları Sıfırla'),
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showDoNotDisturbDialog() {
    // Rahatsız etme modu ayarları için diyalog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rahatsız Etme Saatleri'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Burada saat seçimi eklenebilir
            Text('Belirli saatlerde bildirimleri sessize alabilirsiniz.'),
            SizedBox(height: 16),
            Text('Bu özellik yakında eklenecek!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showClearNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Bildirimleri Temizle'),
        content: const Text('Tüm bildirimleri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tüm bildirimler temizlendi'),
                ),
              );
            },
            child: const Text(
              'Temizle',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarları Sıfırla'),
        content: const Text('Tüm bildirim ayarlarınız varsayılan değerlere sıfırlanacak. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _deliveryNotifications = true;
                _paymentNotifications = true;
                _systemNotifications = true;
                _promotionalNotifications = false;
                _soundEnabled = true;
                _vibrationEnabled = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ayarlar sıfırlandı'),
                ),
              );
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}