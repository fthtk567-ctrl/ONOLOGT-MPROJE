import 'package:flutter/material.dart';
import '../../shared/models/courier.dart';
import 'settings/help_support_screen.dart';
import 'settings/change_password_screen.dart';
import 'settings/notification_settings_screen.dart';
import 'settings/edit_personal_info_screen.dart';
import 'settings/edit_bank_info_screen.dart';
import 'settings/edit_vehicle_info_screen.dart';
import '../../services/auth_service.dart';

class CourierProfileScreen extends StatefulWidget {
  const CourierProfileScreen({super.key});

  @override
  State<CourierProfileScreen> createState() => _CourierProfileScreenState();
}

class _CourierProfileScreenState extends State<CourierProfileScreen> {
  // Örnek kurye verisi
  late Courier _courier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourierData();
  }

  Future<void> _loadCourierData() async {
    // Normalde API'dan kurye verisi alınır
    // Burada örnek veri oluşturuyoruz
    await Future.delayed(const Duration(seconds: 1));
    
    _courier = Courier(
      id: '12345',
      name: 'Ahmet Yılmaz',
      email: 'ahmet.yilmaz@example.com',
      phone: '+90 555 123 4567',
      profileImage: 'https://randomuser.me/api/portraits/men/32.jpg',
      vehicleType: VehicleType.motorcycle,
      rating: 4.8,
      totalDeliveries: 287,
      completionRate: 98.5,
      joinDate: DateTime(2022, 3, 15),
      status: CourierStatus.active,
      accountNumber: 'TR12 0000 0000 0000 0000 0000 01',
      bankName: 'XYZ Bank',
      identityNumber: '12345678901',
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(_courier.name),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: 
                                    NetworkImage(_courier.profileImage),
                                backgroundColor: Colors.white,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    // Profil fotoğrafı değiştirme
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Profil fotoğrafı değiştirme özelliği yakında eklenecektir')),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    // Profil bilgileri
                    _buildProfileSummary(),
                    
                    // Performans kartı
                    _buildPerformanceCard(),
                    
                    // Kişisel bilgiler
                    _buildSectionTitle('Kişisel Bilgiler'),
                    _buildPersonalInfoCard(),
                    
                    // Araç bilgileri
                    _buildSectionTitle('Araç Bilgileri'),
                    _buildVehicleInfoCard(),
                    
                    // Ödeme bilgileri
                    _buildSectionTitle('Ödeme Bilgileri'),
                    _buildPaymentInfoCard(),
                    
                    // Ayarlar
                    _buildSectionTitle('Hesap'),
                    _buildAccountSettings(),
                    
                    const SizedBox(height: 24),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Teslimat',
              _courier.totalDeliveries.toString(),
              Icons.delivery_dining,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Puan',
              _courier.rating.toString(),
              Icons.star,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Tamamlama',
              '%${_courier.completionRate}',
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Performans',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _courier.rating / 5,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_courier.rating}/5.0 Puan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < _courier.rating.floor()
                          ? Icons.star
                          : (index < _courier.rating ? Icons.star_half : Icons.star_border),
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_courier.totalDeliveries} teslimat · %${_courier.completionRate} tamamlama oranı',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Ad Soyad', _courier.name, Icons.person),
                const Divider(height: 24),
                _buildInfoRow('Telefon', _courier.phone, Icons.phone),
                const Divider(height: 24),
                _buildInfoRow('E-posta', _courier.email, Icons.email),
                const Divider(height: 24),
                _buildInfoRow('T.C. Kimlik No', _courier.identityNumber, Icons.credit_card),
                const Divider(height: 24),
                _buildInfoRow(
                  'Katılma Tarihi', 
                  '${_courier.joinDate.day}.${_courier.joinDate.month}.${_courier.joinDate.year}',
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPersonalInfoScreen(
                    courier: _courier,
                    onSave: (updatedCourier) {
                      setState(() {
                        _courier = updatedCourier;
                      });
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Düzenle',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    String vehicleTypeText;
    IconData vehicleIcon;

    switch (_courier.vehicleType) {
      case VehicleType.motorcycle:
        vehicleTypeText = 'Motosiklet';
        vehicleIcon = Icons.motorcycle;
        break;
      case VehicleType.car:
        vehicleTypeText = 'Otomobil';
        vehicleIcon = Icons.directions_car;
        break;
      case VehicleType.van:
        vehicleTypeText = 'Van';
        vehicleIcon = Icons.airport_shuttle;
        break;
      case VehicleType.bicycle:
        vehicleTypeText = 'Bisiklet';
        vehicleIcon = Icons.pedal_bike;
        break;
      case VehicleType.truck:
        vehicleTypeText = 'Kamyon';
        vehicleIcon = Icons.local_shipping;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Araç Türü', vehicleTypeText, vehicleIcon),
                const Divider(height: 24),
                _buildInfoRow('Plaka', '34 ABC 123', Icons.directions_car),
                const Divider(height: 24),
                _buildInfoRow('Ehliyet No', '12345678', Icons.card_membership),
              ],
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditVehicleInfoScreen(
                    courier: _courier,
                    onSave: (updatedCourier) {
                      setState(() {
                        _courier = updatedCourier;
                      });
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Düzenle',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Banka', _courier.bankName, Icons.account_balance),
                const Divider(height: 24),
                _buildInfoRow('Hesap No', _courier.accountNumber, Icons.credit_card),
              ],
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBankInfoScreen(
                    courier: _courier,
                    onSave: (updatedCourier) {
                      setState(() {
                        _courier = updatedCourier;
                      });
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Düzenle',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.edit,
          color: Colors.grey,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.lock,
            title: 'Şifreyi Değiştir',
            onTap: () {
              // Şifre değiştirme ekranına git
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsItem(
            context,
            icon: Icons.notifications,
            title: 'Bildirim Ayarları',
            onTap: () {
              // Bildirim ayarları ekranına git
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsItem(
            context,
            icon: Icons.help,
            title: 'Yardım & Destek',
            onTap: () {
              // Yardım ve destek ekranına git
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpAndSupportScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsItem(
            context,
            icon: Icons.logout,
            title: 'Çıkış Yap',
            onTap: () {
              // Çıkış işlemi
              _showLogoutDialog();
            },
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          TextButton(
            onPressed: () {
              // Çıkış işlemi gerçekleştir
              AuthService().logout();
              
              // Dialog'u kapat
              Navigator.pop(context);
              
              // Ana sayfaya yönlendir
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/', 
                (route) => false
              );
            },
            child: const Text(
              'ÇIKIŞ YAP',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}