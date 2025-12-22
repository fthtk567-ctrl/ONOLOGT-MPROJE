import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final Map<String, dynamic> _settings = {
    'commission_rate': 15.0,
    'fixed_fee': 2.0,
    'vat_rate': 18.0,
    'min_delivery_fee': 20.0,
    'max_delivery_distance': 15.0,
    'courier_timeout_minutes': 10,
  };
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // commission_configs tablosundan sistem ayarlarını yükle
      final response = await SupabaseService.from('commission_configs')
          .select()
          .isFilter('merchant_id', null)
          .single();
      
      setState(() {
        _settings['commission_rate'] = (response['commission_rate'] ?? 15.0).toDouble();
        _settings['fixed_fee'] = (response['fixed_fee'] ?? 2.0).toDouble();
        _settings['vat_rate'] = (response['vat_rate'] ?? 18.0).toDouble();
        _isLoading = false;
      });
      
      print('✅ Sistem ayarları yüklendi: $_settings');
    } catch (e) {
      print('❌ Sistem ayarları yükleme hatası: $e');
      // Varsayılan değerlerle devam et
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCommissionSettings() async {
    try {
      await SupabaseService.from('commission_configs')
          .upsert({
            'merchant_id': null, // Sistem geneli ayarları
            'commission_rate': _settings['commission_rate'],
            'fixed_fee': _settings['fixed_fee'],
            'vat_rate': _settings['vat_rate'],
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Komisyon ayarları güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Sistem Ayarları'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Komisyon Ayarları',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildEditableSettingCard(
                  'Komisyon Oranı (%)',
                  _settings['commission_rate'].toString(),
                  Icons.percent,
                  Colors.orange,
                  'commission_rate',
                ),
                _buildEditableSettingCard(
                  'Sabit Ücret (₺)',
                  _settings['fixed_fee'].toString(),
                  Icons.add_circle,
                  Colors.blue,
                  'fixed_fee',
                ),
                _buildEditableSettingCard(
                  'KDV Oranı (%)',
                  _settings['vat_rate'].toString(),
                  Icons.calculate,
                  Colors.red,
                  'vat_rate',
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _updateCommissionSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Komisyon Ayarlarını Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Teslimat Ayarları',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildEditableSettingCard(
                  'Minimum Teslimat Ücreti (₺)',
                  _settings['min_delivery_fee'].toString(),
                  Icons.attach_money,
                  Colors.green,
                  'min_delivery_fee',
                ),
                _buildEditableSettingCard(
                  'Maksimum Teslimat Mesafesi (km)',
                  _settings['max_delivery_distance'].toString(),
                  Icons.social_distance,
                  Colors.purple,
                  'max_delivery_distance',
                ),
                _buildEditableSettingCard(
                  'Kurye Cevap Süresi (dakika)',
                  _settings['courier_timeout_minutes'].toString(),
                  Icons.timer,
                  Colors.indigo,
                  'courier_timeout_minutes',
                ),
              ],
            ),
    );
  }

  Widget _buildEditableSettingCard(String title, String value, IconData icon, Color color, String key) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        trailing: SizedBox(
          width: 100,
          child: TextFormField(
            initialValue: value,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (newValue) {
              final double? numValue = double.tryParse(newValue);
              if (numValue != null) {
                setState(() {
                  _settings[key] = numValue;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
