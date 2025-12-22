import 'package:flutter/material.dart';

class CargoHomeScreen extends StatefulWidget {
  const CargoHomeScreen({super.key});

  @override
  State<CargoHomeScreen> createState() => _CargoHomeScreenState();
}

class _CargoHomeScreenState extends State<CargoHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kargo Paneli'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_shipping,
              size: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Kargo Modülü',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kargo modülü henüz geliştirme aşamasındadır.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}