import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';

class EditVehicleInfoScreenSupabase extends StatefulWidget {
  final String courierId;

  const EditVehicleInfoScreenSupabase({
    super.key,
    required this.courierId,
  });

  @override
  State<EditVehicleInfoScreenSupabase> createState() => _EditVehicleInfoScreenSupabaseState();
}

class _EditVehicleInfoScreenSupabaseState extends State<EditVehicleInfoScreenSupabase> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  
  String _selectedVehicleType = 'motor'; // motor, araba, bisiklet, van
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'value': 'motor', 'label': 'Motosiklet', 'icon': Icons.two_wheeler},
    {'value': 'araba', 'label': 'Otomobil', 'icon': Icons.directions_car},
    {'value': 'bisiklet', 'label': 'Bisiklet', 'icon': Icons.pedal_bike},
    {'value': 'van', 'label': 'Van/Kamyonet', 'icon': Icons.airport_shuttle},
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicleInfo();
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('commission_settings')
          .eq('id', widget.courierId)
          .single();

      if (response['commission_settings'] != null) {
        final commissionSettings = response['commission_settings'] as Map<String, dynamic>;
        
        setState(() {
          _selectedVehicleType = commissionSettings['vehicle_type'] ?? 'motor';
          // vehicle_plate ve plate_number ikisini de dene (uyumluluk için)
          _plateNumberController.text = commissionSettings['vehicle_plate'] ?? commissionSettings['plate_number'] ?? '';
          _modelController.text = commissionSettings['vehicle_model'] ?? '';
          _yearController.text = commissionSettings['vehicle_year']?.toString() ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Araç bilgileri yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Mevcut commission_settings'i al
      final currentResponse = await SupabaseService.client
          .from('users')
          .select('commission_settings')
          .eq('id', widget.courierId)
          .single();

      final currentSettings = (currentResponse['commission_settings'] as Map<String, dynamic>?) ?? {};

      // Araç bilgilerini güncelle, diğer alanları koru
      final updatedSettings = {
        ...currentSettings,
        'vehicle_type': _selectedVehicleType,
        'vehicle_plate': _plateNumberController.text.trim().toUpperCase(), // vehicle_plate kullan (trigger ile uyumlu)
        'vehicle_model': _modelController.text.trim(),
        'vehicle_year': int.tryParse(_yearController.text.trim()),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('users')
          .update({
            'commission_settings': updatedSettings,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.courierId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Araç bilgileriniz başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // true döndürerek parent'ı yenile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Araç Bilgilerini Düzenle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'KAYDET',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                  // Başlık ikonu
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.orange[600]!, Colors.orange[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Araç Türü Seçici
                  const Text(
                    'Araç Türü',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVehicleTypeSelector(),
                  const SizedBox(height: 24),

                  // Plaka
                  _buildInputField(
                    controller: _plateNumberController,
                    label: 'Plaka',
                    icon: Icons.credit_card,
                    hint: 'Örn: 34 ABC 123',
                    iconColor: Colors.blue,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Plaka boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Model
                  _buildInputField(
                    controller: _modelController,
                    label: 'Araç Modeli',
                    icon: Icons.local_shipping,
                    hint: 'Örn: Honda PCX 150',
                    iconColor: Colors.purple,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Araç modeli boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Yıl
                  _buildInputField(
                    controller: _yearController,
                    label: 'Model Yılı',
                    icon: Icons.calendar_today,
                    hint: 'Örn: 2020',
                    iconColor: Colors.teal,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Model yılı boş bırakılamaz';
                      }
                      final year = int.tryParse(value);
                      if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                        return 'Geçerli bir yıl girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Info box
                  _buildInfoBox(),
                  const SizedBox(height: 24),

                  // Belge Yükleme Bölümü (Gelecek özellik)
                  _buildDocumentUploadSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _vehicleTypes.map((type) {
        final isSelected = _selectedVehicleType == type['value'];
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedVehicleType = type['value'];
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange[50] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    type['icon'],
                    color: isSelected ? Colors.white : Colors.grey[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type['label'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.orange[900] : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: iconColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 22),
              const SizedBox(width: 10),
              Text(
                'Araç Bilgileri Hakkında',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Araç türü, komisyon oranınızı etkiler. Doğru araç bilgilerini girerek en uygun kazanç planından faydalanabilirsiniz.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[100]!, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Belge Yükleme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ruhsat, Ehliyet ve Sigorta belgesi yükleme özelliği yakında eklenecektir',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDocumentIconPlaceholder(Icons.description, 'Ruhsat'),
              const SizedBox(width: 16),
              _buildDocumentIconPlaceholder(Icons.card_membership, 'Ehliyet'),
              const SizedBox(width: 16),
              _buildDocumentIconPlaceholder(Icons.health_and_safety, 'Sigorta'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentIconPlaceholder(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey[500], size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
