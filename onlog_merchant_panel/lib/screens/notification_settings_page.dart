import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Bildirim Tercihleri Ayarları
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Sipariş bildirimleri
  bool _newOrderPush = true;
  bool _newOrderEmail = true;
  bool _newOrderSMS = false;
  bool _newOrderSound = true;
  
  // Kurye bildirimleri
  bool _courierArrivedPush = true;
  bool _courierArrivedSMS = false;
  bool _courierDelayedPush = true;
  
  // Sistem bildirimleri
  bool _systemUpdatesPush = true;
  bool _systemUpdatesEmail = true;
  bool _promotionalEmail = false;
  
  // Günlük özetler
  bool _dailySummaryEmail = true;
  String _dailySummaryTime = '09:00';
  
  // Sesli uyarılar
  bool _soundEnabled = true;
  double _soundVolume = 0.7;
  String _selectedSound = 'Varsayılan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        title: const Text('Bildirim Tercihleri', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.check, color: Colors.white, size: 20),
            label: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Önemli Not
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Siparişleri kaçırmamak için en az bir bildirim kanalını açık tutmanızı öneririz.',
                    style: TextStyle(color: Colors.blue[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Sipariş Bildirimleri
          _buildSectionCard(
            'Sipariş Bildirimleri',
            Icons.shopping_bag,
            [
              _buildNotificationRow(
                'Push Bildirim',
                'Yeni sipariş geldiğinde anlık bildirim',
                Icons.notifications_active,
                _newOrderPush,
                (v) => setState(() => _newOrderPush = v),
                isImportant: true,
              ),
              _buildNotificationRow(
                'E-posta',
                'Yeni sipariş için e-posta al',
                Icons.email,
                _newOrderEmail,
                (v) => setState(() => _newOrderEmail = v),
              ),
              _buildNotificationRow(
                'SMS',
                'Yeni sipariş için SMS al',
                Icons.sms,
                _newOrderSMS,
                (v) => setState(() => _newOrderSMS = v),
              ),
              _buildNotificationRow(
                'Sesli Uyarı',
                'Yeni sipariş için ses çal',
                Icons.volume_up,
                _newOrderSound,
                (v) => setState(() => _newOrderSound = v),
                isImportant: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Kurye Bildirimleri
          _buildSectionCard(
            'Kurye Bildirimleri',
            Icons.delivery_dining,
            [
              _buildNotificationRow(
                'Kurye Ulaştı',
                'Kurye restorana ulaştığında bildir',
                Icons.location_on,
                _courierArrivedPush,
                (v) => setState(() => _courierArrivedPush = v),
              ),
              _buildNotificationRow(
                'Kurye Ulaştı (SMS)',
                'Kurye ulaştığında SMS gönder',
                Icons.sms,
                _courierArrivedSMS,
                (v) => setState(() => _courierArrivedSMS = v),
              ),
              _buildNotificationRow(
                'Gecikme Uyarısı',
                'Teslimat geciktiğinde uyar',
                Icons.warning_amber,
                _courierDelayedPush,
                (v) => setState(() => _courierDelayedPush = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sistem Bildirimleri
          _buildSectionCard(
            'Sistem Bildirimleri',
            Icons.settings,
            [
              _buildNotificationRow(
                'Sistem Güncellemeleri',
                'Uygulama güncellemeleri ve özellikler',
                Icons.system_update,
                _systemUpdatesPush,
                (v) => setState(() => _systemUpdatesPush = v),
              ),
              _buildNotificationRow(
                'E-posta Bülteni',
                'Sistem haberleri için e-posta',
                Icons.email,
                _systemUpdatesEmail,
                (v) => setState(() => _systemUpdatesEmail = v),
              ),
              _buildNotificationRow(
                'Promosyonlar',
                'Kampanya ve indirim bildirimleri',
                Icons.local_offer,
                _promotionalEmail,
                (v) => setState(() => _promotionalEmail = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Günlük Özetler
          _buildSectionCard(
            'Günlük Özetler',
            Icons.today,
            [
              _buildNotificationRow(
                'Günlük Özet E-postası',
                'Her gün sipariş ve gelir özeti',
                Icons.summarize,
                _dailySummaryEmail,
                (v) => setState(() => _dailySummaryEmail = v),
              ),
              if (_dailySummaryEmail) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectSummaryTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Gönderim Saati: $_dailySummaryTime',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          
          // Sesli Uyarı Ayarları
          _buildSectionCard(
            'Sesli Uyarı Ayarları',
            Icons.music_note,
            [
              _buildNotificationRow(
                'Sesli Uyarılar',
                'Bildirimler için ses çal',
                Icons.volume_up,
                _soundEnabled,
                (v) => setState(() => _soundEnabled = v),
              ),
              if (_soundEnabled) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ses Seviyesi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.volume_mute, size: 20, color: Colors.grey),
                        Expanded(
                          child: Slider(
                            value: _soundVolume,
                            onChanged: (v) => setState(() => _soundVolume = v),
                            activeColor: const Color(0xFF4CAF50),
                            divisions: 10,
                            label: '${(_soundVolume * 100).round()}%',
                          ),
                        ),
                        const Icon(Icons.volume_up, size: 20, color: Color(0xFF4CAF50)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bildirim Sesi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSound,
                          isExpanded: true,
                          items: ['Varsayılan', 'Zil 1', 'Zil 2', 'Alarm', 'Klasik'].map((sound) {
                            return DropdownMenuItem(
                              value: sound,
                              child: Text(sound),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSound = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testSound,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Test Et'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testNewOrderSound,
                        icon: const Icon(Icons.shopping_bag, size: 20),
                        label: const Text('Yeni Sipariş'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Teslimat tamamlandı sesi test butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _testDeliveryCompletedSound,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Teslimat Tamamlandı Sesi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotificationRow(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    bool isImportant = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isImportant && value ? const Color(0xFF4CAF50).withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isImportant && value ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: value ? const Color(0xFF4CAF50) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (isImportant) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ÖNERİLİR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  void _selectSummaryTime() async {
    final parts = _dailySummaryTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dailySummaryTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveSettings() {
    // Ayarları SharedPreferences'a kaydet
    NotificationService.setSoundEnabled(_soundEnabled);
    NotificationService.setSoundVolume(_soundVolume);
    NotificationService.setSelectedSound(_selectedSound);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim tercihleri kaydedildi'),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _testSound() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🔊 Test sesi çalınıyor... ($_selectedSound, ${(_soundVolume * 100).toInt()}%)',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Gerçek ses çalma
    await NotificationService.playTestSound();
  }

  void _testNewOrderSound() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('🔔 YENİ SİPARİŞ SESİ! (Volume: ayarlı ses seviyesi)'),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Gerçek yeni sipariş sesi çalma
    await NotificationService.playNewOrderSound();
  }

  void _testDeliveryCompletedSound() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('🎉 TESLİMAT TAMAMLANDI! ($_selectedSound, ${(_soundVolume * 100).toInt()}%)'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Gerçek teslimat tamamlandı sesi çalma
    await NotificationService.playDeliveryCompletedSound();
  }
}
