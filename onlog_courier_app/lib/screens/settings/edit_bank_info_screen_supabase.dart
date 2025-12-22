import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';

class EditBankInfoScreenSupabase extends StatefulWidget {
  final String courierId;

  const EditBankInfoScreenSupabase({
    super.key,
    required this.courierId,
  });

  @override
  State<EditBankInfoScreenSupabase> createState() => _EditBankInfoScreenSupabaseState();
}

class _EditBankInfoScreenSupabaseState extends State<EditBankInfoScreenSupabase> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadBankInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('payment_settings')
          .eq('id', widget.courierId)
          .single();

      if (response['payment_settings'] != null) {
        final paymentSettings = response['payment_settings'] as Map<String, dynamic>;
        _bankNameController.text = paymentSettings['bank_name'] ?? '';
        _accountHolderController.text = paymentSettings['account_holder_name'] ?? '';
        _ibanController.text = paymentSettings['iban'] ?? '';
        _accountNumberController.text = paymentSettings['account_number'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banka bilgileri yüklenemedi: $e'),
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
      final paymentSettings = {
        'bank_name': _bankNameController.text.trim(),
        'account_holder_name': _accountHolderController.text.trim(),
        'iban': _ibanController.text.trim().toUpperCase(),
        'account_number': _accountNumberController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('users')
          .update({
            'payment_settings': paymentSettings,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.courierId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banka bilgileriniz başarıyla güncellendi'),
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

  String? _validateIBAN(String? value) {
    if (value == null || value.isEmpty) {
      return 'IBAN boş bırakılamaz';
    }
    
    // TR ile başlamalı ve 26 karakter olmalı
    final iban = value.replaceAll(' ', '').toUpperCase();
    if (!iban.startsWith('TR')) {
      return 'IBAN TR ile başlamalıdır';
    }
    if (iban.length != 26) {
      return 'IBAN 26 karakter olmalıdır';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Ödeme Bilgilerini Düzenle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[700],
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
                          colors: [Colors.green[600]!, Colors.green[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Info box
                  _buildInfoBox(),
                  const SizedBox(height: 24),

                  // Banka Adı
                  _buildInputField(
                    controller: _bankNameController,
                    label: 'Banka Adı',
                    icon: Icons.account_balance,
                    hint: 'Örn: Ziraat Bankası',
                    iconColor: Colors.green,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Banka adı boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Hesap Sahibi
                  _buildInputField(
                    controller: _accountHolderController,
                    label: 'Hesap Sahibi Adı Soyadı',
                    icon: Icons.person,
                    hint: 'Örn: AHMET YILMAZ',
                    iconColor: Colors.blue,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Hesap sahibi adı boş bırakılamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // IBAN
                  _buildInputField(
                    controller: _ibanController,
                    label: 'IBAN',
                    icon: Icons.credit_card,
                    hint: 'TR00 0000 0000 0000 0000 0000 00',
                    iconColor: Colors.orange,
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateIBAN,
                  ),
                  const SizedBox(height: 16),

                  // Hesap Numarası
                  _buildInputField(
                    controller: _accountNumberController,
                    label: 'Hesap Numarası (Opsiyonel)',
                    icon: Icons.numbers,
                    hint: 'Varsa hesap numaranızı girin',
                    iconColor: Colors.purple,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Doğrulama Butonu
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[400]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Banka hesabı doğrulama özelliği yakında eklenecektir'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_user, color: Colors.white),
                      label: const Text(
                        'BANKA HESABIMI DOĞRULA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Güvenlik notu
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Banka bilgileriniz güvenli bir şekilde şifrelenerek saklanmaktadır.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
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

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[900], size: 22),
              const SizedBox(width: 10),
              Text(
                'Önemli Bilgilendirme',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Haftalık ödemelerinizin doğru hesaba aktarılabilmesi için banka bilgilerinizi eksiksiz ve doğru bir şekilde girdiğinizden emin olun.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.amber[900],
              height: 1.4,
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
}
