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

  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadStats(),
        _loadMeals(),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get active orders
      final ordersRes = await _supabase
          .from('orders')
          .select('id, status')
          .eq('ngo_id', userId)
          .inFilter('status', ['pending', 'paid', 'processing']);
      
      activeOrders = (ordersRes as List).length;

      // Get completed orders for stats
      final completedRes = await _supabase
          .from('orders')
          .select('id')
          .eq('ngo_id', userId)
          .eq('status', 'completed');
      
      mealsClaimed = (completedRes as List).length;

      // Calculate carbon savings (simplified)
      carbonSaved = mealsClaimed * 2.5; // Avg 2.5kg CO2 per meal
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadMeals() async {
    try {
      final res = await _supabase
          .from('meals')
          .select('''
            id,
            title,
            description,
            category,
            image_url,
            original_price,
            discounted_price,
            quantity_available,
            expiry_date,
            pickup_deadline,
            status,
            location,
            unit,
            fulfillment_method,
            is_donation_available,
            ingredients,
            allergens,
            co2_savings,
            pickup_time,
            created_at,
            updated_at,
            restaurant_id,
            restaurants!inner(
              profile_id,
              restaurant_name,
              rating,
              address_text
            )
          ''')
          .eq('is_donation_available', true)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String())
          .order('expiry_date', ascending: true);

      meals = (res as List).map((json) {
        // Transform restaurant data to match expected format
        final restaurantData = json['restaurants'];
        json['restaurant'] = {
          'id': restaurantData['profile_id'],
          'name': restaurantData['restaurant_name'] ?? 'Unknown',
          'rating': restaurantData['rating'] ?? 0.0,
          'logo_url': '',
          'verified': true,
          'reviews_count': 0,
        };
        // Map database fields to model fields
        json['donation_price'] = json['discounted_price'];
        json['quantity'] = json['quantity_available']; // Fix quantity mapping
        json['expiry'] = json['expiry_date'];
        return MealModel.fromJson(json);
      }).toList();

      // Separate expiring soon (within 2 hours)
      final twoHoursFromNow = DateTime.now().add(const Duration(hours: 2));
      expiringMeals = meals.where((m) => m.expiry.isBefore(twoHoursFromNow)).toList();
    } catch (e) {
      debugPrint('Error loading meals: $e');
      error = e.toString();
    }
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
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
