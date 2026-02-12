import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/data/models/meal_model.dart';
import '../../../user_home/domain/entities/meal.dart';
import 'ngo_cart_viewmodel.dart';

class NgoHomeViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  bool isLoading = false; // Start as false, will be set to true when loading
  String? error;
  
  // Constructor with logging
  NgoHomeViewModel() {
    debugPrint('🏗️ NgoHomeViewModel created');
    debugPrint('📊 Initial state - isLoading: $isLoading, meals: ${meals.length}');
  }
  
  // Filters
  String selectedFilter = 'all';
  String searchQuery = '';
  
  // Location
  String currentLocation = 'Cairo, Egypt';
  
  // Stats
  int mealsClaimed = 0;
  double carbonSaved = 0;
  int activeOrders = 0;
  bool hasNotifications = true;
  
  // Meals
  List<Meal> meals = [];
  List<Meal> expiringMeals = [];
  
  // Smart loading: TTL tracking
  DateTime? _lastFetchTime;
  static const _ttl = Duration(minutes: 2);

  bool get _isDataStale {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _ttl;
  }

  /// Smart load: only fetch if data is missing or stale
  Future<void> loadIfNeeded() async {
    // Always load on first call
    if (_lastFetchTime == null) {
      debugPrint('🔄 First load - fetching data...');
      await loadData();
      return;
    }
    
    // Skip if data exists and is fresh
    if (meals.isNotEmpty && !_isDataStale) {
      debugPrint('✓ Using cached data (${meals.length} meals)');
      return;
    }
    
    // Skip if already loading (in-flight guard)
    if (isLoading) {
      debugPrint('⏳ Already loading, skipping...');
      return;
    }
    
    debugPrint('🔄 Data stale or empty - fetching...');
    await loadData();
  }

  List<Meal> get filteredMeals {
    var result = List<Meal>.from(meals);

    // Apply search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((m) {
        return m.title.toLowerCase().contains(q) ||
            m.restaurant.name.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q);
      }).toList();
    }

    // Apply category filter
    switch (selectedFilter) {
      case 'vegetarian':
        result = result.where((m) =>
          m.category.toLowerCase().contains('veg') ||
          m.title.toLowerCase().contains('veg')
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

  Future<void> loadData({bool forceRefresh = false}) async {
    debugPrint('📊 loadData called - forceRefresh: $forceRefresh, hasListeners: $hasListeners');
    
    // Skip if data is fresh and not forcing refresh
    if (!forceRefresh && meals.isNotEmpty && !_isDataStale) {
      debugPrint('✓ Data is fresh, skipping load');
      return;
    }
    
    isLoading = true;
    error = null;
    
    // CRITICAL: Notify immediately to show loading state
    notifyListeners();

    try {
      debugPrint('🔄 Starting data fetch...');
      await Future.wait([
        _loadStats(),
        _loadMeals(),
      ]);
      _lastFetchTime = DateTime.now();
      debugPrint('✅ Data fetch complete - ${meals.length} meals loaded');
    } catch (e) {
      error = e.toString();
      debugPrint('❌ Data fetch failed: $e');
    } finally {
      isLoading = false;
      debugPrint('🔔 Notifying listeners - meals: ${meals.length}, error: $error');
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ No authenticated user for stats loading');
      return;
    }

    try {
      // Check if NGO record exists
      final ngoCheck = await _supabase
          .from('ngos')
          .select('profile_id')
          .eq('profile_id', userId)
          .maybeSingle();

      if (ngoCheck == null) {
        debugPrint('⚠️ NGO record not found for user $userId');
        // Set default values
        activeOrders = 0;
        mealsClaimed = 0;
        carbonSaved = 0;
        return;
      }

      // Get active orders (using correct enum values from database)
      final ordersRes = await _supabase
          .from('orders')
          .select('id, status')
          .eq('ngo_id', userId)
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready_for_pickup']);
      
      activeOrders = (ordersRes as List?)?.length ?? 0;

      // Get completed orders for stats
      final completedRes = await _supabase
          .from('orders')
          .select('id')
          .eq('ngo_id', userId)
          .eq('status', 'completed');
      
      mealsClaimed = (completedRes as List?)?.length ?? 0;

      // Calculate carbon savings (simplified)
      carbonSaved = mealsClaimed * 2.5; // Avg 2.5kg CO2 per meal

      debugPrint('✅ Stats loaded: Orders=$activeOrders, Claimed=$mealsClaimed, Carbon=${carbonSaved}kg');
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      // Set default values on error
      activeOrders = 0;
      mealsClaimed = 0;
      carbonSaved = 0;
    }
  }

  Future<void> _loadMeals() async {
    try {
      // OPTIMIZED: Fetch only essential columns with proper error handling
      final res = await _supabase
          .from('meals')
          .select('''
            id,
            title,
            image_url,
            discounted_price,
            original_price,
            quantity_available,
            expiry_date,
            location,
            category,
            restaurant_id,
            description,
            unit,
            fulfillment_method,
            status,
            is_donation_available,
            restaurants!inner(
              profile_id,
              restaurant_name,
              rating
            )
          ''')
          .eq('is_donation_available', true)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String())
          .order('expiry_date', ascending: true)
          .limit(50); // Add pagination limit

      meals = (res as List).map((json) {
        try {
          // Transform restaurant data to match expected format
          final restaurantData = json['restaurants'];
          if (restaurantData == null) {
            debugPrint('Warning: Missing restaurant data for meal ${json['id']}');
            return null;
          }

          json['restaurant'] = {
            'id': restaurantData['profile_id']?.toString() ?? '',
            'name': restaurantData['restaurant_name'] ?? 'Unknown Restaurant',
            'rating': (restaurantData['rating'] as num?)?.toDouble() ?? 0.0,
            'logo_url': '',
            'verified': true,
            'reviews_count': 0,
          };

          // Map database fields to model fields with proper null handling
          json['donation_price'] = json['discounted_price'] ?? 0.0;
          json['quantity'] = json['quantity_available'] ?? 0;
          json['expiry'] = json['expiry_date'];
          json['description'] = json['description'] ?? '';
          json['unit'] = json['unit'] ?? 'portions';
          json['fulfillment_method'] = json['fulfillment_method'] ?? 'pickup';
          json['is_donation_available'] = json['is_donation_available'] ?? true;
          json['status'] = json['status'] ?? 'active';
          json['original_price'] = json['original_price'] ?? json['discounted_price'] ?? 0.0;
          json['pickup_deadline'] = null;
          json['pickup_time'] = null;
          json['ingredients'] = [];
          json['allergens'] = [];
          json['co2_savings'] = 0.0;

          return MealModel.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing meal ${json['id']}: $e');
          return null;
        }
      }).whereType<Meal>().toList(); // Filter out null values

      // Separate expiring soon (within 2 hours)
      final twoHoursFromNow = DateTime.now().add(const Duration(hours: 2));
      expiringMeals = meals.where((m) => m.expiry.isBefore(twoHoursFromNow)).toList();

      debugPrint('✅ Loaded ${meals.length} meals, ${expiringMeals.length} expiring soon');
    } catch (e) {
      debugPrint('❌ Error loading meals: $e');
      error = 'Failed to load meals: ${e.toString()}';
      meals = [];
      expiringMeals = [];
    }
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    if (hasListeners) {
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    if (hasListeners) {
      notifyListeners();
    }
  }
  
  /// Clear state on logout
  void clearState() {
    isLoading = true;
    error = null;
    selectedFilter = 'all';
    searchQuery = '';
    mealsClaimed = 0;
    carbonSaved = 0;
    activeOrders = 0;
    meals = [];
    expiringMeals = [];
    _lastFetchTime = null;
    notifyListeners();
  }

  Future<void> claimMeal(Meal meal, BuildContext context) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify NGO record exists
      final ngoCheck = await _supabase
          .from('ngos')
          .select('profile_id')
          .eq('profile_id', userId)
          .maybeSingle();

      if (ngoCheck == null) {
        throw Exception('NGO profile not found. Please complete your profile setup.');
      }

      // Check if meal is still available
      final mealCheck = await _supabase
          .from('meals')
          .select('id, quantity_available, status')
          .eq('id', meal.id)
          .maybeSingle();

      if (mealCheck == null) {
        throw Exception('Meal not found');
      }

      if (mealCheck['status'] != 'active') {
        throw Exception('This meal is no longer available');
      }

      if (((mealCheck['quantity_available'] as int?) ?? 0) <= 0) {
        throw Exception('This meal is out of stock');
      }

      // Add to cart instead of creating order immediately
      final cartViewModel = context.read<NgoCartViewModel>();
      cartViewModel.addToCart(meal);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added to cart: ${meal.title}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.go('/ngo/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding to cart: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
