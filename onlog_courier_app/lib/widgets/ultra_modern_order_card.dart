import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'countdown_timer.dart';

/// 🎨 Ultra Modern Sipariş Kartı
/// Glassmorphism + Gradient + Micro-interactions
class UltraModernOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const UltraModernOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  @override
  State<UltraModernOrderCard> createState() => _UltraModernOrderCardState();
}

class _UltraModernOrderCardState extends State<UltraModernOrderCard> 
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['order_number'] ?? 
        'ONL-${widget.order['id']?.toString().substring(0, 8) ?? 'N/A'}';
    final status = widget.order['status'] ?? 'Bilinmiyor';
    final amount = widget.order['declared_amount'] ?? 0.0;
    final merchantCommission = widget.order['merchant_commission'] ?? 0.0;
    final notes = widget.order['notes'] ?? '';
    final acceptDeadline = widget.order['accept_deadline'] != null 
        ? DateTime.parse(widget.order['accept_deadline']) 
        : null;
    final pickupAddress = _getPickupAddress();
    final deliveryAddress = _getDeliveryAddress();
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceM,
            vertical: AppTheme.spaceS,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: _isPressed 
                ? AppTheme.cardShadow 
                : AppTheme.elevatedCardShadow,
            border: Border.all(
              color: Colors.grey[100]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Stack(
              children: [
                // Gradient overlay (subtle)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _getStatusColor(status).withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Ana İçerik
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(orderId, status),
                      
                      if (acceptDeadline != null) ...[
                        const SizedBox(height: AppTheme.spaceM),
                        _buildCountdown(acceptDeadline),
                      ],
                      
                      const SizedBox(height: AppTheme.spaceL),
                      
                      // Adresler
                      _buildAddressSection(pickupAddress, deliveryAddress),
                      
                      const SizedBox(height: AppTheme.spaceL),
                      
                      // Tutar Bilgisi
                      _buildAmountSection(amount, merchantCommission),
                      
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceM),
                        _buildNotesSection(notes),
                      ],
                      
                      // Aksiyon Butonları (sadece WAITING_COURIER durumunda)
                      if (status == 'WAITING_COURIER' && 
                          widget.onAccept != null && 
                          widget.onReject != null) ...[
                        const SizedBox(height: AppTheme.spaceL),
                        _buildActionButtons(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String orderId, String status) {
    return Row(
      children: [
        // Status Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: _getStatusGradient(status),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(status).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 22,
          ),
        ),
        
        const SizedBox(width: AppTheme.spaceM),
        
        // Sipariş Bilgisi
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#$orderId',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(status),
                  style: AppTheme.caption.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Sağ üst: Zaman veya ikon
        Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey[300],
          size: 24,
        ),
      ],
    );
  }

  Widget _buildCountdown(DateTime deadline) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceS,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4E6), Color(0xFFFFE8CC)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: const Color(0xFFFFB84D).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Color(0xFFFF9500),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CountdownTimer(
              deadline: deadline,
              onExpired: () {}, // Boş callback - kart kendi halledecek
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(String pickup, String delivery) {
    return Column(
      children: [
        _buildCompactAddressRow(
          icon: Icons.store_rounded,
          label: 'ALIŞ',
          address: pickup,
          color: AppTheme.secondaryColor,
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
          child: Row(
            children: [
              const SizedBox(width: 24),
              Container(
                width: 2,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.secondaryColor.withOpacity(0.3),
                      AppTheme.primaryColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        _buildCompactAddressRow(
          icon: Icons.location_on_rounded,
          label: 'TESLİMAT',
          address: delivery,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildCompactAddressRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection(double amount, double commission) {
    final courierEarning = commission;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAmountItem(
            label: 'Tahsilat',
            amount: amount,
            icon: Icons.payments_rounded,
            color: const Color(0xFF0EA5E9),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          _buildAmountItem(
            label: 'Kazancınız',
            amount: courierEarning,
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₺${amount.toStringAsFixed(2)}',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: Colors.amber[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.note_rounded, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.amber[900],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Reddet',
            icon: Icons.close_rounded,
            color: AppTheme.accentColor,
            onPressed: widget.onReject!,
          ),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          flex: 2,
          child: _buildActionButton(
            label: 'Kabul Et',
            icon: Icons.check_rounded,
            color: AppTheme.secondaryColor,
            onPressed: widget.onAccept!,
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper metodlar (mevcut fonksiyonları koruyoruz)
  String _getPickupAddress() {
    try {
      final pickupLocation = widget.order['pickup_location'];
      if (pickupLocation is Map) {
        return pickupLocation['address'] ?? 'Adres bilgisi yok';
      }
      return 'Adres bilgisi yok';
    } catch (e) {
      return 'Adres bilgisi yok';
    }
  }

  String _getDeliveryAddress() {
    final deliveryAddress = widget.order['delivery_address'];
    if (deliveryAddress is String && deliveryAddress.isNotEmpty) {
      return deliveryAddress;
    }
    return 'Adres bilgisi yok';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING_COURIER':
        return const Color(0xFFFF9500);
      case 'ASSIGNED':
        return const Color(0xFF0EA5E9);
      case 'ACCEPTED':
        return const Color(0xFF8B5CF6);
      case 'PICKED_UP':
        return const Color(0xFF6366F1);
      case 'DELIVERED':
        return const Color(0xFF10B981);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  LinearGradient _getStatusGradient(String status) {
    final color = _getStatusColor(status);
    return LinearGradient(
      colors: [color, color.withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING_COURIER':
        return Icons.schedule_rounded;
      case 'ASSIGNED':
        return Icons.person_pin_circle_rounded;
      case 'ACCEPTED':
        return Icons.check_circle_rounded;
      case 'PICKED_UP':
        return Icons.local_shipping_rounded;
      case 'DELIVERED':
        return Icons.task_alt_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING_COURIER':
        return 'Kurye Bekliyor';
      case 'ASSIGNED':
        return 'Atandı';
      case 'ACCEPTED':
        return 'Kabul Edildi';
      case 'PICKED_UP':
        return 'Alındı';
      case 'DELIVERED':
        return 'Teslim Edildi';
      case 'CANCELLED':
        return 'İptal';
      default:
        return status;
    }
  }
}
