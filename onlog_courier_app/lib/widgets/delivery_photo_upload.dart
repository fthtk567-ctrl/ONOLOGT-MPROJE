import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class DeliveryPhotoUpload extends StatefulWidget {
  final Function(File) onPhotoSelected;
  final String deliveryId;
  
  const DeliveryPhotoUpload({
    super.key,
    required this.onPhotoSelected,
    required this.deliveryId,
  });

  @override
  State<DeliveryPhotoUpload> createState() => _DeliveryPhotoUploadState();
}

class _DeliveryPhotoUploadState extends State<DeliveryPhotoUpload> {
  File? _selectedImage;
  final bool _isUploading = false;
  
  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 50, // Kaliteyi düşür (boyut için)
      );
      
      if (photo != null) {
        // Fotoğrafı sıkıştır
        final File compressedFile = await _compressImage(File(photo.path));
        setState(() => _selectedImage = compressedFile);
        widget.onPhotoSelected(compressedFile);
      }
    } catch (e) {
      debugPrint('❌ Fotoğraf çekilemedi: $e');
      // Kullanıcıya hata göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf çekilemedi!')),
        );
      }
    }
  }
  
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${widget.deliveryId}.jpg';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 50,     // Düşük kalite
      rotate: 0,       // Rotasyon yok
    );
    
    return File(result?.path ?? file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fotoğraf preview
        if (_selectedImage != null)
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  color: Colors.white,
                  onPressed: _takePhoto,
                ),
              ),
            ],
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Teslimat Fotoğrafı Çek',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

        // Fotoğraf çekme butonu
        if (_selectedImage == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _takePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.camera_alt),
              label: Text(_isUploading ? 'Yükleniyor...' : 'Fotoğraf Çek'),
            ),
          ),
      ],
    );
  }
}