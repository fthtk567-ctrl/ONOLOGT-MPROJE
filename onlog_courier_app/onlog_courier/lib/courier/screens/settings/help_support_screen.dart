import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım & Destek'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // İletişim kanalları
          const Text(
            'İletişim Kanalları',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildContactCard(
            context,
            icon: Icons.phone,
            title: 'Telefon Desteği',
            subtitle: '0850 123 45 67',
            actionText: 'Ara',
            actionIcon: Icons.call,
            onTap: () async {
              // Telefon uygulaması açılacak
              final Uri callUri = Uri(scheme: 'tel', path: '08501234567');
              if (await canLaunchUrl(callUri)) {
                await launchUrl(callUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Telefon uygulaması açılamadı')),
                  );
                }
              }
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildContactCard(
            context,
            icon: Icons.email,
            title: 'E-posta Desteği',
            subtitle: 'destek@onlog.com',
            actionText: 'E-posta Gönder',
            actionIcon: Icons.send,
            onTap: () async {
              // E-posta uygulaması açılacak
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'destek@onlog.com',
                queryParameters: {
                  'subject': 'ONLOG Kurye Destek Talebi',
                  'body': 'Merhaba ONLOG Destek Ekibi,\n\n'
                }
              );
              
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('E-posta uygulaması açılamadı')),
                  );
                }
              }
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildContactCard(
            context,
            icon: Icons.chat,
            title: 'Canlı Sohbet',
            subtitle: '7/24 canlı destek',
            actionText: 'Sohbet Başlat',
            actionIcon: Icons.chat_bubble,
            onTap: () {
              // Canlı sohbet ekranı açılacak
              _showLiveChatDialog(context);
            },
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Sık Sorulan Sorular
          const Text(
            'Sık Sorulan Sorular',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildFaqItem(
            context,
            question: 'Teslimat görevleri nasıl atanır?',
            answer: 'Teslimat görevleri, konum, araç tipi ve uygunluk durumunuza göre otomatik olarak sistem tarafından atanır. Gelen görevleri kabul etmeniz veya reddetmeniz mümkündür.',
          ),
          
          _buildFaqItem(
            context,
            question: 'Ödemeler ne zaman yapılır?',
            answer: 'Ödemeler haftalık olarak her Cuma günü hesabınıza aktarılır. Kazançlarınızı "Kazanç" ekranından anlık olarak takip edebilirsiniz.',
          ),
          
          _buildFaqItem(
            context,
            question: 'Şifremi unuttum, ne yapmalıyım?',
            answer: 'Giriş ekranındaki "Şifremi Unuttum" bağlantısını kullanarak, kayıtlı e-posta adresinize veya telefon numaranıza sıfırlama bağlantısı alabilirsiniz.',
          ),
          
          _buildFaqItem(
            context,
            question: 'Araç türümü nasıl değiştirebilirim?',
            answer: 'Araç türünüzü değiştirmek için Profil sayfasından "Araç Bilgileri" bölümünü düzenleyebilirsiniz. Değişiklik için gerekli belgeleri yüklemeniz gerekebilir.',
          ),
          
          _buildFaqItem(
            context,
            question: 'Teslimat sırasında sorun yaşarsam ne yapmalıyım?',
            answer: 'Teslimat sırasında herhangi bir sorun yaşarsanız, teslimat detayları ekranındaki "Sorun Bildir" butonunu kullanarak destek ekibimizle iletişime geçebilirsiniz.',
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Hızlı Çözümler
          const Text(
            'Hızlı Çözümler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildQuickSolutionItem(
            context,
            icon: Icons.location_off,
            title: 'Konum Sorunları',
            onTap: () {
              _showLocationTroubleshootingDialog(context);
            },
          ),
          
          _buildQuickSolutionItem(
            context,
            icon: Icons.attach_money,
            title: 'Ödeme Sorunları',
            onTap: () {
              _showPaymentTroubleshootingDialog(context);
            },
          ),
          
          _buildQuickSolutionItem(
            context,
            icon: Icons.app_registration,
            title: 'Uygulama Kullanımı',
            onTap: () {
              _showAppUsageGuideDialog(context);
            },
          ),
          
          const SizedBox(height: 30),
          
          // Geri Bildirim Butonu
          ElevatedButton(
            onPressed: () {
              _showFeedbackDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Geri Bildirim Gönder'),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required IconData actionIcon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
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
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(actionIcon, size: 18),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _buildQuickSolutionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canlı Destek'),
        content: const SizedBox(
          height: 200,
          child: Center(
            child: Text('Canlı destek özelliği yakında eklenecektir.'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLocationTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum Sorunları'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Konum izinlerini kontrol edin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Cihaz ayarlarından uygulamaya konum izni verildiğinden emin olun.',
              ),
              SizedBox(height: 16),
              Text(
                '2. GPS\'in açık olduğunu doğrulayın',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Cihazınızın ayarlarından GPS\'in açık olduğundan emin olun.',
              ),
              SizedBox(height: 16),
              Text(
                '3. Uygulamayı yeniden başlatın',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Uygulamayı tamamen kapatıp yeniden açın.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showPaymentTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Sorunları'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Banka bilgilerinizi kontrol edin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Profil sayfanızdan banka hesap bilgilerinizin doğru olduğundan emin olun.',
              ),
              SizedBox(height: 16),
              Text(
                '2. Ödeme gecikmelerini kontrol edin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Ödemeler genellikle 1-2 iş günü içinde hesabınıza yansır.',
              ),
              SizedBox(height: 16),
              Text(
                '3. Destek ekibiyle iletişime geçin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Sorun devam ederse, ödeme referans numaranızla birlikte destek ekibimizle iletişime geçin.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAppUsageGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulama Kullanım Rehberi'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ana Ekran',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Aktif teslimatları, günlük kazancınızı ve çevrimiçi/çevrimdışı durumunuzu görüntüleyebilirsiniz.',
              ),
              SizedBox(height: 16),
              Text(
                'Kazanç Ekranı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Günlük, haftalık ve aylık kazançlarınızı detaylı olarak takip edebilirsiniz.',
              ),
              SizedBox(height: 16),
              Text(
                'Profil Ekranı',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Kişisel bilgilerinizi, araç bilgilerinizi ve hesap ayarlarınızı yönetebilirsiniz.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Bildirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Uygulamamızı geliştirmemize yardımcı olacak görüşlerinizi paylaşın:'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Görüşlerinizi yazın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (feedbackController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Geri bildiriminiz için teşekkürler!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen bir geri bildirim yazın'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}