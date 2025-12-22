import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

class FixOldDataPage extends StatefulWidget {
  const FixOldDataPage({super.key});

  @override
  State<FixOldDataPage> createState() => _FixOldDataPageState();
}

class _FixOldDataPageState extends State<FixOldDataPage> {
  bool _isProcessing = false;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() => _logs.add('${DateTime.now().toString().substring(11, 19)} - $message'));
  }

  Future<void> _fixMissingFields() async {
    setState(() {
      _isProcessing = true;
      _logs.clear();
    });

    try {
      _addLog('🔍 Eksik alan kontrolü başlatılıyor...');
      
      // Users tablosunu kontrol et
      final users = await SupabaseService.from('users').select();
      _addLog('✅ ${users.length} kullanıcı bulundu');
      
      int fixed = 0;
      for (final user in users) {
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};
        
        if (user['status'] == null) {
          updates['status'] = 'pending';
          needsUpdate = true;
        }
        if (user['is_active'] == null) {
          updates['is_active'] = false;
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          await SupabaseService.from('users')
              .update(updates)
              .eq('id', user['id']);
          fixed++;
        }
      }
      
      _addLog('✅ $fixed kullanıcı güncellendi');
      _addLog('🎉 İşlem tamamlandı!');
      
    } catch (e) {
      _addLog('❌ Hata: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Veri Düzelt'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veri Bakım Araçları',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _fixMissingFields,
              icon: const Icon(Icons.build),
              label: const Text('Eksik Alanları Doldur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            if (_logs.isNotEmpty) ...[
              const Text(
                'İşlem Logları:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
