import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Yardım & Destek'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // İletişim Kartı
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 60,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Size Nasıl Yardımcı Olabiliriz?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Herhangi bir sorun yaşarsanız bizimle iletişime geçin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // İletişim Yöntemleri
            _buildContactOption(
              context,
              icon: Icons.phone,
              title: 'Telefon ile İletişim',
              subtitle: '+90 537 429 1076',
              onTap: () => _launchPhone('+905374291076'),
            ),

            _buildContactOption(
              context,
              icon: Icons.email,
              title: 'E-posta Gönder',
              subtitle: 'destek@onlog.com.tr',
              onTap: () => _launchEmail('destek@onlog.com.tr'),
            ),

            _buildContactOption(
              context,
              icon: Icons.chat_bubble,
              title: 'WhatsApp',
              subtitle: 'Hızlı yanıt için WhatsApp',
              onTap: () => _launchWhatsApp('+905374291076'),
            ),

            // SSS Bölümü
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        const Text(
                          'Sıkça Sorulan Sorular',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildFAQItem(
                    'Teslimat kabul etmediğimde ne olur?',
                    'Teslimatı kabul etmezseniz başka bir kuryeye atanır. Sık reddedilenler öncelik kaybedebilir.',
                  ),
                  _buildFAQItem(
                    'Ödemeler ne zaman yapılır?',
                    'Teslimat tamamlandıktan sonra kazancınız cüzdanınıza yansır. Haftalık veya günlük çekim yapabilirsiniz.',
                  ),
                  _buildFAQItem(
                    'Teslimat sırasında sorun yaşarsam?',
                    'Sorun Bildir bölümünden fotoğraf ve açıklama ile sorun bildirebilirsiniz.',
                  ),
                  _buildFAQItem(
                    'Konumum neden paylaşılmıyor?',
                    'Mesai açık olduğunda konum otomatik paylaşılır. Konum izni verdiğinizden emin olun.',
                  ),
                  _buildFAQItem(
                    'Banka bilgilerimi nasıl güncellerim?',
                    'Profil > Banka Bilgileri menüsünden IBAN ve hesap bilgilerinizi güncelleyebilirsiniz.',
                  ),
                ],
              ),
            ),

            // Uygulama Bilgisi
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'ONLOG Kurye Uygulaması',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versiyon 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2025 ONLOG - Tüm hakları saklıdır',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=ONLOG Destek Talebi',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Telefon numarasını temizle (boşlukları ve + işaretini kaldır)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s+]'), '');
    
    // WhatsApp URI - direkt uygulama açılır
    final Uri uri = Uri.parse('whatsapp://send?phone=$cleanNumber&text=${Uri.encodeComponent('Merhaba, yardıma ihtiyacım var')}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // WhatsApp yüklü değilse web versiyonunu aç
      final Uri webUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent('Merhaba, yardıma ihtiyacım var')}');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
