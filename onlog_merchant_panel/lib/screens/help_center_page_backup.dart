import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help_outline, color: Color(0xFF4CAF50), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Yardım Merkezi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.all(kIsWeb ? 12 : 16),
            children: [
              // İletişim Kartı
              Card(
                child: Padding(
                  padding: EdgeInsets.all(kIsWeb ? 12 : 14),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(kIsWeb ? 8 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.support_agent,
                        size: kIsWeb ? 28 : 32,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(height: kIsWeb ? 8 : 12),
                    Text(
                      'Size Nasıl Yardımcı Olabiliriz?',
                      style: TextStyle(
                        fontSize: kIsWeb ? 15 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: kIsWeb ? 4 : 6),
                    Text(
                      'Herhangi bir sorunuz veya sorununuz için bizimle iletişime geçin',
                      style: TextStyle(
                        fontSize: kIsWeb ? 11 : 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: kIsWeb ? 12 : 16),

            // İletişim Yöntemleri
            _buildSectionTitle('İletişim'),
            _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Telefon Desteği',
            subtitle: '+90 537 429 1076',
            color: Colors.blue,
            onTap: () async {
              final Uri url = Uri.parse('tel:+905374291076');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
            SizedBox(height: kIsWeb ? 6 : 8),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'E-posta Desteği',
              subtitle: 'destek@onlog.com.tr',
              color: Colors.orange,
            onTap: () async {
              final Uri url = Uri.parse('mailto:destek@onlog.com.tr');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
            SizedBox(height: kIsWeb ? 6 : 8),
            _buildContactCard(
              icon: Icons.chat_outlined,
              title: 'WhatsApp Desteği',
              subtitle: '+90 537 429 1076',
              color: Colors.green,
            onTap: () async {
              final Uri url = Uri.parse('https://wa.me/905374291076');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
            SizedBox(height: kIsWeb ? 12 : 16),

            // Sık Sorulan Sorular
            _buildSectionTitle('Sık Sorulan Sorular'),
            _buildFAQCard(
              question: 'Kurye çağırma ücreti var mı?',
              answer: 'Hayır, kurye çağırma ücretsizdir. Sadece teslimat ücreti ve komisyon ödenir.',
            ),
            SizedBox(height: kIsWeb ? 6 : 8),
            _buildFAQCard(
              question: 'Komisyon oranı nasıl hesaplanır?',
              answer: 'Komisyon oranınız %15 + 2 TL sabit ücret + %18 KDV şeklinde hesaplanır.',
            ),
            SizedBox(height: kIsWeb ? 6 : 8),
            _buildFAQCard(
              question: 'Ödemelerim ne zaman yapılır?',
              answer: 'Haftalık borç bakiyeniz her Pazartesi sıfırlanır ve ödeme talebiniz oluşturulur.',
            ),
            SizedBox(height: kIsWeb ? 6 : 8),
            _buildFAQCard(
              question: 'Teslimat iptali yapabilir miyim?',
              answer: 'Kurye atanmadan önce iptal edebilirsiniz. Kurye atandıktan sonra iptaller için destek ekibiyle iletişime geçin.',
            ),
            SizedBox(height: kIsWeb ? 6 : 8),
            _buildFAQCard(
              question: 'Canlı haritada kuryeyi nasıl takip ederim?',
              answer: 'Canlı Harita sekmesinden aktif teslimatlarınızı ve kuryelerin konumlarını gerçek zamanlı olarak görebilirsiniz.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: kIsWeb ? 10 : 12, vertical: kIsWeb ? 0 : 2),
        leading: Container(
          padding: EdgeInsets.all(kIsWeb ? 6 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: kIsWeb ? 16 : 18),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: kIsWeb ? 12 : 13),
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: kIsWeb ? 11 : 12)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: kIsWeb ? 16 : 18),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQCard({
    required String question,
    required String answer,
  }) {
    return Card(
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: kIsWeb ? 12 : 14, vertical: kIsWeb ? 0 : 2),
          childrenPadding: EdgeInsets.fromLTRB(kIsWeb ? 12 : 14, 0, kIsWeb ? 12 : 14, kIsWeb ? 10 : 12),
          leading: Container(
            padding: EdgeInsets.all(kIsWeb ? 6 : 7),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.help_outline,
              color: const Color(0xFF4CAF50),
              size: kIsWeb ? 14 : 16),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: kIsWeb ? 12 : 13,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: kIsWeb ? 11 : 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
