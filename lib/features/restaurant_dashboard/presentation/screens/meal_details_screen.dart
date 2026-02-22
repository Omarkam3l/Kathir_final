import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';

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

      // Delete meal using safe delete function
      final result = await _supabase.rpc('safe_delete_meal', params: {
        'p_meal_id': widget.mealId,
      });

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/restaurant-dashboard/meals');
        } else {
          // Can't delete - meal is in orders
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Cannot delete meal'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Mark Inactive',
                textColor: Colors.white,
                onPressed: () async {
                  // Mark meal as inactive instead
                  await _supabase
                      .from('meals')
                      .update({'status': 'inactive'})
                      .eq('id', widget.mealId);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meal marked as inactive'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.go('/restaurant-dashboard/meals');
                  }
                },
              ),
            ),
          );
        }
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
      backgroundColor: Colors.black,
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
              : Stack(
                  children: [
                    // Full screen scrollable content
                    CustomScrollView(
                      slivers: [
                        // Hero Image Section
                        SliverToBoxAdapter(
                          child: Stack(
                            children: [
                              // Full image
                              SizedBox(
                                height: 400,
                                width: double.infinity,
                                child: _meal!['image_url'] != null && (_meal!['image_url'] as String).isNotEmpty
                                    ? Image.network(
                                        _meal!['image_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                                      )
                                    : _buildPlaceholderImage(),
                              ),
                              
                              // Gradient overlay
                              Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.transparent,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Back, Edit, and Delete buttons
                              SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Back button
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                                          onPressed: () => context.pop(),
                                        ),
                                      ),
                                      
                                      // Edit and Delete buttons
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.white),
                                              onPressed: () async {
                                                final result = await context.push('/restaurant-dashboard/edit-meal/${widget.mealId}');
                                                if (result == true) {
                                                  _loadMealDetails();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: _isDeleting ? null : _deleteMeal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Curved container overlay at bottom
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(32),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Main Content
                        SliverToBoxAdapter(
                          child: Container(
                            color: bg,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                            child: _buildMealContent(isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildMealContent(bool isDark) {
    final meal = _meal!;
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    final borderColor = isDark ? const Color(0xFF2D4A3A) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Price Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['title'] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(meal['status'] ?? 'active'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'EGP ${meal['discounted_price'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                if ((meal['original_price'] ?? 0) > (meal['discounted_price'] ?? 0))
                  Text(
                    'EGP ${meal['original_price'] ?? 0}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.grey[400],
                      decorationThickness: 2,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Category and Quantity Badges
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF2D1F0D).withValues(alpha: 0.3)
                      : const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark 
                        ? const Color(0xFF4A3319).withValues(alpha: 0.3)
                        : const Color(0xFFFFE4CC),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category, color: Color(0xFFEA580C), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'CATEGORY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEA580C),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meal['category'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF0D2D1F).withValues(alpha: 0.3)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark 
                        ? const Color(0xFF1A4A33).withValues(alpha: 0.3)
                        : const Color(0xFFD1FAE5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'QUANTITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF059669),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${meal['quantity_available'] ?? 0} portions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Expiry Alert
        if (meal['expiry_date'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF2D0D0D).withValues(alpha: 0.3)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF4A1919).withValues(alpha: 0.3)
                    : const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Expires: ${DateTime.parse(meal['expiry_date']).toString().split('.')[0]}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // Description
        if (meal['description'] != null && (meal['description'] as String).isNotEmpty) ...[
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meal['description'],
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Details Card
        Text(
          'Meal Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _buildDetailRow(Icons.attach_money, 'Original Price', 'EGP ${meal['original_price'] ?? 0}'),
              const Divider(height: 24),
              _buildDetailRow(Icons.local_offer, 'Discounted Price', 'EGP ${meal['discounted_price'] ?? 0}'),
              const Divider(height: 24),
              _buildDetailRow(
                Icons.access_time,
                'Expiry Date',
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
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 400,
      color: Colors.grey[800],
      child: const Icon(Icons.restaurant, size: 80, color: Colors.white54),
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
