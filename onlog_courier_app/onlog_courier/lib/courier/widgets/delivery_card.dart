import 'package:flutter/material.dart';
import '../../shared/models/delivery_task.dart';

class DeliveryCard extends StatelessWidget {
  final DeliveryTask delivery;
  final VoidCallback onTap;
  
  const DeliveryCard({
    super.key, 
    required this.delivery, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${delivery.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const Divider(height: 24),
              _buildAddressRow(
                Icons.location_on, 
                'Alınacak Yer', 
                delivery.pickupAddress,
              ),
              const SizedBox(height: 16),
              _buildAddressRow(
                Icons.flag, 
                'Teslim Edilecek Yer', 
                delivery.deliveryAddress,
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${delivery.price.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (delivery.distance != null)
                    Text(
                      '${delivery.distance!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;
    
    switch (delivery.status) {
      case DeliveryStatus.pending:
        color = Colors.grey;
        text = 'Beklemede';
        break;
      case DeliveryStatus.assigned:
        color = Colors.blue;
        text = 'Atandı';
        break;
      case DeliveryStatus.pickedUp:
        color = Colors.orange;
        text = 'Alındı';
        break;
      case DeliveryStatus.delivered:
        color = Colors.green;
        text = 'Teslim Edildi';
        break;
      case DeliveryStatus.cancelled:
        color = Colors.red;
        text = 'İptal Edildi';
        break;
      case DeliveryStatus.returned:
        color = Colors.purple;
        text = 'İade Edildi';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String title, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon, 
          size: 20, 
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}