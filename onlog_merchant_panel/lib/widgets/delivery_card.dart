import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';

/// Teslimat Kartı Widget'ı
/// 
/// Merchant panel'de teslimat taleplerini gösterir.
/// Platform kaynağına göre renkli badge ekler.
class DeliveryCard extends StatelessWidget {
  final DeliveryRequest delivery;
  final VoidCallback? onCallCourier;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCancel;

  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onCallCourier,
    this.onViewDetails,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ KAYNAK BADGE'İ (Platform siparişleri için)
          if (delivery.isExternalOrder) _buildSourceBadge(),
          
          // Teslimat içeriği
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık satırı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teslimat #${delivery.id.substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (delivery.merchantName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              delivery.merchantName!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Paket bilgisi
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, 
                      size: 18, 
                      color: Colors.grey[700]
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${delivery.packageCount} paket',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.payments_outlined, 
                      size: 18, 
                      color: Colors.grey[700]
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${delivery.declaredAmount.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                // Notlar
                if (delivery.notes != null && delivery.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.amber[900]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            delivery.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[900],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Zaman bilgisi
                Text(
                  'Oluşturuldu: ${_formatDateTime(delivery.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Aksiyon butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancel != null && delivery.status == 'pending')
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('İptal'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    if (onViewDetails != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Detay'),
                      ),
                    ],
                    if (onCallCourier != null && delivery.status == 'pending') ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onCallCourier,
                        icon: const Icon(Icons.delivery_dining, size: 18),
                        label: const Text('Kurye Çağır'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⭐ Kaynak Badge'i (Platform bilgisi)
  Widget _buildSourceBadge() {
    final sourceInfo = _getSourceInfo(delivery.source);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: sourceInfo['color'] as Color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            sourceInfo['icon'] as IconData,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            sourceInfo['label'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (delivery.externalOrderId != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                delivery.externalOrderId!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Platform bilgilerini döndür (renk, ikon, etiket)
  Map<String, dynamic> _getSourceInfo(String source) {
    switch (source) {
      case 'yemek_app':
        return {
          'label': '🍕 YEMEK APP',
          'color': const Color(0xFFFF6B35), // Turuncu
          'icon': Icons.restaurant_menu,
        };
      case 'trendyol':
        return {
          'label': '🛍️ TRENDYOL',
          'color': const Color(0xFFF27A1A), // Trendyol turuncusu
          'icon': Icons.shopping_bag,
        };
      case 'getir':
        return {
          'label': '🛵 GETİR',
          'color': const Color(0xFF5D3EBC), // Getir moru
          'icon': Icons.delivery_dining,
        };
      case 'yemeksepeti':
        return {
          'label': '🍔 YEMEK SEPETİ',
          'color': const Color(0xFFFF4500), // Kırmızı-turuncu
          'icon': Icons.fastfood,
        };
      default:
        return {
          'label': source.toUpperCase(),
          'color': Colors.grey[700],
          'icon': Icons.help_outline,
        };
    }
  }

  /// Durum chip'i
  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;

    switch (delivery.status) {
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Bekliyor';
        break;
      case 'assigned':
        chipColor = Colors.blue;
        statusText = 'Atandı';
        break;
      case 'picked_up':
        chipColor = Colors.purple;
        statusText = 'Alındı';
        break;
      case 'delivered':
        chipColor = Colors.green;
        statusText = 'Teslim Edildi';
        break;
      case 'cancelled':
        chipColor = Colors.red;
        statusText = 'İptal';
        break;
      default:
        chipColor = Colors.grey;
        statusText = delivery.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1.5),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Tarih formatla
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
