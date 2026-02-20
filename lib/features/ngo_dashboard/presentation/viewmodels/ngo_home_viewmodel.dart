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
  String currentLocation = 'Loading...';
  
  // Stats
  int mealsClaimed = 0;
  double carbonSaved = 0;
  int activeOrders = 0;
  bool hasNotifications = true;
  
  // Meals
  List<Meal> meals = [];
  List<Meal> expiringMeals = [];
  List<String> categories = ['All Items']; // Dynamic categories from database
  
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
    if (selectedFilter != 'all' && selectedFilter.isNotEmpty) {
      result = result.where((m) => 
        m.category.toLowerCase() == selectedFilter.toLowerCase()
      ).toList();
    }

    return result;
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    debugPrint('🔍 ========== NGO HOME: loadData START ==========');
    debugPrint('hasListeners: $hasListeners');
    debugPrint('forceRefresh: $forceRefresh');
    debugPrint('meals.length: ${meals.length}');
    debugPrint('_isDataStale: $_isDataStale');
    
    if (!hasListeners) {
      debugPrint('❌ NGO: No listeners, returning');
      return;
    }
    
    // Skip if data is fresh and not forcing refresh
    if (!forceRefresh && meals.isNotEmpty && !_isDataStale) {
      debugPrint('ℹ️ NGO: Data is fresh, skipping load');
      return;
    }
    
    debugPrint('✅ NGO: Starting data load...');
    isLoading = true;
    error = null;
    
    // CRITICAL: Notify immediately to show loading state
    notifyListeners();

    try {
      debugPrint('✅ NGO: Calling Future.wait for stats and meals...');
      await Future.wait([
        _loadLocation(),
        _loadStats(),
        _loadMeals(),
      ]);
      _lastFetchTime = DateTime.now();
      debugPrint('✅ NGO: Data load complete');
    } catch (e, stackTrace) {
      debugPrint('❌ NGO: Error in loadData: $e');
      debugPrint('Stack trace: $stackTrace');
      error = e.toString();
      debugPrint('❌ Data fetch failed: $e');
    } finally {
      isLoading = false;
      if (hasListeners) {
        debugPrint('✅ NGO: Notifying listeners');
        notifyListeners();
      }
    }
    
    debugPrint('🎉 ========== NGO HOME: loadData END ==========');
  }

  Future<void> _loadLocation() async {
    debugPrint('📍 NGO: _loadLocation START');
    final userId = _supabase.auth.currentUser?.id;
    debugPrint('User ID: $userId');
    
    if (userId == null) {
      debugPrint('❌ NGO: User ID is null in _loadLocation');
      currentLocation = 'Cairo, Egypt'; // Default fallback
      return;
    }

    try {
      debugPrint('🔍 NGO: Fetching user profile location...');
      final profileRes = await _supabase
          .from('profiles')
          .select('default_location')
          .eq('id', userId)
          .maybeSingle();
      
      if (profileRes != null && profileRes['default_location'] != null) {
        currentLocation = profileRes['default_location'] as String;
        debugPrint('✅ NGO: Location loaded: $currentLocation');
      } else {
        // Try to get from NGO table if available
        debugPrint('🔍 NGO: Trying to get location from NGO table...');
        final ngoRes = await _supabase
            .from('ngos')
            .select('address_text')
            .eq('profile_id', userId)
            .maybeSingle();
        
        if (ngoRes != null && ngoRes['address_text'] != null) {
          currentLocation = ngoRes['address_text'] as String;
          debugPrint('✅ NGO: Location from NGO table: $currentLocation');
        } else {
          currentLocation = 'Cairo, Egypt'; // Default fallback
          debugPrint('ℹ️ NGO: Using default location');
        }
      }
      debugPrint('✅ NGO: _loadLocation COMPLETE');
    } catch (e, stackTrace) {
      debugPrint('❌ NGO: Error loading location: $e');
      debugPrint('Stack trace: $stackTrace');
      currentLocation = 'Cairo, Egypt'; // Default fallback on error
    }
  }

  Future<void> _loadStats() async {
    debugPrint('📊 NGO: _loadStats START');
    final userId = _supabase.auth.currentUser?.id;
    debugPrint('User ID: $userId');
    
    if (userId == null) {
      debugPrint('❌ NGO: User ID is null in _loadStats');
      return;
    }

    try {
      debugPrint('🔍 NGO: Fetching active orders...');
      // Get active orders
      final ordersRes = await _supabase
          .from('orders')
          .select('id, status')
          .eq('ngo_id', userId)
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery']);
      
      activeOrders = (ordersRes as List).length;
      debugPrint('✅ NGO: Active orders: $activeOrders');

      debugPrint('🔍 NGO: Fetching completed orders with items...');
      // Get completed orders with order items to count meals
      final completedRes = await _supabase
          .from('orders')
          .select('id, order_items(quantity)')
          .eq('ngo_id', userId)
          .eq('status', 'completed');
      
      // Count total meals from all completed orders
      int totalMeals = 0;
      for (final order in (completedRes as List)) {
        final items = order['order_items'] as List?;
        if (items != null) {
          for (final item in items) {
            totalMeals += (item['quantity'] as int?) ?? 0;
          }
        }
      }
      
      mealsClaimed = totalMeals;
      debugPrint('✅ NGO: Meals claimed: $mealsClaimed (from ${(completedRes as List).length} completed orders)');

      // Calculate carbon savings (2.5kg CO2 per meal saved)
      carbonSaved = mealsClaimed * 2.5;
      debugPrint('✅ NGO: Carbon saved: ${carbonSaved.toStringAsFixed(1)} kg');
      debugPrint('✅ NGO: _loadStats COMPLETE');
    } catch (e, stackTrace) {
      debugPrint('❌ NGO: Error loading stats: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadMeals() async {
    try {
      debugPrint('🔍 ========== NGO: _loadMeals START ==========');
      
      // OPTIMIZED: Fetch meals and restaurants separately to avoid RLS recursion
      // Step 1: Get meals
      debugPrint('📊 Step 1: Fetching meals from database...');
      final mealsRes = await _supabase
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
            description
          ''')
          .eq('is_donation_available', true)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String())
          .order('expiry_date', ascending: true)
          .limit(50); // Add pagination limit

      debugPrint('✅ Step 1: Got ${(mealsRes as List).length} meals from database');

      if ((mealsRes as List).isEmpty) {
        meals = [];
        expiringMeals = [];
        debugPrint('ℹ️ NGO: No meals available (empty result)');
        debugPrint('🎉 ========== NGO: _loadMeals END (no meals) ==========');
        return;
      }

      // Step 2: Get unique restaurant IDs
      debugPrint('📊 Step 2: Extracting restaurant IDs...');
      final restaurantIds = (mealsRes as List)
          .map((m) => m['restaurant_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      debugPrint('✅ Step 2: Found ${restaurantIds.length} unique restaurants');
      debugPrint('Restaurant IDs: $restaurantIds');

      // Step 3: Fetch restaurants separately with avatar_url from profiles
      debugPrint('📊 Step 3: Fetching restaurants from database...');
      final restaurantsRes = await _supabase
          .from('restaurants')
          .select('''
            profile_id, 
            restaurant_name, 
            rating, 
            latitude, 
            longitude, 
            address_text,
            profiles!inner(avatar_url)
          ''')
          .inFilter('profile_id', restaurantIds);

      debugPrint('✅ Step 3: Got ${(restaurantsRes as List).length} restaurants from database');

      // Step 4: Create restaurant lookup map
      debugPrint('📊 Step 4: Creating restaurant lookup map...');
      final restaurantMap = <String, Map<String, dynamic>>{};
      for (final r in (restaurantsRes as List)) {
        restaurantMap[r['profile_id']] = r;
        debugPrint('  - ${r['profile_id']}: ${r['restaurant_name']}');
      }
      debugPrint('✅ Step 4: Restaurant map created with ${restaurantMap.length} entries');

      // Step 5: Transform meals with restaurant data
      debugPrint('📊 Step 5: Transforming meals with restaurant data...');
      meals = (mealsRes as List).map((json) {
        final restaurantId = json['restaurant_id'] as String?;
        final restaurantData = restaurantId != null 
            ? restaurantMap[restaurantId] 
            : null;

        if (restaurantData == null) {
          debugPrint('⚠️ Warning: No restaurant data for meal ${json['id']} (restaurant_id: $restaurantId)');
        }

        // Add restaurant data
        json['restaurant'] = {
          'id': restaurantId ?? '',
          'name': restaurantData?['restaurant_name'] ?? 'Unknown Restaurant',
          'rating': restaurantData?['rating'] ?? 0.0,
          'logo_url': restaurantData?['profiles']?['avatar_url'] ?? '',
          'verified': true,
          'reviews_count': 0,
          'latitude': restaurantData?['latitude'],
          'longitude': restaurantData?['longitude'],
          'address_text': restaurantData?['address_text'],
        };

        // Map database fields to model fields
        json['donation_price'] = json['discounted_price'];
        json['quantity'] = json['quantity_available'];
        json['expiry'] = json['expiry_date'];
        json['description'] = json['description'] ?? '';
        json['unit'] = 'portions';
        json['fulfillment_method'] = 'pickup';
        json['is_donation_available'] = true;
        json['status'] = 'active';
        // Keep original_price from database - don't overwrite it!
        json['pickup_deadline'] = null;
        json['pickup_time'] = null;
        json['ingredients'] = [];
        json['allergens'] = [];
        json['co2_savings'] = 0.0;

        return MealModel.fromJson(json);
      }).toList();

      debugPrint('✅ Step 5: Transformed ${meals.length} meals successfully');

      // Step 6: Extract unique categories from meals
      debugPrint('📊 Step 6: Extracting unique categories...');
      final uniqueCategories = meals
          .map((m) => m.category)
          .where((cat) => cat.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      
      categories = ['All Items', ...uniqueCategories];
      debugPrint('✅ Step 6: Found ${categories.length - 1} unique categories: $uniqueCategories');

      // Separate expiring soon (within 2 hours)
      debugPrint('📊 Step 7: Filtering expiring meals...');
      final twoHoursFromNow = DateTime.now().add(const Duration(hours: 2));
      expiringMeals = meals.where((m) => m.expiry.isBefore(twoHoursFromNow)).toList();
      
      debugPrint('✅ Step 7: Found ${expiringMeals.length} expiring meals');
      debugPrint('🎉 ========== NGO: _loadMeals END (success) ==========');
    } catch (e, stackTrace) {
      debugPrint('❌ ========== NGO: _loadMeals ERROR ==========');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('===========================================');
      error = e.toString();
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
      await cartViewModel.addToCart(meal);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to cart: ${meal.title}'),
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
