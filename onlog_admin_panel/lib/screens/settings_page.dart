import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'dart:html' as html;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Ayarlar'),
        backgroundColor: Colors.blueGrey,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Ayarları'),
            subtitle: const Text('Hesap bilgilerinizi düzenleyin'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Bildirimler'),
            subtitle: const Text('Bildirim tercihlerinizi yönetin'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Güvenlik'),
            subtitle: const Text('Şifre ve güvenlik ayarları'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Versiyon 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Hesabınızdan çıkış yapın'),
            onTap: () async {
              await SupabaseService.client.auth.signOut();
              // Sayfayı yeniden yükle (web için)
              html.window.location.reload();
            },
          ),
        ],
      ),
    );
  }
}
