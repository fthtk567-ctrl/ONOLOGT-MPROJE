import 'package:flutter/material.dart';

class CompetitorAnalysisPage extends StatelessWidget {
  const CompetitorAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rakip Analizi'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Rakip Analizi Sayfası',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
