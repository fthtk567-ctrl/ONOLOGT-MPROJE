import 'dart:io';
import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_delivery_service.dart';
import '../widgets/delivery_photo_upload.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onConfirmed;
  
  const DeliveryConfirmationScreen({
    super.key,
    required this.delivery,
    required this.onConfirmed,
  });

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedPhoto;
  bool _isLoading = false;
  double? _collectedAmount;
  String? _notes;
  bool _hasArrived = false;
  
  Future<void> _confirmDelivery() async {
    if (!_formKey.currentState!.validate() || _selectedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun ve fotoğraf çekin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Fotoğrafı yükle
      final String? photoUrl = await SupabaseDeliveryService.uploadDeliveryPhoto(
        deliveryId: widget.delivery['id'],
        photoFile: _selectedPhoto!,
      );

      if (photoUrl == null) throw 'Fotoğraf yüklenemedi';

      // 2. Teslimatı tamamla
      final success = await SupabaseDeliveryService.completeDelivery(
        deliveryId: widget.delivery['id'],
        collectedAmount: _collectedAmount!,
        photoUrl: photoUrl,
        notes: _notes,
      );

      if (!success) throw 'Teslimat onaylanamadı';

      // 3. Başarılı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Teslimat başarıyla tamamlandı!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onConfirmed();
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teslimat Onayı'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Varış bildirimi
            if (!_hasArrived)
              ElevatedButton.icon(
                onPressed: () => setState(() => _hasArrived = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.location_on),
                label: const Text('Varış Bildir'),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Varış Bildirildi',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            
            // Teslimat fotoğrafı
            if (_hasArrived)
              DeliveryPhotoUpload(
                deliveryId: widget.delivery['id'],
                onPhotoSelected: (file) => setState(() => _selectedPhoto = file),
              ),

            if (_hasArrived && _selectedPhoto != null) ...[
              const SizedBox(height: 24),

              // Tahsilat tutarı
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tahsil Edilen Tutar (TL)',
                  prefixIcon: Icon(Icons.monetization_on),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tutar girilmeli';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
                onSaved: (value) => _collectedAmount = double.tryParse(value ?? '0'),
              ),

              const SizedBox(height: 16),

              // Not alanı
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Teslimat Notu (Opsiyonel)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) => _notes = value,
              ),

              const SizedBox(height: 24),

              // Onay butonu
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () {
                  _formKey.currentState!.save();
                  _confirmDelivery();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle),
                label: Text(_isLoading ? 'Onaylanıyor...' : 'Teslimatı Onayla'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}