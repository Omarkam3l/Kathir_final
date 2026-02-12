import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';

class RecentMealCard extends StatefulWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onTap;
  final VoidCallback? onDonated;

  const RecentMealCard({
    required this.meal,
    required this.onTap,
    this.onDonated,
    super.key,
  });

  @override
  State<RecentMealCard> createState() => _RecentMealCardState();
}

class _RecentMealCardState extends State<RecentMealCard> {
  final _supabase = Supabase.instance.client;
  bool _isDonating = false;

  Future<void> _donateMeal() async {
    final quantity = widget.meal['quantity_available'] ?? 0;
    
    // Confirm donation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Donate Meal'),
        content: Text(
          'Are you sure you want to donate this meal?\n\n'
          'This will:\n'
          '• Set the price to FREE (EGP 0.00)\n'
          '• Notify all users about this free meal\n'
          '• Available quantity: $quantity ${quantity == 1 ? 'portion' : 'portions'}\n'
          '• First come, first served\n'
          '• Cannot be undone',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Donate'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDonating = true);

    try {
      final restaurantId = _supabase.auth.currentUser?.id;
      if (restaurantId == null) throw Exception('Not authenticated');

      debugPrint('🎁 Donating meal: ${widget.meal['id']}');

      // Call RPC function to donate meal
      final response = await _supabase.rpc(
        'donate_meal',
        params: {
          'p_meal_id': widget.meal['id'],
          'p_restaurant_id': restaurantId,
        },
      );

      debugPrint('✅ Donation response: $response');

      if (mounted) {
        // Show success message without revealing user count
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Meal donated successfully! Users have been notified.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Notify parent to refresh
        widget.onDonated?.call();
      }
    } catch (e) {
      debugPrint('❌ Error donating meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error donating meal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDonating = false);
      }
    }
  }

  String _getPrice() {
    // Try discounted_price first, then fall back to original_price
    final discountedPrice = widget.meal['discounted_price'];
    final originalPrice = widget.meal['original_price'];
    
    if (discountedPrice != null && discountedPrice != 0) {
      return (discountedPrice as num).toStringAsFixed(2);
    } else if (originalPrice != null) {
      return (originalPrice as num).toStringAsFixed(2);
    }
    return '0.00';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expiryDate = DateTime.parse(widget.meal['expiry_date']);
    final isExpired = expiryDate.isBefore(DateTime.now());
    final isFree = (widget.meal['discounted_price'] as num?)?.toDouble() == 0.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with FREE badge if donated
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: widget.meal['image_url'] != null
                      ? Image.network(
                          widget.meal['image_url'],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                if (isFree)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (widget.meal['title'] ?? '').isEmpty 
                        ? 'Delicious Meal' 
                        : (widget.meal['title'] ?? 'Delicious Meal'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isFree 
                            ? 'FREE' 
                            : 'EGP ${_getPrice()}',
                        style: TextStyle(
                          color: isFree ? AppColors.primaryGreen : AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: isFree ? 14 : 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExpired 
                              ? Colors.red.withValues(alpha: 0.1)
                              : AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isExpired ? 'Expired' : 'Active',
                          style: TextStyle(
                            fontSize: 10,
                            color: isExpired ? Colors.red : AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Donate button (only show if not free and not expired)
                  if (!isFree && !isExpired)
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: _isDonating ? null : _donateMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isDonating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.volunteer_activism, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Donate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
    );
  }
}
