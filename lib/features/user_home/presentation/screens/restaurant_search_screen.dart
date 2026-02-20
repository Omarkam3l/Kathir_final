import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/restaurant.dart';

/// Restaurant Search Screen with Map and Location-based filtering
class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _mapController = MapController();
  
  LatLng? _userLocation;
  LatLng _mapCenter = const LatLng(30.0444, 31.2357); // Cairo default
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  bool _isSearching = false;
  double _searchRadius = 5.0; // km
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);
    
    try {
      // Get user's current location
      final position = await _getCurrentLocation();
      
      if (position != null && mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _mapCenter = _userLocation!;
        });
        _mapController.move(_mapCenter, 13.0);
      }
      
      // Load restaurants
      await _loadRestaurants();
    } catch (e) {
      debugPrint('Error initializing location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('''
            profile_id,
            restaurant_name,
            rating,
            rating_count,
            latitude,
            longitude,
            address_text,
            profiles!inner(avatar_url)
          ''')
          .order('rating', ascending: false);

      if (mounted) {
        setState(() {
          _restaurants = (response as List).map((json) {
            return Restaurant(
              id: json['profile_id'],
              name: json['restaurant_name'] ?? 'Unknown',
              rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
              logoUrl: json['profiles']?['avatar_url'],
              verified: true,
              reviewsCount: json['rating_count'] ?? 0,
              latitude: (json['latitude'] as num?)?.toDouble(),
              longitude: (json['longitude'] as num?)?.toDouble(),
              addressText: json['address_text'],
            );
          }).toList();
          
          _filteredRestaurants = _restaurants;
          _filterByLocation();
        });
      }
    } catch (e) {
      debugPrint('Error loading restaurants: $e');
    }
  }

  void _filterByLocation() {
    if (_userLocation == null) {
      setState(() => _filteredRestaurants = _restaurants);
      return;
    }

    final filtered = _restaurants.where((restaurant) {
      if (restaurant.latitude == null || restaurant.longitude == null) {
        return false;
      }

      final distance = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        restaurant.latitude!,
        restaurant.longitude!,
      ) / 1000; // Convert to km

      return distance <= _searchRadius;
    }).toList();

    setState(() => _filteredRestaurants = filtered);
  }

  void _searchRestaurants(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      _filterByLocation();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      setState(() => _isSearching = true);
      
      final q = query.toLowerCase();
      final results = _restaurants.where((r) {
        return r.name.toLowerCase().contains(q) ||
               (r.addressText?.toLowerCase().contains(q) ?? false);
      }).toList();

      if (mounted) {
        setState(() {
          _filteredRestaurants = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onRestaurantTap(Restaurant restaurant) {
    context.push('/restaurant/${restaurant.id}/meals', extra: restaurant);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildSearchBar(isDark),
            _buildRadiusSlider(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        _buildMap(isDark),
                        _buildRestaurantsList(isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              'Find Restaurants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          IconButton(
            onPressed: _initializeLocation,
            icon: const Icon(Icons.my_location, color: AppColors.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _searchRestaurants,
          decoration: InputDecoration(
            hintText: 'Search by restaurant name or location...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search, color: AppColors.primaryGreen),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filterByLocation();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusSlider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Radius',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${_searchRadius.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          Slider(
            value: _searchRadius,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            activeColor: AppColors.primaryGreen,
            onChanged: (value) {
              setState(() => _searchRadius = value);
              _filterByLocation();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _mapCenter,
        initialZoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        if (_userLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _userLocation!,
                radius: _searchRadius * 1000, // Convert km to meters
                useRadiusInMeter: true,
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderColor: AppColors.primaryGreen,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ..._filteredRestaurants
                .where((r) => r.latitude != null && r.longitude != null)
                .map((restaurant) {
              return Marker(
                point: LatLng(restaurant.latitude!, restaurant.longitude!),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _onRestaurantTap(restaurant),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildRestaurantsList(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF102216) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${_filteredRestaurants.length} found',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredRestaurants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No restaurants found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try increasing the search radius',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRestaurants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final restaurant = _filteredRestaurants[index];
                          return _buildRestaurantCard(restaurant, isDark);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, bool isDark) {
    double? distance;
    if (_userLocation != null &&
        restaurant.latitude != null &&
        restaurant.longitude != null) {
      distance = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        restaurant.latitude!,
        restaurant.longitude!,
      ) / 1000; // Convert to km
    }

    return GestureDetector(
      onTap: () => _onRestaurantTap(restaurant),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            // Restaurant Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
              ),
              child: restaurant.logoUrl != null && restaurant.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        restaurant.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            restaurant.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        restaurant.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Restaurant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (restaurant.addressText != null)
                    Text(
                      restaurant.addressText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant.reviewsCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
