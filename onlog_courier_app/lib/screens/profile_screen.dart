import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'settings/edit_personal_info_screen_supabase.dart';
import 'settings/change_password_screen_supabase.dart';
import 'settings/edit_bank_info_screen_supabase.dart';
import 'settings/edit_vehicle_info_screen_supabase.dart';
import 'help_support_screen.dart';
import 'courier_login_screen.dart';
import '../services/location_service.dart'; // 🔴 Konum servisi import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final response = await SupabaseService.from('users')
            .select()
            .eq('id', user.id)
            .single();
        setState(() {
          _userData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Profil yükleme hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final user = SupabaseService.currentUser;
      if (user == null) return;

      final bytes = await File(image.path).readAsBytes();
      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Bucket yoksa oluştur (admin olmak gerekebilir - manuel oluşturulmalı)
      // Şimdilik hata yakalayalım ve kullanıcıya bilgi verelim
      try {
        await SupabaseService.client.storage
            .from('profile-photos')
            .uploadBinary(fileName, bytes);
      } catch (storageError) {
        throw Exception('Profil fotoğrafı yüklenemedi. Lütfen yöneticinize başvurun.');
      }

      final photoUrl = SupabaseService.client.storage
          .from('profile-photos')
          .getPublicUrl(fileName);

      await SupabaseService.from('users')
          .update({'profile_photo_url': photoUrl})
          .eq('id', user.id);

      setState(() {
        _userData?['profile_photo_url'] = photoUrl;
        _isUploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profil fotoğrafı güncellendi')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Basit Header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
              child: Column(
                children: [
                  // Profil Fotoğrafı
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadProfilePhoto,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundImage: _userData?['profile_photo_url'] != null
                                ? NetworkImage(_userData!['profile_photo_url'])
                                : null,
                            child: _userData?['profile_photo_url'] == null
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                        ),
                      ),
                      // Kamera İkonu
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // İsim
                  Text(
                    _userData?['full_name'] ?? 'Kullanıcı',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    _userData?['email'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // İstatistikler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        _userData?['total_deliveries']?.toString() ?? '0',
                        'Teslimat',
                        Icons.delivery_dining,
                      ),
                      _buildStatCard(
                        _userData?['service_radius']?.toString() ?? '0',
                        'km Yarıçap',
                        Icons.location_on,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bilgiler Kartı
          SliverToBoxAdapter(child: _buildInfoCard()),

          // Ayarlar
          SliverToBoxAdapter(child: _buildSettingsSection()),

          // Çıkış Butonu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF4CAF50)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final metadata = _userData?['metadata'] as Map<String, dynamic>?;
    final cityFromMetadata = metadata?['city'];
    
    // JSON'lardan araç ve IBAN bilgilerini al
    final commissionSettings = _userData?['commission_settings'] as Map<String, dynamic>?;
    final paymentSettings = _userData?['payment_settings'] as Map<String, dynamic>?;
    
    final vehicleType = commissionSettings?['vehicle_type'] ?? 'Belirtilmemiş';
    final iban = paymentSettings?['iban'] ?? 'Belirtilmemiş';
    
    final infoItems = [
      {
        'icon': Icons.phone,
        'label': 'Telefon',
        'value': _userData?['phone'] ?? 'Belirtilmemiş',
      },
      {
        'icon': Icons.location_city,
        'label': 'Şehir',
        'value': _userData?['city'] ?? cityFromMetadata ?? 'Belirtilmemiş',
      },
      {
        'icon': Icons.motorcycle,
        'label': 'Araç',
        'value': vehicleType,
      },
      {
        'icon': Icons.account_balance,
        'label': 'IBAN',
        'value': iban,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: infoItems.map((item) {
          return ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: const Color(0xFF4CAF50),
              size: 24,
            ),
            title: Text(
              item['label'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            subtitle: Text(
              item['value'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final user = SupabaseService.currentUser;
    if (user == null) return const SizedBox.shrink();
    
    final settings = [
      {
        'icon': Icons.edit,
        'title': 'Profili Düzenle',
        'screen': () => EditPersonalInfoScreenSupabase(courierId: user.id),
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Şifre Değiştir',
        'screen': () => const ChangePasswordScreenSupabase(),
      },
      {
        'icon': Icons.account_balance,
        'title': 'Banka Bilgileri',
        'screen': () => EditBankInfoScreenSupabase(courierId: user.id),
      },
      {
        'icon': Icons.directions_car,
        'title': 'Araç Bilgileri',
        'screen': () => EditVehicleInfoScreenSupabase(courierId: user.id),
      },
      {
        'icon': Icons.help_outline,
        'title': 'Yardım & Destek',
        'screen': () => const HelpSupportScreen(),
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: settings.map((setting) {
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  setting['icon'] as IconData,
                  color: const Color(0xFF4CAF50),
                  size: 24,
                ),
                title: Text(
                  setting['title'] as String,
                  style: const TextStyle(fontSize: 15),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () async {
                  final screen = setting['screen'];
                  if (screen != null) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => (screen as Function)()),
                    );
                    // Eğer düzenleme yapıldıysa (result == true), profil verilerini yenile
                    if (result == true) {
                      _loadUserData();
                    }
                  }
                },
              ),
              if (setting != settings.last) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 🔴 LOGOUT ÖNCESİ: Konum servisini durdur
      print('🛑 Logout - Konum servisi durduruluyor...');
      LocationService.stopLocationTracking();
      
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CourierLoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
