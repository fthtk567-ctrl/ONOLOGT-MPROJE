import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('❓ Yardım & Destek'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İletişim Kartları
            const Text(
              'İletişim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.phone,
              color: Colors.green,
              title: 'Telefon Desteği',
              subtitle: '+90 555 123 4567',
              onTap: () => _makePhoneCall('+905551234567'),
            ),
            _buildContactCard(
              icon: Icons.email,
              color: Colors.blue,
              title: 'E-posta',
              subtitle: 'destek@onlog.com',
              onTap: () => _sendEmail('destek@onlog.com'),
            ),
            _buildContactCard(
              icon: Icons.chat,
              color: Colors.orange,
              title: 'WhatsApp',
              subtitle: 'Hızlı destek için yazın',
              onTap: () => _openWhatsApp('+905551234567'),
            ),
            const SizedBox(height: 32),
            // SSS
            const Text(
              'Sık Sorulan Sorular',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: 'Kazançlarım ne zaman ödeniyor?',
              answer:
                  'Kazançlarınız teslim ettiğiniz siparişler için haftalık olarak hesaplanır ve pazartesi günleri ödeme işlemi başlatılır. Ödeme 2-3 iş günü içinde hesabınıza geçer.',
            ),
            _buildFAQItem(
              question: 'Sipariş nasıl kabul edebilirim?',
              answer:
                  'Ana sayfada gelen siparişleri görebilirsiniz. "Siparişi Kabul Et" butonuna basarak teslimatı üstlenebilirsiniz. Sipariş detaylarını dikkatle okuyun.',
            ),
            _buildFAQItem(
              question: 'Müşteri bilgilerini nasıl görürüm?',
              answer:
                  'Siparişi kabul ettikten sonra, sipariş detaylarında müşteri adı, adresi ve telefon numarasını görebilirsiniz. Teslimat öncesi müşteriyi arayabilirsiniz.',
            ),
            _buildFAQItem(
              question: 'Teslimat sırasında sorun yaşarsam ne yapmalıyım?',
              answer:
                  'Müşteriye ulaşamıyorsanız veya adres bulamıyorsanız, önce müşteriyi arayın. Sorun devam ederse destek hattımızı arayın. Siparişi iptal etmeden önce mutlaka bizimle iletişime geçin.',
            ),
            _buildFAQItem(
              question: 'Komisyon oranları nasıl hesaplanır?',
              answer:
                  'Esnaf kuryeler için %15, SGK\'lı kuryeler için sabit ücret sistemi uygulanır. Kazançlarınız otomatik olarak hesaplanır ve profil sayfanızda görüntüleyebilirsiniz.',
            ),
            _buildFAQItem(
              question: 'Hesabımı nasıl silebilirim?',
              answer:
                  'Hesap silme işlemi için destek ekibimizle iletişime geçmeniz gerekmektedir. E-posta veya telefon ile bizimle iletişime geçin.',
            ),
            const SizedBox(height: 32),
            // Uygulama Bilgileri
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/onlog_logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.local_shipping, size: 60, color: Colors.blue);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ONLOG Kurye App',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versiyon 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _openURL('https://onlog.com/gizlilik'),
                        icon: const Icon(Icons.privacy_tip, size: 16),
                        label: const Text('Gizlilik', style: TextStyle(fontSize: 12)),
                      ),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      TextButton.icon(
                        onPressed: () => _openURL('https://onlog.com/kullanim-sartlari'),
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('Şartlar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=ONLOG Kurye App Destek',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
