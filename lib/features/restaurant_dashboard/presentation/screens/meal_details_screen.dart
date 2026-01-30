import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../widgets/restaurant_bottom_nav.dart';

/// Screen to view meal details with edit and delete options
class MealDetailsScreen extends StatefulWidget {
  final String mealId;

  const MealDetailsScreen({super.key, required this.mealId});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _meal;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadMealDetails();
  }

  Future<void> _loadMealDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('meals')
          .select()
          .eq('id', widget.mealId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _meal = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meal: $e')),
        );
      }
    }
  }

  Future<void> _deleteMeal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      // Delete image from storage if exists
      if (_meal?['image_url'] != null && (_meal!['image_url'] as String).isNotEmpty) {
        final imageUrl = _meal!['image_url'] as String;
        final path = imageUrl.split('/').last;
        await _supabase.storage.from('meal-images').remove([path]);
      }

      // Delete meal record
      await _supabase.from('meals').delete().eq('id', widget.mealId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/restaurant-dashboard/meals');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Meal Details'),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        actions: [
          if (_meal != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/restaurant-dashboard/edit-meal/${widget.mealId}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: _isDeleting ? null : _deleteMeal,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meal == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Meal not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/restaurant-dashboard/meals'),
                        child: const Text('Back to Meals'),
                      ),
                    ],
                  ),
                )
              : _buildMealDetails(isDark),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/restaurant-dashboard/meals');
              break;
            case 1:
              context.go('/restaurant-dashboard/meals');
              break;
            case 2:
              // TODO: Navigate to orders
              break;
            case 3:
              context.go('/restaurant-dashboard/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildMealDetails(bool isDark) {
    final meal = _meal!;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (meal['image_url'] != null && (meal['image_url'] as String).isNotEmpty)
            Image.network(
              meal['image_url'],
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
            )
          else
            _buildPlaceholderImage(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meal['title'] ?? 'Untitled',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildStatusChip(meal['status'] ?? 'active'),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                if (meal['description'] != null && (meal['description'] as String).isNotEmpty) ...[
                  Text(
                    meal['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.category, 'Category', meal['category'] ?? 'N/A'),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.inventory, 'Quantity', '${meal['quantity_available'] ?? 0}'),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.attach_money, 'Original Price', '\$${meal['original_price'] ?? 0}'),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.local_offer, 'Discounted Price', '\$${meal['discounted_price'] ?? 0}'),
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.access_time,
                        'Expiry',
                        meal['expiry_date'] != null
                            ? DateTime.parse(meal['expiry_date']).toString().split('.')[0]
                            : 'N/A',
                      ),
                      if (meal['pickup_deadline'] != null) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          Icons.schedule,
                          'Pickup Deadline',
                          DateTime.parse(meal['pickup_deadline']).toString().split('.')[0],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        break;
      case 'sold':
        color = Colors.orange;
        break;
      case 'expired':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
