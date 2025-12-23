import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 🎯 Kompakt Modern Sipariş Kartı
/// Getir/Uber tarzı minimal ve profesyonel tasarım
class CompactOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const CompactOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final externalId = order['external_order_id'];
    final orderNumber = order['order_number'];
    final orderId = externalId?.toString().isNotEmpty == true
        ? externalId.toString()
        : (orderNumber ?? 'ONL-${order['id']?.toString().substring(0, 8) ?? '---'}');
    
    final status = order['status'] ?? 'pending';
    final amount = (order['declared_amount'] ?? 0.0).toDouble();
    final deliveryFee = _calculateDeliveryFee(amount);
    final deliveryAddress = _getDeliveryAddress();
    final merchantName = _getMerchantName();
    final packageCount = order['package_count'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Sipariş No + Tutar
                Row(
                  children: [
                    // Sipariş No
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              orderId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (packageCount > 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${packageCount}x',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Kazanç
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D2A0), Color(0xFF00B894)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B894).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '+₺${deliveryFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                
                // Merchant
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchantName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3436),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Alış noktası',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Delivery Address
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B894), Color(0xFF00A383)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deliveryAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3436),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Teslimat adresi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Distance badge (optional)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            size: 12,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '2.5 km',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Action Buttons (sadece WAITING_COURIER durumunda)
                if (status == 'WAITING_COURIER' && onAccept != null && onReject != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Red Et
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF6B6B),
                              side: BorderSide(
                                color: const Color(0xFFFF6B6B).withOpacity(0.3),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Red Et',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Kabul Et
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B894),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Kabul Et',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDeliveryAddress() {
    try {
      final deliveryLocation = order['delivery_location'];
      if (deliveryLocation is Map) {
        final address = deliveryLocation['address'];
        if (address != null && address.toString().isNotEmpty) {
          return address.toString();
        }
      }
      final deliveryAddress = order['delivery_address'];
      if (deliveryAddress is String && deliveryAddress.isNotEmpty) {
        return deliveryAddress;
      }
      return 'Adres bilgisi yok';
    } catch (e) {
      return 'Adres bilgisi yok';
    }
  }

  String _getMerchantName() {
    try {
      final pickupLocation = order['pickup_location'];
      if (pickupLocation is Map) {
        final address = pickupLocation['address'] ?? '';
        // Test data kontrolü
        if (address.contains('Test Mahallesi') || 
            address.contains('Test Sokak') ||
            address.isEmpty) {
          final merchantName = order['merchant_name'];
          if (merchantName != null && merchantName.toString().isNotEmpty) {
            return merchantName.toString();
          }
          return 'Restoran';
        }
        return address;
      }
      final merchantName = order['merchant_name'];
      if (merchantName != null && merchantName.toString().isNotEmpty) {
        return merchantName.toString();
      }
      return 'Restoran';
    } catch (e) {
      return 'Restoran';
    }
  }

  double _calculateDeliveryFee(double amount) {
    // Basit hesaplama - gerçek değer backend'den gelecek
    return 15.0 + (amount * 0.05);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WAITING_COURIER':
        return const Color(0xFFFFA502);
      case 'ASSIGNED':
      case 'ACCEPTED':
        return const Color(0xFF00B894);
      case 'PICKED_UP':
        return const Color(0xFF00B894);
      case 'DELIVERED':
        return const Color(0xFF636E72);
      default:
        return const Color(0xFF2D3436);
    }
  }
}
