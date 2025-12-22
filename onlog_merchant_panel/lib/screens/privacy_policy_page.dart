import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
              child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF4CAF50), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Gizlilik Politikası',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Başlık Kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      size: 48,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gizlilik Politikası',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Son Güncellenme: 28 Ekim 2025',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // İçerik Bölümleri
          _buildSection(
            title: '1. Toplanan Bilgiler',
            content: '''ONLOG olarak, hizmetlerimizi sunabilmek için aşağıdaki bilgileri topluyoruz:

• Hesap Bilgileri: E-posta, telefon, işletme adı
• İşletme Bilgileri: Adres, konum, çalışma saatleri
• Teslimat Bilgileri: Sipariş detayları, alıcı bilgileri
• Cihaz Bilgileri: IP adresi, tarayıcı türü
• Konum Bilgileri: GPS koordinatları (sadece kurye uygulaması)''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '2. Bilgilerin Kullanımı',
            content: '''Toplanan bilgiler şu amaçlarla kullanılır:

• Kurye-işletme eşleştirme ve teslimat yönetimi
• Ödeme işlemleri ve komisyon hesaplamaları
• Bildirim gönderimi (sipariş durumu, yeni teslimat)
• Hizmet kalitesinin iyileştirilmesi
• Güvenlik ve dolandırıcılık önleme''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '3. Bilgi Güvenliği',
            content: '''Verilerinizin güvenliği önceliğimizdir:

• SSL/TLS şifreleme ile veri iletimi
• Supabase güvenli bulut altyapısı
• Düzenli güvenlik denetimleri
• Rol tabanlı erişim kontrolü (RLS)
• Şifrelerin hash'lenerek saklanması''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '4. Bilgi Paylaşımı',
            content: '''Bilgileriniz yalnızca şu durumlarda paylaşılır:

• Teslimat için kuryelerle sipariş detayları
• Ödeme işlemleri için bankalar/ödeme sağlayıcıları
• Yasal zorunluluklar (mahkeme kararı, vb.)
• Hizmet sağlayıcılarla (sunucu, SMS, vb.)

Bilgileriniz hiçbir zaman üçüncü taraflara satılmaz veya reklam amaçlı kullanılmaz.''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '5. Çerezler ve Takip',
            content: '''Web uygulamamızda şu teknolojiler kullanılır:

• Oturum çerezleri (giriş durumu)
• Yerel depolama (tercihler)
• Firebase Cloud Messaging (bildirimler)
• Google Analytics (anonim kullanım istatistikleri)''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '6. Haklarınız',
            content: '''KVKK kapsamında haklarınız:

• Verilerinize erişim talep etme
• Hatalı verilerin düzeltilmesini isteme
• Verilerin silinmesini talep etme
• İşleme itiraz etme
• Veri taşınabilirliği

Bu haklarınızı kullanmak için destek@onlog.com.tr adresine başvurabilirsiniz.''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '7. Çocukların Gizliliği',
            content: '''ONLOG hizmetleri 18 yaş altı kullanıcılara yönelik değildir. Bilerek 18 yaş altı bireylerden bilgi toplamıyoruz.''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '8. Değişiklikler',
            content: '''Bu gizlilik politikası gerektiğinde güncellenebilir. Önemli değişiklikler bildirim veya e-posta yoluyla duyurulur.''',
          ),
          const SizedBox(height: 12),

          _buildSection(
            title: '9. İletişim',
            content: '''Gizlilik politikası hakkında sorularınız için:

E-posta: destek@onlog.com.tr
Telefon: +90 537 429 1076
Adres: Çumra/KONYA''',
          ),
          const SizedBox(height: 24),

          // Kabul Butonu
          Card(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ONLOG uygulamasını kullanarak bu gizlilik politikasını kabul etmiş sayılırsınız.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
