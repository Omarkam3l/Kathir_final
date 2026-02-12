import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/data/models/meal_model.dart';
import '../../../user_home/domain/entities/meal.dart';

class NgoHomeViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  bool isLoading = true;
  String? error;
  
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
    // Skip if data exists and is fresh
    if (meals.isNotEmpty && !_isDataStale) {
      return;
    }
    
    // Skip if already loading (in-flight guard)
    if (isLoading) {
      return;
    }
    
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
    print('🔍 ========== NGO HOME: loadData START ==========');
    print('hasListeners: $hasListeners');
    print('forceRefresh: $forceRefresh');
    print('meals.length: ${meals.length}');
    print('_isDataStale: $_isDataStale');
    
    if (!hasListeners) {
      print('❌ NGO: No listeners, returning');
      return;
    }
    
    // Skip if data is fresh and not forcing refresh
    if (!forceRefresh && meals.isNotEmpty && !_isDataStale) {
      print('ℹ️ NGO: Data is fresh, skipping load');
      return;
    }
    
    print('✅ NGO: Starting data load...');
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      print('📊 NGO: Calling Future.wait for stats and meals...');
      await Future.wait([
        _loadStats(),
        _loadMeals(),
      ]);
      _lastFetchTime = DateTime.now();
      print('✅ NGO: Data load complete');
    } catch (e, stackTrace) {
      print('❌ NGO: Error in loadData: $e');
      print('Stack trace: $stackTrace');
      error = e.toString();
    } finally {
      isLoading = false;
      if (hasListeners) {
        print('✅ NGO: Notifying listeners');
        notifyListeners();
      }
    }
    
    print('🎉 ========== NGO HOME: loadData END ==========');
  }

  Future<void> _loadStats() async {
    print('📊 NGO: _loadStats START');
    final userId = _supabase.auth.currentUser?.id;
    print('User ID: $userId');
    
    if (userId == null) {
      print('❌ NGO: User ID is null in _loadStats');
      return;
    }

    try {
      print('🔍 NGO: Fetching active orders...');
      // Get active orders (removed 'paid' and 'processing' - not valid statuses)
      final ordersRes = await _supabase
          .from('orders')
          .select('id, status')
          .eq('ngo_id', userId)
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery']);
      
      activeOrders = (ordersRes as List).length;
      print('✅ NGO: Active orders: $activeOrders');

      print('🔍 NGO: Fetching completed orders...');
      // Get completed orders for stats
      final completedRes = await _supabase
          .from('orders')
          .select('id')
          .eq('ngo_id', userId)
          .eq('status', 'completed');
      
      mealsClaimed = (completedRes as List).length;
      print('✅ NGO: Meals claimed: $mealsClaimed');

      // Calculate carbon savings (simplified)
      carbonSaved = mealsClaimed * 2.5; // Avg 2.5kg CO2 per meal
      print('✅ NGO: Carbon saved: $carbonSaved kg');
      print('✅ NGO: _loadStats COMPLETE');
    } catch (e, stackTrace) {
      print('❌ NGO: Error loading stats: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadMeals() async {
    try {
      print('🔍 ========== NGO: _loadMeals START ==========');
      
      // OPTIMIZED: Fetch meals and restaurants separately to avoid RLS recursion
      // Step 1: Get meals
      print('📊 Step 1: Fetching meals from database...');
      final mealsRes = await _supabase
          .from('meals')
          .select('''
            id,
            title,
            image_url,
            discounted_price,
            quantity_available,
            expiry_date,
            location,
            category,
            restaurant_id
          ''')
          .eq('is_donation_available', true)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String())
          .order('expiry_date', ascending: true);

      print('✅ Step 1: Got ${(mealsRes as List).length} meals from database');

      if ((mealsRes as List).isEmpty) {
        meals = [];
        expiringMeals = [];
        print('ℹ️ NGO: No meals available (empty result)');
        print('🎉 ========== NGO: _loadMeals END (no meals) ==========');
        return;
      }

      // Step 2: Get unique restaurant IDs
      print('📊 Step 2: Extracting restaurant IDs...');
      final restaurantIds = (mealsRes as List)
          .map((m) => m['restaurant_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      print('✅ Step 2: Found ${restaurantIds.length} unique restaurants');
      print('Restaurant IDs: $restaurantIds');

      // Step 3: Fetch restaurants separately
      print('📊 Step 3: Fetching restaurants from database...');
      final restaurantsRes = await _supabase
          .from('restaurants')
          .select('profile_id, restaurant_name, rating')
          .inFilter('profile_id', restaurantIds);

      print('✅ Step 3: Got ${(restaurantsRes as List).length} restaurants from database');

      // Step 4: Create restaurant lookup map
      print('📊 Step 4: Creating restaurant lookup map...');
      final restaurantMap = <String, Map<String, dynamic>>{};
      for (final r in (restaurantsRes as List)) {
        restaurantMap[r['profile_id']] = r;
        print('  - ${r['profile_id']}: ${r['restaurant_name']}');
      }
      print('✅ Step 4: Restaurant map created with ${restaurantMap.length} entries');

      // Step 5: Transform meals with restaurant data
      print('📊 Step 5: Transforming meals with restaurant data...');
      meals = (mealsRes as List).map((json) {
        final restaurantId = json['restaurant_id'] as String?;
        final restaurantData = restaurantId != null 
            ? restaurantMap[restaurantId] 
            : null;

        if (restaurantData == null) {
          print('⚠️ Warning: No restaurant data for meal ${json['id']} (restaurant_id: $restaurantId)');
        }

        // Add restaurant data
        json['restaurant'] = {
          'id': restaurantId ?? '',
          'name': restaurantData?['restaurant_name'] ?? 'Unknown Restaurant',
          'rating': restaurantData?['rating'] ?? 0.0,
          'logo_url': '',
          'verified': true,
          'reviews_count': 0,
        };

        // Map database fields to model fields
        json['donation_price'] = json['discounted_price'];
        json['quantity'] = json['quantity_available'];
        json['expiry'] = json['expiry_date'];
        json['description'] = '';
        json['unit'] = 'portions';
        json['fulfillment_method'] = 'pickup';
        json['is_donation_available'] = true;
        json['status'] = 'active';
        json['original_price'] = json['discounted_price'];
        json['pickup_deadline'] = null;
        json['pickup_time'] = null;
        json['ingredients'] = [];
        json['allergens'] = [];
        json['co2_savings'] = 0.0;

        return MealModel.fromJson(json);
      }).toList();

      print('✅ Step 5: Transformed ${meals.length} meals successfully');

      // Separate expiring soon (within 2 hours)
      print('📊 Step 6: Filtering expiring meals...');
      final twoHoursFromNow = DateTime.now().add(const Duration(hours: 2));
      expiringMeals = meals.where((m) => m.expiry.isBefore(twoHoursFromNow)).toList();
      
      print('✅ Step 6: Found ${expiringMeals.length} expiring meals');
      print('🎉 ========== NGO: _loadMeals END (success) ==========');
    } catch (e, stackTrace) {
      print('❌ ========== NGO: _loadMeals ERROR ==========');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('===========================================');
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

      // Create order
      await _supabase.from('orders').insert({
        'user_id': userId,
        'ngo_id': userId,
        'restaurant_id': meal.restaurant.id,
        'meal_id': meal.id,
        'status': 'pending',
        'delivery_type': 'donation',
        'subtotal': meal.donationPrice,
        'total_amount': meal.donationPrice,
      });

      // Update meal status
      await _supabase
          .from('meals')
          .update({'status': 'reserved'})
          .eq('id', meal.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully claimed: ${meal.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await loadData();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
