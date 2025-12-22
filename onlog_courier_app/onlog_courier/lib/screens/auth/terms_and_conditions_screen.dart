import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Şartları & Gizlilik Politikası'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ONLOG Kurye Uygulaması Kullanım Şartları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Genel Kullanım Şartları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ONLOG Kurye uygulamasını kullanarak aşağıdaki şartları kabul etmiş sayılırsınız. Bu uygulama, kurye hizmetlerinin yönetimi, teslimatların takibi ve kurye ödemelerinin hesaplanması için tasarlanmıştır.\n\n'
                'Bu uygulamayı kullanabilmek için 18 yaşını doldurmuş olmanız ve yasal ehliyete sahip olmanız gerekmektedir. Uygulama içerisinde yapacağınız tüm işlemlerden siz sorumlusunuz.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Hesap Güvenliği',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ONLOG Kurye uygulamasında oluşturduğunuz hesabın güvenliği tamamen sizin sorumluluğunuzdadır. Şifrenizi kimseyle paylaşmamalı ve güvenli bir şekilde saklamalısınız. Hesabınızda gerçekleşen her türlü aktiviteden siz sorumlusunuz.\n\n'
                'Herhangi bir güvenlik ihlali durumunda derhal ONLOG destek ekibiyle iletişime geçmeniz gerekmektedir.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '3. Teslimat Kuralları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kurye olarak, size atanan teslimatları zamanında ve güvenli bir şekilde gerçekleştirmekle yükümlüsünüz. Teslimatlarda gecikme yaşanması durumunda müşterilere ve ONLOG\'a bilgi vermeniz gerekmektedir.\n\n'
                'Teslimat sırasında güvenlik önlemlerine uymalı, trafik kurallarına dikkat etmeli ve teslimatları profesyonel bir şekilde gerçekleştirmelisiniz.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '4. Gizlilik Politikası',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ONLOG, kişisel verilerinizin gizliliğine önem verir. Uygulamayı kullanırken sağladığınız bilgiler, teslimat hizmetlerinin yürütülmesi, ödeme işlemlerinin gerçekleştirilmesi ve yasal yükümlülüklerin yerine getirilmesi amacıyla işlenir.\n\n'
                'Toplanan veriler arasında adınız, iletişim bilgileriniz, konum bilgileriniz ve ödeme bilgileriniz bulunmaktadır. Bu bilgiler, hizmet kalitesini artırmak ve yasal gereklilikleri yerine getirmek için kullanılır.\n\n'
                'Kişisel verileriniz, yasal zorunluluklar dışında üçüncü taraflarla paylaşılmaz.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '5. Ödeme Koşulları',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ONLOG Kurye uygulaması üzerinden gerçekleştirdiğiniz teslimatlar için ödeme, belirlenen tarihlerde hesabınıza aktarılacaktır. Ödeme miktarları, teslimat mesafesi, ağırlık ve diğer faktörlere göre belirlenir.\n\n'
                'Ödemelerinizle ilgili herhangi bir sorun yaşarsanız, ONLOG destek ekibiyle iletişime geçebilirsiniz.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '6. Fikri Mülkiyet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ONLOG Kurye uygulaması ve içeriğindeki tüm materyaller, ONLOG\'un fikri mülkiyetidir. Uygulama içeriğini kopyalamak, dağıtmak veya değiştirmek yasaktır.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '7. Değişiklikler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ONLOG, bu kullanım şartlarını ve gizlilik politikasını dilediği zaman değiştirme hakkını saklı tutar. Değişiklikler, uygulama üzerinden duyurulacaktır.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '8. İletişim',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Herhangi bir soru, öneri veya şikayetiniz varsa, ONLOG destek ekibiyle iletişime geçebilirsiniz:\n\n'
                'E-posta: destek@onlog.com\n'
                'Telefon: 0850 123 45 67',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Kabul Ediyorum'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}