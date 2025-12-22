import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onlog_shared/onlog_shared.dart';

/// İşletme Bilgileri Ayarları (Supabase Version)
class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  
  // İşletme bilgileri
  late final TextEditingController _businessNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _taxOfficeController;
  
  // Çalışma saatleri
  final Map<String, Map<String, dynamic>> _workingHours = {
    'Pazartesi': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Salı': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Çarşamba': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Perşembe': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Cuma': {'isOpen': true, 'open': '09:00', 'close': '23:00'},
    'Cumartesi': {'isOpen': true, 'open': '10:00', 'close': '23:00'},
    'Pazar': {'isOpen': true, 'open': '10:00', 'close': '22:00'},
  };

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _taxNumberController = TextEditingController();
    _taxOfficeController = TextEditingController();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      print('🔍 İşletme bilgileri yükleniyor: ${user.id}');
      
      final userData = await SupabaseUserService.getUser(user.id);

      if (userData == null) {
        print('❌ Kullanıcı bulunamadı');
        setState(() => _isLoading = false);
        return;
      }

      print('✅ Kullanıcı verisi yüklendi: $userData');
      
      setState(() {
        _businessNameController.text = userData['business_name'] as String? ?? '';
        // business_address varsa onu kullan, yoksa address kullan
        _addressController.text = (userData['business_address'] as String?) ?? (userData['address'] as String?) ?? '';
        _phoneController.text = (userData['business_phone'] as String?) ?? (userData['phone'] as String?) ?? '';
        _emailController.text = userData['email'] as String? ?? '';
        _taxNumberController.text = userData['tax_number']?.toString() ?? '';
        _taxOfficeController.text = userData['tax_office']?.toString() ?? '';
        _isLoading = false;
      });
      
      print('✅ Form dolduruldu');
      print('📍 Adres: ${_addressController.text}');
    } catch (e) {
      print('❌ İşletme bilgileri yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, color: Color(0xFF4CAF50), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'İşletme Bilgileri',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveSettings,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genel Bilgiler
                  _buildSectionCard(
                    'Genel Bilgiler',
                    Icons.business,
                    [
                      _buildTextField(
                        controller: _businessNameController,
                        label: 'İşletme Adı',
                        icon: Icons.store,
                        validator: (v) => v?.isEmpty ?? true ? 'İşletme adı gerekli' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Adres',
                        icon: Icons.location_on,
                        maxLines: 3,
                        validator: (v) => v?.isEmpty ?? true ? 'Adres gerekli' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Telefon',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _emailController,
                              label: 'E-posta',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Vergi Bilgileri
                  _buildSectionCard(
                    'Vergi Bilgileri',
                    Icons.receipt_long,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _taxNumberController,
                              label: 'Vergi Numarası',
                              icon: Icons.numbers,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _taxOfficeController,
                              label: 'Vergi Dairesi',
                              icon: Icons.account_balance,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Çalışma Saatleri
                  _buildSectionCard(
                    'Çalışma Saatleri',
                    Icons.schedule,
                    [
                      ..._workingHours.entries.map((entry) {
                        return _buildWorkingHourRow(entry.key, entry.value);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Ödeme Ayarları
                  _buildSectionCard(
                    'Ödeme Yöntemleri',
                    Icons.payment,
                    [
                      _buildPaymentOption('Nakit', Icons.money, true),
                      _buildPaymentOption('Kredi Kartı', Icons.credit_card, true),
                      _buildPaymentOption('Online Ödeme', Icons.smartphone, true),
                      _buildPaymentOption('Yemek Çeki', Icons.card_giftcard, false),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildWorkingHourRow(String day, Map<String, dynamic> hours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // 12 → 10 (overflow fix)
      padding: const EdgeInsets.all(8), // 12 → 8 (overflow fix v2)
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60, // 85 → 60 (overflow fix v2: çok daha dar)
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 11, // 13 → 11 (overflow fix v2)
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (hours['isOpen'])
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(day, 'open'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), // 8,8 → 6,6 (overflow fix v2)
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: Color(0xFF4CAF50)), // 14 → 12 (overflow fix v2)
                                  const SizedBox(width: 2), // 4 → 2 (overflow fix v2)
                                  Flexible( // overflow fix v2: text otomatik küçülsün
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        hours['open'],
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), // 13 → 12 (overflow fix v2)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3), // 6 → 3 (overflow fix v2)
                          child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(day, 'close'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), // 8,8 → 6,6 (overflow fix v2)
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: Color(0xFFFF5722)), // 14 → 12 (overflow fix v2)
                                  const SizedBox(width: 2), // 4 → 2 (overflow fix v2)
                                  Flexible( // overflow fix v2: text otomatik küçülsün
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        hours['close'],
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), // 13 → 12 (overflow fix v2)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Expanded(
                    child: Text(
                      'Kapalı',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: hours['isOpen'],
            onChanged: (value) {
              setState(() {
                _workingHours[day]!['isOpen'] = value;
              });
            },
            activeThumbColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: enabled ? const Color(0xFF4CAF50) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {
              setState(() {
                enabled = value;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title ${value ? "açıldı" : "kapatıldı"}')),
                );
              });
            },
            activeThumbColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  void _selectTime(String day, String type) async {
    final currentTime = _workingHours[day]![type] as String;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _workingHours[day]![type] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final success = await SupabaseUserService.updateUser(
        userId: user.id,
        businessName: _businessNameController.text.trim(),
        businessPhone: _phoneController.text.trim(),
        businessAddress: _addressController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ İşletme bilgileri kaydedildi'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Kaydetme başarısız'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
