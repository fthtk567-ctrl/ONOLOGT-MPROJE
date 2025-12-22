import 'package:flutter/material.dart';
import 'package:onlog_shared/onlog_shared.dart';

class PlatformHelper {
  static IconData getPlatformIcon(OrderPlatform platform) {
    switch (platform) {
      case OrderPlatform.trendyol:
        return Icons.shopping_bag;
      case OrderPlatform.yemeksepeti:
        return Icons.restaurant;
      case OrderPlatform.getir:
        return Icons.delivery_dining;
      case OrderPlatform.bitaksi:
        return Icons.medical_services;
      case OrderPlatform.manuel:
        return Icons.edit_note;
    }
  }

  static Color getPlatformColor(OrderPlatform platform) {
    switch (platform) {
      case OrderPlatform.trendyol:
        return Colors.orange;
      case OrderPlatform.yemeksepeti:
        return Colors.red;
      case OrderPlatform.getir:
        return Colors.purple;
      case OrderPlatform.bitaksi:
        return Colors.blue;
      case OrderPlatform.manuel:
        return const Color(0xFF4CAF50); // Fıstık yeşili
    }
  }

  static Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.red;
      case OrderStatus.assigned:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.pickedUp:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions;
      case OrderStatus.assigned:
        return Icons.person_add;
      case OrderStatus.preparing:
        return Icons.kitchen;
      case OrderStatus.ready:
        return Icons.check_circle_outline;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  final bool showIcon;

  const OrderStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PlatformHelper.getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PlatformHelper.getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              PlatformHelper.getStatusIcon(status),
              size: 14,
              color: PlatformHelper.getStatusColor(status),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _getStatusDisplayName(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: PlatformHelper.getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Kurye Bekliyor';
      case OrderStatus.assigned:
        return 'Kurye Atandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.ready:
        return 'Hazır';
      case OrderStatus.pickedUp:
        return 'Kurye Aldı';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}

class PlatformChip extends StatelessWidget {
  final OrderPlatform platform;
  final bool showIcon;

  const PlatformChip({
    super.key,
    required this.platform,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PlatformHelper.getPlatformColor(platform).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PlatformHelper.getPlatformColor(platform).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              PlatformHelper.getPlatformIcon(platform),
              size: 14,
              color: PlatformHelper.getPlatformColor(platform),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _getPlatformDisplayName(platform),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: PlatformHelper.getPlatformColor(platform),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlatformDisplayName(OrderPlatform platform) {
    switch (platform) {
      case OrderPlatform.trendyol:
        return 'Trendyol';
      case OrderPlatform.yemeksepeti:
        return 'Yemeksepeti';
      case OrderPlatform.getir:
        return 'Getir';
      case OrderPlatform.bitaksi:
        return 'BiTaksi';
      case OrderPlatform.manuel:
        return 'Manuel';
    }
  }
}




