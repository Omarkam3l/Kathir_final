import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming google_fonts is available, if not will fallback
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:intl/intl.dart';

// Custom Colors for this screen to match design
class ProductDetailPage extends StatefulWidget {
  final MealOffer product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final meal = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.primary;

    // Derived colors based on theme
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Hero Image with App Bar
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Consumer<FoodieState>(
                    builder: (context, foodie, _) {
                      final isFav = foodie.isFavourite(meal.id);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.redAccent : Colors.white,
                              ),
                              onPressed: () => foodie.toggleFavourite(meal),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'meal_${meal.id}',
                        child: Image.network(
                          meal.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.restaurant,
                                color: Colors.white54, size: 64),
                          ),
                        ),
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                meal.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${meal.donationPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                if (meal.originalPrice > meal.donationPrice)
                                  Text(
                                    '\$${meal.originalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: subTextColor,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: subTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Restaurant Row
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color:
                                      isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: surfaceColor,
                                  image: meal.restaurant.logoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              meal.restaurant.logoUrl!),
                                          fit: BoxFit.cover)
                                      : null,
                                  border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12),
                                ),
                                child: meal.restaurant.logoUrl == null
                                    ? Icon(Icons.store,
                                        size: 20, color: subTextColor)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          meal.restaurant.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        if (meal.restaurant.verified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified,
                                              color: Colors.blue, size: 16),
                                        ],
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${meal.restaurant.rating} (${meal.restaurant.reviewsCount} reviews)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: subTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {}, // Go to restaurant
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      primaryColor.withValues(alpha: 0.1),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Text(
                                  'View Profile',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Badges: Pickup & Impact
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.access_time,
                                iconColor: Colors.orange,
                                title: 'PICKUP BY',
                                value: meal.pickupTime != null
                                    ? DateFormat('EEE, h:mm a')
                                        .format(meal.pickupTime!)
                                    : 'Today, ${DateFormat('h:mm a').format(meal.expiry)}',
                                bgColor: isDark
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.orange.shade50,
                                borderColor: isDark
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.orange.shade100,
                                textColor: textColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.eco,
                                iconColor: Colors.green,
                                title: 'IMPACT',
                                value:
                                    'Saves ${meal.co2Savings > 0 ? meal.co2Savings : "0.5"}kg CO2',
                                bgColor: isDark
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.green.shade50,
                                borderColor: isDark
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.green.shade100,
                                textColor: textColor,
                              ),
                            ),
                          ],
                        ),

                        // Quantity Alert
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Hurry! Only ${meal.quantity} portions left.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.red[300]
                                      : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Description
                        const SizedBox(height: 24),
                        Text(
                          'Description',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meal.description.isNotEmpty
                              ? meal.description
                              : 'Freshly prepared meal saved from surplus. Delicious and ready to enjoy! This dish is perfect for a sustainable and tasty dinner choice.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.6,
                            color: subTextColor,
                          ),
                        ),

                        // Ingredients & Allergens
                        if (meal.ingredients.isNotEmpty ||
                            meal.allergens.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ingredients & Allergens',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Icon(Icons.info_outline,
                                  color: subTextColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...meal.ingredients.map((e) =>
                                  _buildTag(e, false, isDark, subTextColor)),
                              ...meal.allergens.map((e) =>
                                  _buildTag(e, true, isDark, subTextColor)),
                            ],
                          ),
                        ],

                        // Location
                        const SizedBox(height: 24),
                        Text(
                          'Pickup Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPickupLocation(context, isDark, textColor, subTextColor),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              meal.restaurant.latitude != null && meal.restaurant.longitude != null
                                  ? Icons.location_on
                                  : Icons.location_off,
                              size: 16,
                              color: subTextColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                meal.restaurant.addressText ?? 
                                    (meal.restaurant.latitude != null && meal.restaurant.longitude != null
                                        ? 'Restaurant location'
                                        : 'Location not available'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: subTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 100), // Spacing for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? surfaceColor : Colors.white).withValues(alpha: 0.9),
                    border: Border(
                        top: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TOTAL',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subTextColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '\$${(meal.donationPrice * qty).toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              context
                                  .read<FoodieState>()
                                  .addToCart(meal, qty: qty);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Added $qty ${meal.title} to cart')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Add to Cart',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, bool isAllergen, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAllergen
            ? (isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade100)
            : (isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAllergen
              ? (isDark
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.orange.shade200)
              : (isDark ? Colors.white10 : Colors.grey.shade300),
        ),
      ),
      child: Text(
        isAllergen ? 'Contains: $text' : text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isAllergen
              ? (isDark ? Colors.orange[200] : Colors.orange[800])
              : textColor,
        ),
      ),
    );
  }

  Widget _buildPickupLocation(BuildContext context, bool isDark, Color textColor, Color subTextColor) {
    final meal = widget.product;
    final hasLocation = meal.restaurant.latitude != null && meal.restaurant.longitude != null;
    final location = hasLocation 
        ? LatLng(meal.restaurant.latitude!, meal.restaurant.longitude!)
        : const LatLng(30.0444, 31.2357); // Default Cairo location
    
    return GestureDetector(
      onTap: hasLocation 
          ? () => _showLocationMapDialog(context, isDark)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: hasLocation
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: location,
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: isDark
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: location,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 40,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Location not set',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (hasLocation)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_full, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to view',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLocationMapDialog(BuildContext context, bool isDark) {
    final meal = widget.product;
    final location = LatLng(
      meal.restaurant.latitude!,
      meal.restaurant.longitude!,
    );
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _LocationMapViewer(
          location: location,
          restaurantName: meal.restaurant.name,
          address: meal.restaurant.addressText,
          isDark: isDark,
        ),
      ),
    );
  }
}

