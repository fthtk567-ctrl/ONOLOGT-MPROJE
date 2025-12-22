import 'package:flutter/material.dart';
import '../services/legal_service.dart';

class LegalConsentWidget extends StatefulWidget {
  final String userId;
  final String userType;
  final Function(bool hasAllConsents)? onConsentChanged;
  final bool showAsBottomSheet;
  final bool compactMode;

  const LegalConsentWidget({
    super.key,
    required this.userId,
    required this.userType,
    this.onConsentChanged,
    this.showAsBottomSheet = false,
    this.compactMode = false,
  });

  @override
  State<LegalConsentWidget> createState() => _LegalConsentWidgetState();
}

class _LegalConsentWidgetState extends State<LegalConsentWidget> {
  final LegalService _legalService = LegalService();
  bool _isLoading = false;
  bool _kvkkAccepted = false;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _legalService.getUserConsentSummary(widget.userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          final totalRequired = summary['totalRequired'] as int? ?? 0;
          final totalAccepted = summary['totalAccepted'] as int? ?? 0;
          
          if (totalRequired > 0 && totalAccepted >= totalRequired) {
            _kvkkAccepted = true;
            _termsAccepted = true;
            _notifyParent();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _notifyParent() {
    final allAccepted = _kvkkAccepted && _termsAccepted;
    widget.onConsentChanged?.call(allAccepted);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.compactMode) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yasal Onaylar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CheckboxListTile(
                dense: true,
                value: _kvkkAccepted,
                onChanged: (value) {
                  setState(() {
                    _kvkkAccepted = value ?? false;
                    _notifyParent();
                  });
                },
                title: const Text('KVKK Ayd�nlatma Metni'),
                subtitle: const Text('Okudum, kabul ediyorum'),
              ),
              CheckboxListTile(
                dense: true,
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                    _notifyParent();
                  });
                },
                title: const Text('Kullan�m Ko�ullar�'),
                subtitle: const Text('Okudum, kabul ediyorum'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const Text('Yasal Onaylar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              CheckboxListTile(
                value: _kvkkAccepted,
                onChanged: (value) {
                  setState(() {
                    _kvkkAccepted = value ?? false;
                    _notifyParent();
                  });
                },
                title: const Text('KVKK Ayd�nlatma Metni'),
                subtitle: const Text('Ki�isel verilerinizin i�lenmesine ili�kin'),
              ),
              const Divider(height: 1),
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                    _notifyParent();
                  });
                },
                title: const Text('Kullan�m Ko�ullar�'),
                subtitle: const Text('Hizmet kullan�m �artlar�n� kabul ediyorum'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
