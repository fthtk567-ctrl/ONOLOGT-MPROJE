import 'package:flutter/material.dart';
import '../services/platform_integration_service.dart';

class PlatformSelectionPage extends StatefulWidget {
  const PlatformSelectionPage({super.key});

  @override
  State<PlatformSelectionPage> createState() => _PlatformSelectionPageState();
}

class _PlatformSelectionPageState extends State<PlatformSelectionPage> {
  List<Map<String, dynamic>> _connectedPlatforms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedPlatforms();
  }

  Future<void> _loadConnectedPlatforms() async {
    setState(() => _isLoading = true);
    
    try {
      final connected = await PlatformIntegrationService.getConnectedPlatforms();
      setState(() {
        _connectedPlatforms = connected;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Platform listesi yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isPlatformConnected(String platformId) {
    return _connectedPlatforms.any((p) => p['id'] == platformId);
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'store':
        return Icons.store;
      default:
        return Icons.store;
    }
  }

  void _connectPlatform(Map<String, dynamic> platform) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlatformConnectionPage(
          platform: platform,
          onConnected: () {
            _loadConnectedPlatforms();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Seç'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: PlatformIntegrationService.supportedPlatforms.length,
              itemBuilder: (context, index) {
                final platform = PlatformIntegrationService.supportedPlatforms[index];
                final isConnected = _isPlatformConnected(platform['id']);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isConnected ? Colors.green : Colors.grey,
                      child: Icon(
                        _getIconData(platform['icon']),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      platform['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(platform['description']),
                        const SizedBox(height: 4),
                        Text(
                          isConnected ? 'Bağlı ✓' : 'Bağlanmamış',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: isConnected
                        ? IconButton(
                            icon: const Icon(Icons.settings, color: Colors.blue),
                            onPressed: () {
                              // Platform ayarları sayfası
                            },
                          )
                        : ElevatedButton(
                            onPressed: () => _connectPlatform(platform),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Bağlan'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}

class PlatformConnectionPage extends StatefulWidget {
  final Map<String, dynamic> platform;
  final VoidCallback onConnected;

  const PlatformConnectionPage({
    super.key,
    required this.platform,
    required this.onConnected,
  });

  @override
  State<PlatformConnectionPage> createState() => _PlatformConnectionPageState();
}

class _PlatformConnectionPageState extends State<PlatformConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    // Auth alanları için controller'ları oluştur
    final authFields = List<String>.from(widget.platform['authFields'] ?? []);
    for (String field in authFields) {
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'api_key':
        return 'API Anahtarı';
      case 'seller_id':
        return 'Satıcı ID';
      case 'restaurant_id':
        return 'Restoran ID';
      case 'api_token':
        return 'API Token';
      case 'merchant_id':
        return 'Satıcı ID';
      case 'partner_id':
        return 'Partner ID';
      case 'secret_key':
        return 'Gizli Anahtar';
      case 'username':
        return 'Kullanıcı Adı';
      case 'password':
        return 'Şifre';
      default:
        return field.toUpperCase();
    }
  }

  bool _isPasswordField(String field) {
    return field.contains('password') || field.contains('secret') || field.contains('key');
  }

  Future<void> _connectPlatform() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    try {
      // Credential'ları topla
      final credentials = <String, String>{};
      _controllers.forEach((field, controller) {
        credentials[field] = controller.text.trim();
      });

      final success = await PlatformIntegrationService.connectPlatform(
        widget.platform['id'],
        credentials,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.platform['name']} başarıyla bağlandı!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onConnected();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bağlantı kurulamadı. Lütfen bilgileri kontrol edin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authFields = List<String>.from(widget.platform['authFields'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platform['name']} Bağlantısı'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.platform['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.platform['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bağlantı Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: authFields.length,
                  itemBuilder: (context, index) {
                    final field = authFields[index];
                    final isPassword = _isPasswordField(field);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _controllers[field],
                        decoration: InputDecoration(
                          labelText: _getFieldLabel(field),
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            isPassword ? Icons.lock : Icons.key,
                          ),
                        ),
                        obscureText: isPassword,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return '${_getFieldLabel(field)} gereklidir';
                          }
                          return null;
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConnecting ? null : _connectPlatform,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Bağlantıyı Kur',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




