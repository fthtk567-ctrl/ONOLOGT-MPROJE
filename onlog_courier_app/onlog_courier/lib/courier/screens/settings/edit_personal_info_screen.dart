import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/models/courier.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  final Courier courier;
  final Function(Courier updatedCourier) onSave;

  const EditPersonalInfoScreen({
    super.key, 
    required this.courier, 
    required this.onSave
  });

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _identityController;
  bool _isLoading = false;
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _profileImageUrl = '';
  
  // İzin kontrolü yapılacak
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
    _nameController = TextEditingController(text: widget.courier.name);
    _phoneController = TextEditingController(text: widget.courier.phone);
    _emailController = TextEditingController(text: widget.courier.email);
    _identityController = TextEditingController(text: widget.courier.identityNumber);
    _profileImageUrl = widget.courier.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // API işlemini simüle etmek için kısa bir bekleme
      await Future.delayed(const Duration(seconds: 1));

      // Kurye bilgilerini güncelle
      final updatedCourier = widget.courier;
      updatedCourier.name = _nameController.text;
      updatedCourier.phone = _phoneController.text;
      updatedCourier.email = _emailController.text;
      updatedCourier.identityNumber = _identityController.text;

      // Callback ile güncellenmiş veriyi ana sayfaya ilet
      widget.onSave(updatedCourier);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Başarılı mesajı göster ve sayfayı kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilgileriniz başarıyla güncellendi'),
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
        title: const Text('Kişisel Bilgileri Düzenle'),
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
            _buildProfileImageSection(),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _nameController,
              label: 'Ad Soyad',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ad soyad boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _phoneController,
              label: 'Telefon',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Telefon boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _emailController,
              label: 'E-posta',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'E-posta boş bırakılamaz';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _identityController,
              label: 'T.C. Kimlik No',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'T.C. Kimlik No boş bırakılamaz';
                }
                if (value.length != 11) {
                  return 'T.C. Kimlik No 11 haneli olmalıdır';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // Resim seçme fonksiyonu
  Future<void> _pickImage(ImageSource source) async {
    try {
      // İzin kontrolü
      if (source == ImageSource.camera) {
        bool hasCameraPermission = await _requestPermission(Permission.camera);
        if (!hasCameraPermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kamera izni gerekiyor'))
            );
          }
          return;
        }
      } else if (source == ImageSource.gallery) {
        bool hasGalleryPermission = false;
        if (Platform.isAndroid) {
          // Android 13 ve üzeri için (API 33+)
          if (await Permission.photos.status.isGranted) {
            hasGalleryPermission = true;
          } else if (await Permission.storage.status.isGranted) {
            // Eski Android API'da izin var
            hasGalleryPermission = true;
          } else {
            // İzin yoksa, izin isteyelim
            hasGalleryPermission = await _requestPermission(Platform.isAndroid ? Permission.storage : Permission.photos);
          }
          
          if (!hasGalleryPermission && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Galeri erişim izni gerekiyor'))
            );
            return;
          }
        }
      }
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          // Gerçek API'da bu URL sunucuya yüklenen dosyanın URL'si olacak
          _profileImageUrl = pickedFile.path;
          
          // Courier modeli güncelleme - normalde burada resim önce sunucuya yüklenecek
          widget.courier.profileImage = _profileImageUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçilemedi: ${e.toString()}')),
      );
    }
  }
  
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImage != null 
                    ? FileImage(_selectedImage!) as ImageProvider 
                    : NetworkImage(_profileImageUrl),
                backgroundColor: Colors.grey[200],
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _showImageSourceActionSheet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Profil Fotoğrafını Değiştir',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
}