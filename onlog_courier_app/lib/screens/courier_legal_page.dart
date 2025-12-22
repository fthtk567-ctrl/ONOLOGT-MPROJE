import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onlog_shared/onlog_shared.dart';

class CourierLegalPage extends StatefulWidget {
  const CourierLegalPage({super.key});

  @override
  State<CourierLegalPage> createState() => _CourierLegalPageState();
}

class _CourierLegalPageState extends State<CourierLegalPage> {
  bool _hasAllConsents = false;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Oturum aÃ§manÄ±z gerekiyor')),
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
                        ? 'TÃ¼m yasal onaylarÄ±nÄ±z tamamlandÄ±'
                        : 'BazÄ± yasal onaylar eksik',
                  ),
                ),
              );
            },
            tooltip: _hasAllConsents ? 'Uyumlu' : 'Eksik Onaylar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uyumluluk Durumu
            Card(
              color: _hasAllConsents ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _hasAllConsents ? Icons.check_circle : Icons.info,
                      color: _hasAllConsents ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasAllConsents 
                                ? 'Yasal Uyumluluk TamamlandÄ±'
                                : 'Yasal Onaylar Gerekli',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _hasAllConsents ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasAllConsents
                                ? 'Kurye olarak Ã§alÄ±ÅŸabilmek iÃ§in gerekli tÃ¼m yasal onaylar verilmiÅŸtir.'
                                : 'Kurye olarak Ã§alÄ±ÅŸmaya devam edebilmek iÃ§in bazÄ± yasal belgeleri onaylamanÄ±z gerekmektedir.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Yasal Onay Widget'ı
            LegalConsentWidget(
              userId: user.id,
              userType: 'courier',
              onConsentChanged: (hasAllConsents) {
                setState(() {
                  _hasAllConsents = hasAllConsents;
                });
              },
              compactMode: true,
            ),

            const SizedBox(height: 16),

            // Kurye HaklarÄ±m
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.handshake, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'Kurye HaklarÄ±m',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRightItem('GÃ¼venli Ã§alÄ±ÅŸma ortamÄ± hakkÄ±'),
                    _buildRightItem('Adil Ã¼cretlendirme hakkÄ±'),
                    _buildRightItem('KiÅŸisel veri korunmasÄ± hakkÄ±'),
                    _buildRightItem('Ä°ÅŸ kazasÄ± sigortasÄ± hakkÄ±'),
                    _buildRightItem('Åikayet ve baÅŸvuru hakkÄ±'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Kargo YÃ¶netmeliÄŸi
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Kargo YÃ¶netmeliÄŸi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kargo ve kargoya aracÄ±lÄ±k hizmetleri yÃ¶netmeliÄŸi kapsamÄ±nda '
                      'teslimat iÅŸlemleri sÄ±rasÄ±nda uyulmasÄ± gereken kurallar:',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    _buildRegulationItem('GÃ¶nderi gÃ¼venliÄŸi sorumluluÄŸu'),
                    _buildRegulationItem('Teslimat belgelerinin saklanmasÄ±'),
                    _buildRegulationItem('Hasar/kayÄ±p durumunda bildirim'),
                    _buildRegulationItem('MÃ¼ÅŸteri bilgilerinin gizliliÄŸi'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // KVKK Bilgilendirmesi
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                      'KiÅŸisel verileriniz 6698 sayÄ±lÄ± KVKK kapsamÄ±nda korunmaktadÄ±r. '
                      'Lokasyon, iletiÅŸim ve kimlik bilgileriniz sadece teslimat '
                      'hizmetinin yÃ¼rÃ¼tÃ¼lmesi amacÄ±yla kullanÄ±lmaktadÄ±r.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.verified_user, size: 14, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'SSL Åifreleme ile korunmaktadÄ±r',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // YardÄ±m ve Ä°letiÅŸim
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YardÄ±m ve Ä°letiÅŸim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: const Text('Kurye Destek HattÄ±'),
                      subtitle: const Text('0850 XXX XX XX'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // TODO: Telefon aramasÄ±
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('E-posta DesteÄŸi'),
                      subtitle: const Text('courier@onlog.com.tr'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // TODO: E-posta gÃ¶nder
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.gavel),
                      title: const Text('Yasal Ä°ÅŸler'),
                      subtitle: const Text('legal@onlog.com.tr'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // TODO: E-posta gÃ¶nder
                      },
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

  Widget _buildRightItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegulationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.purple[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

