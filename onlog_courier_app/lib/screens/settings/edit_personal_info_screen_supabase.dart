import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';

class EditPersonalInfoScreenSupabase extends StatefulWidget {
  final String courierId;

  const EditPersonalInfoScreenSupabase({
    super.key,
    required this.courierId,
  });

  @override
  State<EditPersonalInfoScreenSupabase> createState() =>
      _EditPersonalInfoScreenSupabaseState();
}

class _EditPersonalInfoScreenSupabaseState
    extends State<EditPersonalInfoScreenSupabase> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.from('users')
          .select()
          .eq('id', widget.courierId)
          .single();

      setState(() {
        _userData = response;
        // full_name varsa onu kullan, yoksa owner_name'e bakıp fallback yap
        _nameController.text = response['full_name'] ?? response['owner_name'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        // Şehir bilgisini metadata'dan da al
        final metadata = response['metadata'] as Map<String, dynamic>?;
        _cityController.text = response['city'] ?? metadata?['city'] ?? '';
        _districtController.text = response['district'] ?? '';
        _addressController.text = response['address'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Profil yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await SupabaseService.from('users').update({
        'full_name': _nameController.text.trim(), // full_name alanını güncelle
        'owner_name': _nameController.text.trim(), // geriye uyumluluk için owner_name de set et
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'address': _addressController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.courierId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Bilgileriniz başarıyla güncellendi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true); // true = güncellendi
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Hata: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Kişisel Bilgileri Düzenle',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 20),
                label: const Text('KAYDET'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  disabledForegroundColor: Colors.grey,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profil Resmi
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ad Soyad
                  _buildInputField(
                    controller: _nameController,
                    label: 'Ad Soyad',
                    icon: Icons.person_outline,
                    color: Colors.blue,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ad soyad boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Telefon
                  _buildInputField(
                    controller: _phoneController,
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    color: Colors.green,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Telefon boş bırakılamaz';
                      }
                      if (value.length < 10) {
                        return 'Geçerli bir telefon numarası girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şehir
                  _buildInputField(
                    controller: _cityController,
                    label: 'Şehir',
                    icon: Icons.location_city_outlined,
                    color: Colors.orange,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Şehir boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // İlçe
                  _buildInputField(
                    controller: _districtController,
                    label: 'İlçe',
                    icon: Icons.place_outlined,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16),

                  // Adres
                  _buildInputField(
                    controller: _addressController,
                    label: 'Adres',
                    icon: Icons.home_outlined,
                    color: Colors.teal,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Bilgi Notu
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
                            'Bilgileriniz güvenli bir şekilde saklanır ve sadece teslimat süreçlerinde kullanılır.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[800],
                              height: 1.4,
                            ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
