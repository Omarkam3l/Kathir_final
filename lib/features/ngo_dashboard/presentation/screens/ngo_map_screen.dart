import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/services/geocoding_service.dart';
import '../viewmodels/ngo_map_viewmodel.dart';

/// NGO Map Screen - Interactive map showing meal locations
class NgoMapScreen extends StatefulWidget {
  const NgoMapScreen({super.key});

  @override
  State<NgoMapScreen> createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends State<NgoMapScreen> {
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  double _searchRadius = 10.0; // km
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await _getCurrentLocation();
      
      if (position != null && mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        if (mounted) {
          context.read<NgoMapViewModel>().updateLocation(
            newLocation,
            'Current Location',
          );
          _mapController.move(newLocation, 13.0);
        }
      } else {
        // Load with default location
        if (mounted) {
          context.read<NgoMapViewModel>().loadMeals();
        }
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        context.read<NgoMapViewModel>().loadMeals();
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _geocodingService.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _geocodingService.debouncedSearch(
        query,
        const Duration(milliseconds: 500),
      );

      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  void _selectSearchResult(GeocodingResult result) {
    final newLocation = LatLng(result.latitude, result.longitude);
    
    setState(() {
      _showSearchResults = false;
      _searchController.text = result.displayName;
    });

    _searchFocusNode.unfocus();
    
    // Move map to selected location
    _mapController.move(newLocation, 14.0);
    
    // Update viewmodel location
    context.read<NgoMapViewModel>().updateLocation(
      newLocation,
      result.displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Consumer<NgoMapViewModel>(
          builder: (context, viewModel, _) {
            return Stack(
              children: [
                _buildMap(viewModel, isDark),
                _buildSearchBar(isDark, viewModel),
                if (_showSearchResults)
                  _buildSearchResults(isDark),
                _buildRadiusSlider(isDark, viewModel),
                _buildRestaurantsList(isDark, viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(NgoMapViewModel viewModel, bool isDark) {
    // Group meals by restaurant
    final restaurantMeals = <String, List<dynamic>>{};
    for (final mealLocation in viewModel.mealMarkers) {
      final restaurantId = mealLocation.meal.restaurant.id;
      if (!restaurantMeals.containsKey(restaurantId)) {
        restaurantMeals[restaurantId] = [];
      }
      restaurantMeals[restaurantId]!.add(mealLocation);
    }

    // Get unique restaurant locations
    final restaurantMarkers = <String, dynamic>{};
    for (final entry in restaurantMeals.entries) {
      final firstMeal = entry.value.first;
      restaurantMarkers[entry.key] = {
        'location': firstMeal.location,
        'meal': firstMeal.meal,
        'count': entry.value.length,
      };
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: viewModel.currentLocation,
        initialZoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: (_, __) {
          setState(() => _selectedRestaurantId = null);
          viewModel.clearSelection();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        // Search radius circle
        CircleLayer(
          circles: [
            CircleMarker(
              point: viewModel.currentLocation,
              radius: _searchRadius * 1000, // Convert km to meters
              useRadiusInMeter: true,
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderColor: AppColors.primaryGreen,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        // User location marker
        MarkerLayer(
          markers: [
            Marker(
              point: viewModel.currentLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Restaurant markers with meal count
            ...restaurantMarkers.entries.map((entry) {
              final restaurantId = entry.key;
              final data = entry.value;
              final location = data['location'] as LatLng;
              final meal = data['meal'];
              final mealCount = data['count'] as int;
              final isSelected = _selectedRestaurantId == restaurantId;

              return Marker(
                point: location,
                width: isSelected ? 60 : 50,
                height: isSelected ? 70 : 60,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedRestaurantId = restaurantId);
                    viewModel.selectMeal(meal);
                    _mapController.move(location, 14.0);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: isSelected ? 50 : 40,
                        height: isSelected ? 50 : 40,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primaryGreen 
                              : (isDark ? Colors.white : Colors.black),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppColors.primaryGreen.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.2),
                              blurRadius: isSelected ? 15 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: isSelected 
                              ? Colors.black 
                              : (isDark ? Colors.black : Colors.white),
                          size: isSelected ? 26 : 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          '$mealCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark, NgoMapViewModel viewModel) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.go('/ngo/home'),
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
                size: 24,
              ),
              padding: const EdgeInsets.all(16),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _searchLocation,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search location (e.g., Cairo, Maadi)...',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                    _showSearchResults = false;
                  });
                },
                icon: Icon(
                  Icons.clear,
                  size: 24,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                padding: const EdgeInsets.all(16),
              )
            else
              IconButton(
                onPressed: _initializeLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
                padding: const EdgeInsets.all(16),
                tooltip: 'My Location',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return Positioned(
      top: 88,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => Divider(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              title: Text(
                result.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _selectSearchResult(result),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadiusSlider(bool isDark, NgoMapViewModel viewModel) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, color: AppColors.primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Search Radius',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_searchRadius.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 13,
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
              inactiveColor: isDark ? Colors.grey[700] : Colors.grey[300],
              onChanged: (value) {
                setState(() => _searchRadius = value);
                viewModel.filterByRadius(_searchRadius);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsList(bool isDark, NgoMapViewModel viewModel) {
    // Group meals by restaurant
    final restaurantMeals = <String, List<dynamic>>{};
    for (final mealLocation in viewModel.filteredMealMarkers) {
      final restaurantId = mealLocation.meal.restaurant.id;
      if (!restaurantMeals.containsKey(restaurantId)) {
        restaurantMeals[restaurantId] = [];
      }
      restaurantMeals[restaurantId]!.add(mealLocation.meal);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.6,
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
                      '${restaurantMeals.length} found',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: restaurantMeals.isEmpty
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
                        itemCount: restaurantMeals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final entry = restaurantMeals.entries.elementAt(index);
                          final restaurantId = entry.key;
                          final meals = entry.value;
                          final firstMeal = meals.first;
                          
                          return _buildRestaurantCard(
                            restaurantId,
                            firstMeal.restaurant.name,
                            firstMeal.restaurant.rating,
                            firstMeal.restaurant.logoUrl,
                            meals.length,
                            isDark,
                            viewModel,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(
    String restaurantId,
    String name,
    double rating,
    String? logoUrl,
    int mealCount,
    bool isDark,
    NgoMapViewModel viewModel,
  ) {
    // Calculate distance if possible
    double? distance;
    final restaurantMeal = viewModel.mealMarkers
        .firstWhere((m) => m.meal.restaurant.id == restaurantId);
    
    distance = Geolocator.distanceBetween(
      viewModel.currentLocation.latitude,
      viewModel.currentLocation.longitude,
      restaurantMeal.location.latitude,
      restaurantMeal.location.longitude,
    ) / 1000; // Convert to km

    final isSelected = _selectedRestaurantId == restaurantId;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRestaurantId = restaurantId);
        _mapController.move(restaurantMeal.location, 14.0);
        
        // Show restaurant meals
        context.push('/ngo/restaurant/$restaurantId', extra: {
          'restaurant': {
            'id': restaurantId,
            'name': name,
            'rating': rating,
            'logo_url': logoUrl,
          },
          'meals': viewModel.mealMarkers
              .where((m) => m.meal.restaurant.id == restaurantId)
              .map((m) => m.meal)
              .toList(),
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF1A2E22) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
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
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            name[0].toUpperCase(),
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
                        name[0].toUpperCase(),
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
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu, size: 14, color: AppColors.primaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        '$mealCount available meals',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
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
