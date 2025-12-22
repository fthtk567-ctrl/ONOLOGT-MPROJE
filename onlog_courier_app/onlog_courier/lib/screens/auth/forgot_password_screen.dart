import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEmailMethod = true;
  final TextEditingController _emailPhoneController = TextEditingController();

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // API çağrısı simülasyonu
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Başarı mesajı ve onay ekranı
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Şifre Sıfırlama'),
            content: Text(
              _isEmailMethod
                  ? 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'
                  : 'Şifre sıfırlama kodu telefonunuza gönderildi.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // İki ekran geri git (Dialog ve şifre sıfırlama ekranı)
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bilgi metni
                const Text(
                  'Lütfen hesabınızla ilişkili e-posta adresini veya telefon numarasını girin. Size şifre sıfırlama bağlantısı/kodu göndereceğiz.',
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 30),

                // Seçenekler (E-posta veya Telefon ile sıfırlama)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEmailMethod
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          foregroundColor:
                              _isEmailMethod ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isEmailMethod = true;
                          });
                        },
                        child: const Text('E-posta'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isEmailMethod
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          foregroundColor:
                              !_isEmailMethod ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isEmailMethod = false;
                          });
                        },
                        child: const Text('Telefon'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // E-posta / Telefon alanı
                TextFormField(
                  controller: _emailPhoneController,
                  keyboardType: _isEmailMethod
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:
                        _isEmailMethod ? 'E-posta Adresi' : 'Telefon Numarası',
                    hintText: _isEmailMethod
                        ? 'ornek@mail.com'
                        : '5XX XXX XX XX',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      _isEmailMethod ? Icons.email : Icons.phone,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isEmailMethod
                          ? 'Lütfen e-posta adresinizi girin'
                          : 'Lütfen telefon numaranızı girin';
                    }

                    if (_isEmailMethod) {
                      // Basit e-posta doğrulaması
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                    } else {
                      // Basit telefon numarası doğrulaması
                      if (value.length < 10) {
                        return 'Geçerli bir telefon numarası girin';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Sıfırlama butonu
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Şifremi Sıfırla',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}