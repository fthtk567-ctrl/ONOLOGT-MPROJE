import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../shared/models/courier.dart';

class EditVehicleInfoScreen extends StatefulWidget {
  final Courier courier;
  final Function(Courier updatedCourier) onSave;

  const EditVehicleInfoScreen({
    super.key, 
    required this.courier, 
    required this.onSave
  });

  @override
  State<EditVehicleInfoScreen> createState() => _EditVehicleInfoScreenState();
}

class _EditVehicleInfoScreenState extends State<EditVehicleInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late VehicleType _selectedVehicleType;
  late TextEditingController _licensePlateController;
  late TextEditingController _driverLicenseController;
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();
  
  // Belge dosyaları
  File? _licenseFile;
  File? _driverLicenseFile;
  File? _insuranceFile;
  File? _vehiclePhotoFile;
  
  // İzin kontrolü
  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      return result.isGranted;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedVehicleType = widget.courier.vehicleType;
    _licensePlateController = TextEditingController(text: "34 ABC 123");
    _driverLicenseController = TextEditingController(text: "12345678");
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _driverLicenseController.dispose();
    super.dispose();
  }

  String _getVehicleTypeName(VehicleType type) {
    switch (type) {
      case VehicleType.motorcycle:
        return 'Motosiklet';
      case VehicleType.car:
        return 'Otomobil';
      case VehicleType.van:
        return 'Van';
      case VehicleType.bicycle:
        return 'Bisiklet';
      case VehicleType.truck:
        return 'Kamyon';
    }
  }

  IconData _getVehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.motorcycle:
        return Icons.motorcycle;
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.van:
        return Icons.airport_shuttle;
      case VehicleType.bicycle:
        return Icons.pedal_bike;
      case VehicleType.truck:
        return Icons.local_shipping;
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // API işlemini simüle etmek için kısa bir bekleme
      await Future.delayed(const Duration(seconds: 1));

      // Araç bilgilerini güncelle
      final updatedCourier = widget.courier;
      updatedCourier.vehicleType = _selectedVehicleType;
      
      // Belge dosya yollarını kaydet (gerçek uygulamada bu dosyalar sunucuya yüklenir)
      if (_licenseFile != null) {
        // Burada sunucuya yükleme ve dosya yolunu kaydetme işlemi yapılır
        // updatedCourier.licensePath = sunucuDosyaYolu;
        print("Ruhsat dosyası: ${_licenseFile!.path}");
      }
      
      if (_driverLicenseFile != null) {
        print("Ehliyet dosyası: ${_driverLicenseFile!.path}");
      }
      
      if (_insuranceFile != null) {
        print("Sigorta dosyası: ${_insuranceFile!.path}");
      }
      
      if (_vehiclePhotoFile != null) {
        print("Araç fotoğrafı: ${_vehiclePhotoFile!.path}");
      }

      // Callback ile güncellenmiş veriyi ana sayfaya ilet
      widget.onSave(updatedCourier);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Başarılı mesajı göster ve sayfayı kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Araç bilgileriniz başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araç Bilgilerini Düzenle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
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
                    style: TextStyle(color: Colors.white),
                  ),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildVehicleTypeSelector(),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _licensePlateController,
              label: 'Plaka',
              icon: Icons.directions_car,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Plaka boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _driverLicenseController,
              label: 'Ehliyet Numarası',
              icon: Icons.card_membership,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ehliyet numarası boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildDocumentUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Araç Türü',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: VehicleType.values.map((type) {
            return _buildVehicleTypeOption(type);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeOption(VehicleType type) {
    final bool isSelected = _selectedVehicleType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
        });
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getVehicleTypeIcon(type),
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _getVehicleTypeName(type),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black,
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Belge Yükle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDocumentUploadButton(
                title: 'Ruhsat',
                icon: Icons.description,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDocumentUploadButton(
                title: 'Ehliyet',
                icon: Icons.card_membership,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDocumentUploadButton(
                title: 'Sigorta',
                icon: Icons.health_and_safety,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDocumentUploadButton(
                title: 'Araç Fotoğrafı',
                icon: Icons.directions_car,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      // İzin kontrolü
      bool hasStoragePermission = Platform.isAndroid 
        ? (await _requestPermission(Permission.storage) || await _requestPermission(Permission.photos)) 
        : true;
      
      if (!hasStoragePermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya erişim izni gerekiyor')),
          );
        }
        return;
      }
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        setState(() {
          switch (documentType) {
            case 'license':
              _licenseFile = file;
              break;
            case 'driverLicense':
              _driverLicenseFile = file;
              break;
            case 'insurance':
              _insuranceFile = file;
              break;
            case 'vehiclePhoto':
              _vehiclePhotoFile = file;
              break;
          }
        });
        
        // Başarılı mesajı
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.single.name} yüklendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Belge yüklenemedi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickVehiclePhoto() async {
    try {
      // Kamera izni kontrolü
      bool hasCameraPermission = await _requestPermission(Permission.camera);
      if (!hasCameraPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera izni gerekiyor')),
          );
        }
        return;
      }
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (photo != null) {
        setState(() {
          _vehiclePhotoFile = File(photo.path);
        });
        
        // Başarılı mesajı
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Araç fotoğrafı çekildi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf çekilemedi: ${e.toString()}')),
        );
      }
    }
  }

  void _showDocumentActionSheet(String documentType, String title) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text('$title Belgesi Seç'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickDocument(documentType);
                },
              ),
              if (documentType == 'vehiclePhoto')
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Fotoğraf Çek'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickVehiclePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentUploadButton({
    required String title,
    required IconData icon,
  }) {
    String documentType;
    
    switch (title) {
      case 'Ruhsat':
        documentType = 'license';
        break;
      case 'Ehliyet':
        documentType = 'driverLicense';
        break;
      case 'Sigorta':
        documentType = 'insurance';
        break;
      case 'Araç Fotoğrafı':
        documentType = 'vehiclePhoto';
        break;
      default:
        documentType = '';
    }
    
    File? selectedFile;
    switch (documentType) {
      case 'license':
        selectedFile = _licenseFile;
        break;
      case 'driverLicense':
        selectedFile = _driverLicenseFile;
        break;
      case 'insurance':
        selectedFile = _insuranceFile;
        break;
      case 'vehiclePhoto':
        selectedFile = _vehiclePhotoFile;
        break;
    }
    
    return InkWell(
      onTap: () {
        _showDocumentActionSheet(documentType, title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selectedFile != null ? Colors.green.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedFile != null ? Colors.green : Colors.grey[300]!
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedFile != null ? Icons.check_circle : icon, 
              color: selectedFile != null ? Colors.green : Colors.grey[700], 
              size: 28
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selectedFile != null ? Colors.green : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedFile != null ? 'Değiştir' : 'Yükle',
              style: TextStyle(
                color: selectedFile != null ? Colors.green : Colors.blue,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}