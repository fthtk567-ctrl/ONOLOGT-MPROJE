import 'package:flutter/material.dart';
import '../../shared/models/delivery_task.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final DeliveryTask delivery;
  
  const DeliveryDetailsScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  DeliveryStatus _currentStatus = DeliveryStatus.assigned;
  
  @override
  void initState() {
    super.initState();
    _currentStatus = widget.delivery.status;
  }

  void _updateStatus(DeliveryStatus newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    
    // Normalde API'ye durum güncellemesi gönderilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teslimat durumu güncellendi: ${_getStatusText(newStatus)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Beklemede';
      case DeliveryStatus.assigned:
        return 'Atandı';
      case DeliveryStatus.pickedUp:
        return 'Alındı';
      case DeliveryStatus.delivered:
        return 'Teslim Edildi';
      case DeliveryStatus.cancelled:
        return 'İptal Edildi';
      case DeliveryStatus.returned:
        return 'İade Edildi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teslimat #${widget.delivery.id}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teslimat durum kartı
            _buildStatusCard(),

            // Adres bilgileri
            _buildSectionTitle('Adres Bilgileri'),
            _buildAddressCard(
              'Alış Adresi',
              widget.delivery.pickupAddress,
              Icons.location_on,
              Colors.blue,
              () => _openMapNavigation(widget.delivery.pickupAddress, true),
            ),
            _buildAddressCard(
              'Teslimat Adresi',
              widget.delivery.deliveryAddress,
              Icons.flag,
              Colors.red,
              () => _openMapNavigation(widget.delivery.deliveryAddress, false),
            ),

            // Müşteri bilgileri
            _buildSectionTitle('Müşteri Bilgileri'),
            _buildInfoCard(),

            // Teslimat detayları
            _buildSectionTitle('Teslimat Detayları'),
            _buildDeliveryDetails(),

            // Durum güncelleme düğmeleri
            _buildSectionTitle('Durum Güncelleme'),
            _buildStatusUpdateButtons(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText = _getStatusText(_currentStatus);
    
    switch (_currentStatus) {
      case DeliveryStatus.pending:
        statusColor = Colors.grey;
        break;
      case DeliveryStatus.assigned:
        statusColor = Colors.blue;
        break;
      case DeliveryStatus.pickedUp:
        statusColor = Colors.orange;
        break;
      case DeliveryStatus.delivered:
        statusColor = Colors.green;
        break;
      case DeliveryStatus.cancelled:
        statusColor = Colors.red;
        break;
      case DeliveryStatus.returned:
        statusColor = Colors.purple;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.delivery_dining,
            color: statusColor,
            size: 40,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Son Güncelleme: ${DateTime.now().hour}:${DateTime.now().minute}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    String title,
    String address,
    IconData icon,
    Color color,
    VoidCallback onNavigate,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    address,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.directions, color: color),
              onPressed: onNavigate,
              tooltip: 'Yol Tarifi Al',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              'Müşteri Adı',
              widget.delivery.customerName,
              Icons.person,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Telefon',
              widget.delivery.customerPhone,
              Icons.phone,
              onTap: () => _callCustomer(widget.delivery.customerPhone),
            ),
            if (widget.delivery.notes != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                'Not',
                widget.delivery.notes!,
                Icons.note,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Column(
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
            if (onTap != null) ...[
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  'Ücret',
                  '${widget.delivery.price.toStringAsFixed(2)} ₺',
                  Icons.attach_money,
                ),
                _buildDetailItem(
                  'Mesafe',
                  '${widget.delivery.distance ?? "?"} km',
                  Icons.straighten,
                ),
                _buildDetailItem(
                  'Ağırlık',
                  '${widget.delivery.weight ?? "?"} kg',
                  Icons.line_weight,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  'Sipariş Zamanı',
                  '${widget.delivery.createdAt.hour}:${widget.delivery.createdAt.minute}',
                  Icons.access_time,
                ),
                _buildDetailItem(
                  'Kod',
                  widget.delivery.deliveryCode ?? '-',
                  Icons.qr_code,
                ),
                _buildDetailItem(
                  'ID',
                  '#${widget.delivery.id}',
                  Icons.tag,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
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

  Widget _buildStatusUpdateButtons() {
    // Durum güncelleme butonlarını mevcut duruma göre göster
    List<Widget> buttons = [];
    
    switch (_currentStatus) {
      case DeliveryStatus.pending:
      case DeliveryStatus.assigned:
        buttons.add(
          _buildActionButton(
            'Teslimatı Aldım',
            Icons.flight_takeoff,
            Colors.blue,
            () => _updateStatus(DeliveryStatus.pickedUp),
          ),
        );
        break;
        
      case DeliveryStatus.pickedUp:
        buttons.add(
          _buildActionButton(
            'Teslim Edildi',
            Icons.check_circle,
            Colors.green,
            () => _updateStatus(DeliveryStatus.delivered),
          ),
        );
        buttons.add(
          _buildActionButton(
            'İade Edildi',
            Icons.assignment_return,
            Colors.orange,
            () => _updateStatus(DeliveryStatus.returned),
          ),
        );
        break;
        
      case DeliveryStatus.delivered:
      case DeliveryStatus.returned:
      case DeliveryStatus.cancelled:
        buttons.add(
          _buildActionButton(
            'Teslimat Tamamlandı',
            Icons.check_circle,
            Colors.grey,
            null,
          ),
        );
        break;
    }
    
    // İptal butonunu her zaman göster (tamamlanmış teslimatlar hariç)
    if (_currentStatus != DeliveryStatus.delivered && 
        _currentStatus != DeliveryStatus.cancelled &&
        _currentStatus != DeliveryStatus.returned) {
      buttons.add(
        _buildActionButton(
          'İptal Et',
          Icons.cancel,
          Colors.red,
          () => _showCancellationDialog(),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: buttons,
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  void _openMapNavigation(String address, bool isPickup) {
    // Normalde harita uygulamasına yönlendirilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPickup 
              ? 'Alış adresine yönlendiriliyorsunuz' 
              : 'Teslimat adresine yönlendiriliyorsunuz'
        ),
      ),
    );
  }

  void _callCustomer(String phoneNumber) {
    // Normalde telefon uygulamasına yönlendirilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$phoneNumber aranıyor...'),
      ),
    );
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teslimatı İptal Et'),
        content: const Text(
          'Bu teslimatı iptal etmek istediğinizden emin misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('VAZGEÇ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(DeliveryStatus.cancelled);
            },
            child: const Text(
              'İPTAL ET',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}