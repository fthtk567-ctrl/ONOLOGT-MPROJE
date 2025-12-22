import 'package:flutter/material.dart';

class DemoAccountsWidget extends StatelessWidget {
  final Function(String, String) onSelect;
  
  const DemoAccountsWidget({
    super.key, 
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Demo Hesaplar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _buildDemoAccountItem(
            'Kurye Demo', 
            'demo@onlog.com', 
            'demo123',
            onTap: () => onSelect('demo@onlog.com', 'demo123'),
          ),
          const SizedBox(height: 8),
          _buildDemoAccountItem(
            'Admin Hesabı', 
            'admin@onlog.com', 
            'admin123',
            onTap: () => onSelect('admin@onlog.com', 'admin123'),
          ),
          const SizedBox(height: 8),
          _buildDemoAccountItem(
            'Telefon Girişi', 
            '5551234567', 
            '123456',
            onTap: () => onSelect('5551234567', '123456'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDemoAccountItem(String title, String username, String password, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kullanıcı: $username',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Şifre: $password',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.login, size: 16),
          ],
        ),
      ),
    );
  }
}