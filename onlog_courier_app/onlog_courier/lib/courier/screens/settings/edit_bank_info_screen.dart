import 'package:flutter/material.dart';
import '../../../shared/models/courier.dart';

class EditBankInfoScreen extends StatefulWidget {
  final Courier courier;
  final Function(Courier updatedCourier) onSave;

  const EditBankInfoScreen({
    super.key,
    required this.courier,
    required this.onSave,
  });

  @override
  State<EditBankInfoScreen> createState() => _EditBankInfoScreenState();
}

class _EditBankInfoScreenState extends State<EditBankInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(text: widget.courier.bankName);
    _accountNumberController = TextEditingController(text: widget.courier.accountNumber);
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // API işlemini simüle etmek için kısa bir bekleme
      await Future.delayed(const Duration(seconds: 1));

      // Banka bilgilerini güncelle
      final updatedCourier = widget.courier;
      updatedCourier.bankName = _bankNameController.text;
      updatedCourier.accountNumber = _accountNumberController.text;

      // Callback ile güncellenmiş veriyi ana sayfaya ilet
      widget.onSave(updatedCourier);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Başarılı mesajı göster ve sayfayı kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banka bilgileriniz başarıyla güncellendi'),
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
        title: const Text('Ödeme Bilgilerini Düzenle'),
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
            _buildInfoBox(),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _bankNameController,
              label: 'Banka Adı',
              icon: Icons.account_balance,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Banka adı boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _accountNumberController,
              label: 'IBAN / Hesap Numarası',
              icon: Icons.credit_card,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hesap numarası boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Banka hesabı doğrulama özelliği yakında eklenecektir'),
                  ),
                );
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('BANKA HESABIMI DOĞRULA'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Ödeme Bilgileriniz',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Haftalık ödemelerinizin doğru hesaba aktarılabilmesi için banka bilgilerinizi eksiksiz ve doğru bir şekilde girdiğinizden emin olun.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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