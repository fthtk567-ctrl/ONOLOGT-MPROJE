import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onlog_shared/onlog_shared.dart';

class MerchantLegalPage extends StatefulWidget {
  const MerchantLegalPage({super.key});

  @override
  State<MerchantLegalPage> createState() => _MerchantLegalPageState();
}

class _MerchantLegalPageState extends State<MerchantLegalPage> {
  final LegalService _legalService = LegalService();
  bool _hasAllConsents = false;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Oturum açmanız gerekiyor')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Yasal Bilgilendirmeler'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _hasAllConsents ? Icons.verified : Icons.warning,
              color: _hasAllConsents ? Colors.green : Colors.orange,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _hasAllConsents 
                        ? 'Tüm yasal onaylarınız tamamlandı'
                        : 'Bazı yasal onaylar eksik',
                  ),
                ),
              );
            },
            tooltip: _hasAllConsents ? 'Uyumlu' : 'Eksik Onaylar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uyumluluk Durumu
            Card(
              color: _hasAllConsents ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      _hasAllConsents ? Icons.check_circle : Icons.info,
                      color: _hasAllConsents ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasAllConsents 
                                ? 'Yasal Uyumluluk Tamamlandı'
                                : 'Yasal Onaylar Gerekli',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _hasAllConsents ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasAllConsents
                                ? 'Platform kullanımı için gerekli tüm yasal onaylar verilmiştir.'
                                : 'Platform kullanımını sürdürebilmek için bazı yasal belgeleri onaylamanız gerekmektedir.',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Yasal Onay Widget'ı
            LegalConsentWidget(
              userId: user.id,
              userType: 'merchant',
              onConsentChanged: (hasAllConsents) {
                setState(() {
                  _hasAllConsents = hasAllConsents;
                });
              },
            ),

            const SizedBox(height: 24),

            // Aktif Yasal Belgeler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Yasal Belgeleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<LegalDocument>>(
                      stream: _legalService.getActiveDocuments(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final documents = snapshot.data ?? [];
                        if (documents.isEmpty) {
                          return const Text('Henüz yasal belge yayınlanmamış.');
                        }

                        return Column(
                          children: documents.map((doc) => 
                            _buildDocumentListItem(doc, user.id)
                          ).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // KVKK Bilgilendirmesi
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'KVKK Bilgilendirmesi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında, '
                      'kişisel verileriniz ONLOG platformu tarafından güvenli bir '
                      'şekilde işlenmekte ve korunmaktadır.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.verified_user, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'SSL Şifreleme ile korunmaktadır',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // İletişim
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yasal Konularda İletişim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Yasal belgeler ve KVKK ile ilgili sorularınız için:',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'legal@onlog.com.tr',
                          style: TextStyle(
                            color: Colors.blue[600],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          '0850 XXX XX XX',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentListItem(LegalDocument document, String userId) {
    return FutureBuilder<List<LegalConsent>>(
      future: _legalService.getUserConsents(userId).first,
      builder: (context, snapshot) {
        final consents = snapshot.data ?? [];
        final hasConsent = consents.any((consent) => 
            consent.documentId == document.id && consent.isActive);

        return ListTile(
          leading: Icon(
            hasConsent ? Icons.check_circle : Icons.circle_outlined,
            color: hasConsent ? Colors.green : Colors.grey,
          ),
          title: Text(document.title),
          subtitle: Text(document.type.description),
          trailing: TextButton(
            onPressed: () => _showDocumentDetails(document),
            child: const Text('Görüntüle'),
          ),
        );
      },
    );
  }

  void _showDocumentDetails(LegalDocument document) {
    showDialog(
      context: context,
      builder: (context) => LegalDocumentDialog(document: document),
    );
  }
}