// View-only map viewer widget (reused from meal_detail_new.dart)
class _LocationMapViewer extends StatefulWidget {
  final LatLng location;
  final String restaurantName;
  final String? address;
  final bool isDark;

  const _LocationMapViewer({
    required this.location,
    required this.restaurantName,
    this.address,
    required this.isDark,
  });

  @override
  State<_LocationMapViewer> createState() => _LocationMapViewerState();
}

class _LocationMapViewerState extends State<_LocationMapViewer> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  LatLng? _searchedLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=${Uri.encodeComponent(query)}&'
        'format=json&'
        'limit=5&'
        'addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'KathirApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        setState(() {
          _searchResults = results.map((r) => {
            'lat': double.parse(r['lat']),
            'lon': double.parse(r['lon']),
            'display_name': r['display_name'],
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _moveToLocation(LatLng location) {
    setState(() {
      _searchedLocation = location;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(location, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF102216) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0D1B12);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.isDark 
                      ? const Color(0xFF2D4A3A) 
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.restaurantName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: widget.isDark 
                              ? const Color(0xFF94A3B8) 
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.length > 2) {
                  _searchLocation(value);
                } else {
                  setState(() {
                    _searchResults = [];
                    _isSearching = false;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: widget.isDark 
                    ? const Color(0xFF1A2E22) 
                    : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Search results
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: widget.isDark 
                    ? const Color(0xFF1A2E22) 
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark 
                      ? const Color(0xFF2D4A3A) 
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: widget.isDark 
                      ? const Color(0xFF2D4A3A) 
                      : const Color(0xFFE5E7EB),
                ),
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      result['display_name'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _moveToLocation(
                        LatLng(result['lat'], result['lon']),
                      );
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Map
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.location,
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: widget.isDark
                          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                          : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        // Restaurant location marker
                        Marker(
                          point: widget.location,
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: widget.isDark 
                                      ? const Color(0xFF1A2E22) 
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Searched location marker (if any)
                        if (_searchedLocation != null)
                          Marker(
                            point: _searchedLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Address info
          if (widget.address != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark 
                    ? const Color(0xFF1A2E22) 
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark 
                      ? const Color(0xFF2D4A3A) 
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.address!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Reset button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _searchedLocation = null);
                  _mapController.move(widget.location, 15.0);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.my_location, size: 20),
                label: Text(
                  'Show Restaurant Location',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

