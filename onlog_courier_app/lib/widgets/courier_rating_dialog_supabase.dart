import 'package:flutter/material.dart';
import 'package:onlog_shared/services/supabase_service.dart';

/// Kurye Değerlendirme Dialog'u (Supabase Edition)
/// Teslimat tamamlandıktan sonra müşteriden geri bildirim almak için
class CourierRatingDialogSupabase extends StatefulWidget {
  final String orderId;
  final String courierId;
  final String merchantId;

  const CourierRatingDialogSupabase({
    super.key,
    required this.orderId,
    required this.courierId,
    required this.merchantId,
  });

  @override
  State<CourierRatingDialogSupabase> createState() => _CourierRatingDialogSupabaseState();

  /// Static method to show dialog
  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String courierId,
    required String merchantId,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => CourierRatingDialogSupabase(
        orderId: orderId,
        courierId: courierId,
        merchantId: merchantId,
      ),
    );
  }
}

class _CourierRatingDialogSupabaseState extends State<CourierRatingDialogSupabase> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 28),
          SizedBox(width: 12),
          Text('Teslimatı Değerlendir'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yıldız gösterimi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            Text(
              _getRatingText(_rating),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(_rating),
              ),
            ),
            const SizedBox(height: 16),
            
            // Yorum alanı
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Yorumunuz (isteğe bağlı)',
                hintText: 'Deneyiminizi bizimle paylaşın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitRating,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Gönder'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Mükemmel! 🌟';
      case 4:
        return 'Çok İyi 👍';
      case 3:
        return 'Orta 😊';
      case 2:
        return 'Fena Değil 🤔';
      case 1:
        return 'Kötü 😞';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      // Rating'i Supabase'e kaydet
      await SupabaseService.client.from('ratings').insert({
        'order_id': widget.orderId,
        'courier_id': widget.courierId,
        'merchant_id': widget.merchantId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Kurye'nin ortalama rating'ini güncelle
      final ratingsResponse = await SupabaseService.client
          .from('ratings')
          .select('rating')
          .eq('courier_id', widget.courierId);

      if (ratingsResponse.isNotEmpty) {
        final ratings = (ratingsResponse as List)
            .map((r) => (r['rating'] as num).toDouble())
            .toList();
        final average = ratings.reduce((a, b) => a + b) / ratings.length;

        await SupabaseService.client
            .from('users')
            .update({
          'average_rating': average,
          'total_ratings': ratings.length,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.courierId);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Değerlendirmeniz gönderildi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
