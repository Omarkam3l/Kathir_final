import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../widgets/meal_card.dart';
import '../widgets/restaurant_bottom_nav.dart';

class MealsListScreen extends StatefulWidget {
  const MealsListScreen({super.key});

  @override
  State<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends State<MealsListScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _meals = [];
  bool _isLoading = true;
  String? _restaurantId;
  String? _restaurantName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get restaurant info
      final restaurantRes = await _supabase
          .from('restaurants')
          .select('profile_id, restaurant_name')
          .eq('profile_id', userId)
          .maybeSingle();

      if (restaurantRes != null) {
        _restaurantId = restaurantRes['profile_id'];
        _restaurantName = restaurantRes['restaurant_name'];
      }

      // Get meals
      final mealsRes = await _supabase
          .from('meals')
          .select()
          .eq('restaurant_id', _restaurantId ?? userId)
          .order('created_at', ascending: false);

      _meals = List<Map<String, dynamic>>.from(mealsRes);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _meals.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildMealsList(isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/restaurant-dashboard/add-meal');
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/restaurant-dashboard');
              break;
            case 1:
              context.go('/restaurant-dashboard/orders');
              break;
            case 2:
              // Already on meals
              break;
            case 3:
              // TODO: Implement chats
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chats coming soon')),
              );
              break;
            case 4:
              context.go('/restaurant-dashboard/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.restaurant_menu, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Meals',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  _restaurantName ?? 'Restaurant',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.go('/restaurant/chats');
            },
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No meals yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first meal',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _meals.length,
        itemBuilder: (context, index) {
          return MealCard(
            meal: _meals[index],
            onTap: () async {
              final result = await context.push(
                '/restaurant-dashboard/meal/${_meals[index]['id']}',
              );
              if (result == true) _loadData();
            },
          );
        },
      ),
    );
  }
}
