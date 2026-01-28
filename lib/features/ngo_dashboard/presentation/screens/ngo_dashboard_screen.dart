import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../../../user_home/data/models/meal_model.dart';
import '../../../user_home/domain/entities/meal.dart';

/// NGO Dashboard screen for viewing and claiming surplus meals
/// Matches the ngo_home_page HTML design
class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  final _supabase = Supabase.instance.client;

  // Filters
  String _selectedFilter = 'all';
  String _searchQuery = '';

  // Stats
  int _mealsClaimed = 0;
  double _carbonSaved = 0;
  int _activeOrders = 0;

  // Meals
  List<Meal> _meals = [];
  List<Meal> _expiringMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadStats(),
        _loadMeals(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get orders for this NGO
      final ordersRes = await _supabase
          .from('orders')
          .select('id, status')
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'confirmed', 'preparing']);
      
      _activeOrders = (ordersRes as List).length;

      // Calculate stats from completed orders (simplified)
      _mealsClaimed = 120; // TODO: Calculate from actual order history
      _carbonSaved = 350.0; // TODO: Calculate from co2_savings

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadMeals() async {
    try {
      // Fetch available donation meals
      final res = await _supabase
          .from('meals')
          .select('*, restaurant:restaurants(id,name,rating,logo_url,verified,reviews_count)')
          .eq('is_donation_available', true)
          .eq('status', 'active')
          .order('expiry', ascending: true);

      final meals = (res as List).map((json) => MealModel.fromJson(json)).toList();
      // Separate expiring soon (within 2 hours)
      final twoHoursFromNow = DateTime.now().add(const Duration(hours: 2));
      _expiringMeals = meals.where((m) => m.expiry.isBefore(twoHoursFromNow)).toList();
      _meals = meals;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading meals: $e');
    }
  }

  List<Meal> get _filteredMeals {
    var result = List<Meal>.from(_meals);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result.where((m) {
        final q = _searchQuery.toLowerCase();
        return m.title.toLowerCase().contains(q) ||
            m.restaurant.name.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q);
      }).toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'vegetarian':
        result = result.where((m) => 
          m.category == 'vegan' || 
          m.title.toLowerCase().contains('veg') ||
          m.description.toLowerCase().contains('vegetarian')
        ).toList();
        break;
      case 'nearby':
        // TODO: Implement location-based filtering
        break;
      case 'large':
        result = result.where((m) => m.quantity >= 20).toList();
        break;
    }

    return result;
  }

  Future<void> _claimMeal(Meal meal) async {
    // Navigate to order flow
    // For now, show a snackbar and mark as claimed
    try {
      await _supabase
          .from('meals')
          .update({'status': 'reserved'})
          .eq('id', meal.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully claimed: ${meal.title}'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error claiming meal: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final bg = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(isDark, user)),
              
              // Search
              SliverToBoxAdapter(child: _buildSearchBar(isDark)),
              
              // Stats
              SliverToBoxAdapter(child: _buildStatsBar(isDark)),
              
              // Filter chips
              SliverToBoxAdapter(child: _buildFilterChips(isDark)),
              
              // Expiring soon section
              if (_expiringMeals.isNotEmpty)
                SliverToBoxAdapter(child: _buildExpiringSoonSection(isDark)),
              
              // Main content
              SliverToBoxAdapter(child: _buildNearbySurplusHeader(isDark)),
              
              // Meals list
              _isLoading
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : _filteredMeals.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No surplus meals available',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildMealCard(_filteredMeals[index], isDark),
                              childCount: _filteredMeals.length,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
      
      // Bottom navigation
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHeader(bool isDark, dynamic user) {
    final greeting = _getGreeting();
    final orgName = user?.organizationName ?? user?.fullName ?? 'NGO';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Anna Nagar, Chennai',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Icon(Icons.expand_more, size: 20),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                        ),
                        child: const Icon(Icons.notifications_outlined, size: 20),
                      ),
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF1A2E22) : Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      border: Border.all(color: AppColors.primaryGreen, width: 2),
                    ),
                    child: const Icon(Icons.handshake, color: AppColors.primaryGreen, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              children: [
                TextSpan(text: '$greeting, '),
                TextSpan(
                  text: orgName,
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.search, color: Colors.grey),
            ),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search rice, bread, or nearby donors...',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
              ),
              child: Icon(Icons.tune, color: AppColors.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Meals Claimed', '$_mealsClaimed', Icons.restaurant, isDark),
          const SizedBox(width: 12),
          _buildStatCard('Carbon Saved', '${_carbonSaved.toInt()}kg', Icons.eco, isDark),
          const SizedBox(width: 12),
          _buildStatCard('Active Orders', '$_activeOrders', Icons.local_shipping, isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F3A2B) : const Color(0xFFE7F3EB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: AppColors.primaryGreen, size: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('all', 'All Listings', null, isDark),
          _buildFilterChip('vegetarian', 'Vegetarian', Icons.grass, isDark),
          _buildFilterChip('nearby', 'Within 5km', Icons.near_me, isDark),
          _buildFilterChip('large', 'Large Qty', Icons.inventory_2, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData? icon, bool isDark) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = value),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        selectedColor: isDark ? Colors.white : Colors.black,
        checkmarkColor: isDark ? Colors.black : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? (isDark ? Colors.black : Colors.white) : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
        backgroundColor: isDark ? const Color(0xFF1A2E22) : Colors.white,
        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildExpiringSoonSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Expiring Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _expiringMeals.take(5).length,
            itemBuilder: (context, index) => _buildUrgentCard(_expiringMeals[index], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentCard(Meal meal, bool isDark) {
    final minutesLeft = meal.pickupMinutesLeft;
    final isVeryUrgent = minutesLeft <= 45;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Stack(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[300],
                  image: meal.imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(meal.imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: meal.imageUrl.isEmpty
                    ? const Center(child: Icon(Icons.restaurant, size: 32, color: Colors.grey))
                    : null,
              ),
              // Time badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVeryUrgent ? Colors.red[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isVeryUrgent ? Colors.red[100]! : Colors.orange[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, size: 12, color: isVeryUrgent ? Colors.red : Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${minutesLeft}m left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isVeryUrgent ? Colors.red : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Restaurant name badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black54, Colors.black26],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        meal.restaurant.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meal.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
                      ),
                      child: Text(
                        meal.donationPrice > 0 ? '₹${meal.donationPrice.toInt()}' : 'Free',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Approx ${meal.quantity} ${meal.unit}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        Text(' 0.8km', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _claimMeal(meal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Claim Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySurplusHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Nearby Surplus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Icon(Icons.sort, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMealCard(Meal meal, bool isDark) {
    final isReserved = meal.status == 'reserved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Opacity(
        opacity: isReserved ? 0.6 : 1.0,
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                    image: meal.imageUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(meal.imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: meal.imageUrl.isEmpty
                      ? const Center(child: Icon(Icons.restaurant, color: Colors.grey))
                      : null,
                ),
                if (meal.category == 'vegan' || meal.category == 'vegetarian')
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Veg', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (isReserved)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Reserved', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.restaurant.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTag('${meal.quantity}${meal.unit.substring(0, 2)}', Icons.scale, isDark),
                      const SizedBox(width: 8),
                      _buildTag('~${(meal.quantity * 3).clamp(10, 100)}', Icons.group, isDark),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Pickup by ${_formatTime(meal.pickupDeadline ?? meal.expiry)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      if (!isReserved)
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('View Details', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3A2B) : const Color(0xFFE7F3EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.grey[300] : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour $period';
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true, isDark),
            _buildNavItem(Icons.receipt_long, 'Orders', false, isDark),
            // Map FAB
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primaryGreen : Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.map, color: isDark ? Colors.black : Colors.white, size: 24),
            ),
            _buildNavItem(Icons.chat_bubble_outline, 'Chats', false, isDark),
            _buildNavItem(Icons.person_outline, 'Profile', false, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, bool isDark) {
    final color = isSelected ? AppColors.primaryGreen : (isDark ? Colors.grey[500] : Colors.grey[400]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
