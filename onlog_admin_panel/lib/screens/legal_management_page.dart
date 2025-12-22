import 'package:flutter/material.dart';

class LegalManagementPage extends StatelessWidget {
  const LegalManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️ Yasal Belgeler'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLegalCard(
            'Kullanım Koşulları',
            'Uygulama kullanım koşulları ve kuralları',
            Icons.description,
            Colors.blue,
          ),
          _buildLegalCard(
            'Gizlilik Politikası',
            'Kişisel verilerin korunması ve gizlilik',
            Icons.privacy_tip,
            Colors.purple,
          ),
          _buildLegalCard(
            'KVKK Metni',
            'Kişisel Verilerin Korunması Kanunu',
            Icons.security,
            Colors.green,
          ),
          _buildLegalCard(
            'Mesafeli Satış Sözleşmesi',
            'Online alışveriş sözleşmesi',
            Icons.shopping_cart,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}
