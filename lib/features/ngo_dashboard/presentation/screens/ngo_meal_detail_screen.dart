import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../user_home/domain/entities/meal.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_chat_list_viewmodel.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';

class NgoMealDetailScreen extends StatefulWidget {
  final Meal meal;
  const NgoMealDetailScreen({super.key, required this.meal});

  @override
  State<NgoMealDetailScreen> createState() => _NgoMealDetailScreenState();
}

class _NgoMealDetailScreenState extends State<NgoMealDetailScreen> {
  int qty = 1;
  bool isClaiming = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image Section (full screen, no AppBar)
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Full image
                    SizedBox(
                      height: 400,
                      width: double.infinity,
                      child: Image.network(
                        meal.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.restaurant, color: Colors.white54, size: 64),
                        ),
                      ),
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
                    
                    // Back button only (no favorite for NGO)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
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
                      ),
                    ),
                    
                    // Curved white container overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
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
                  color: bgColor,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, isDark),
                      const SizedBox(height: 16),
                      _buildRestaurantRow(context, isDark),
                      const SizedBox(height: 24),
                      _buildBadges(context, isDark),
                      const SizedBox(height: 16),
                      _buildQuantityAlert(context, isDark),
                      const SizedBox(height: 24),
                      _buildDescription(context, isDark),
                      const SizedBox(height: 24),
                      _buildPickupLocation(context, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Sticky Bottom Bar
          _buildBottomBar(context, isDark),
        ],
      ),
    );
  }

  // Widget _buildInfoCard({
  //   required IconData icon,
  //   required Color iconColor,
  //   required String title,
  //   required String value,
  //   required Color bgColor,
  //   required Color borderColor,
  //   required Color textColor,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: bgColor,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: borderColor),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(icon, size: 18, color: iconColor),
  //             const SizedBox(width: 6),
  //             Text(
  //               title,
  //               style: GoogleFonts.plusJakartaSans(
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.bold,
  //                 letterSpacing: 0.5,
  //                 color: iconColor,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 6),
  //         Text(
  //           value,
  //           style: GoogleFonts.plusJakartaSans(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w600,
  //             color: textColor,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildTag(String text, bool isAllergen, bool isDark, Color textColor) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: isAllergen
  //           ? (isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade100)
  //           : (isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade200),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(
  //         color: isAllergen
  //             ? (isDark ? Colors.orange.withValues(alpha: 0.3) : Colors.orange.shade200)
  //             : (isDark ? Colors.white10 : Colors.grey.shade300),
  //       ),
  //     ),
  //     child: Text(
  //       isAllergen ? 'Contains: $text' : text,
  //       style: GoogleFonts.plusJakartaSans(
  //         fontSize: 12,
  //         fontWeight: FontWeight.w500,
  //         color: isAllergen
  //             ? (isDark ? Colors.orange[200] : Colors.orange[800])
  //             : textColor,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final meal = widget.meal;
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    
    return Row(
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
              meal.donationPrice == 0 
                  ? 'FREE'
                  : 'EGP ${meal.donationPrice.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF139E4B),
              ),
            ),
            if (meal.donationPrice == 0 && meal.originalPrice > 0)
              Text(
                'Was EGP ${meal.originalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[400],
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.grey[400],
                  decorationThickness: 2,
                ),
              )
            else if (meal.donationPrice > 0 && meal.originalPrice > meal.donationPrice)
              Text(
                'EGP ${meal.originalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
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
    );
  }

  Widget _buildRestaurantRow(BuildContext context, bool isDark) {
    final meal = widget.meal;
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    final borderColor = isDark ? const Color(0xFF2D4A3A) : const Color(0xFFE2E8F0);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              border: Border.all(color: borderColor),
            ),
            child: const Icon(
              Icons.restaurant,
              size: 20,
              color: AppColors.primaryGreen,
            ),
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
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${meal.restaurant.rating.toStringAsFixed(1)} (${meal.restaurant.reviewsCount} reviews)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final chatListViewModel = NgoChatListViewModel();
              final conversationId = await chatListViewModel.getOrCreateConversation(
                meal.restaurant.id,
              );
              
              if (conversationId != null && context.mounted) {
                context.push(
                  '/ngo/chat/$conversationId',
                  extra: {
                    'conversationId': conversationId,
                    'restaurantName': meal.restaurant.name,
                  },
                );
              }
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: Text(
              'Chat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
              foregroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context, bool isDark) {
    final meal = widget.meal;
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    final pickupTime = meal.pickupDeadline != null
        ? DateFormat('h:mm a').format(meal.pickupDeadline!)
        : DateFormat('h:mm a').format(meal.expiry);
    
    return Row(
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
                    const Icon(Icons.timelapse, color: Color(0xFFEA580C), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'PICKUP BY',
                      style: GoogleFonts.plusJakartaSans(
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
                  'Today, $pickupTime',
                  style: GoogleFonts.plusJakartaSans(
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
                    const Icon(Icons.eco, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'IMPACT',
                      style: GoogleFonts.plusJakartaSans(
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
                  'Saves ${meal.co2Savings > 0 ? meal.co2Savings : "0.5"}kg CO2',
                  style: GoogleFonts.plusJakartaSans(
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
    );
  }

  Widget _buildQuantityAlert(BuildContext context, bool isDark) {
    final meal = widget.meal;
    return Container(
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
          const Icon(Icons.local_fire_department, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Text(
            'Hurry! Only ${meal.quantity} ${meal.unit} left.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, bool isDark) {
    final meal = widget.meal;
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              : 'Freshly prepared meal saved from surplus. Perfect for donation to those in need.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.6,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildPickupLocation(BuildContext context, bool isDark) {
    final meal = widget.meal;
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    final hasLocation = meal.restaurant.latitude != null && 
                        meal.restaurant.longitude != null;
    final location = hasLocation 
        ? LatLng(meal.restaurant.latitude!, meal.restaurant.longitude!)
        : const LatLng(30.0444, 31.2357); // Default Cairo location
    
    return Column(
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
        const SizedBox(height: 12),
        GestureDetector(
          onTap: hasLocation 
              ? () => _showLocationMapDialog(context, isDark)
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                SizedBox(
                  height: 128,
                  child: hasLocation
                      ? FlutterMap(
                          options: MapOptions(
                            initialCenter: location,
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none, // Disable interactions
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
                                      color: AppColors.primaryGreen,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          color: isDark ? const Color(0xFF1A2E22) : const Color(0xFFF3F4F6),
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
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              hasLocation ? Icons.location_on : Icons.location_off,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                meal.restaurant.addressText ?? 
                    (hasLocation ? 'Restaurant location' : 'Location not available'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLocationMapDialog(BuildContext context, bool isDark) {
    final meal = widget.meal;
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

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final meal = widget.meal;
    final bgColor = isDark 
        ? const Color(0xFF1A2E22).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.9);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    final borderColor = isDark ? const Color(0xFF2D4A3A) : const Color(0xFFE2E8F0);
    
    return Positioned(
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
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DONATION',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      meal.donationPrice == 0 
                          ? 'FREE'
                          : 'EGP ${meal.donationPrice.toStringAsFixed(2)}',
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
                      onPressed: isClaiming ? null : () async {
                        setState(() => isClaiming = true);
                        
                        final cart = context.read<NgoCartViewModel>();
                        await cart.addToCart(meal);
                        
                        setState(() => isClaiming = false);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ ${meal.title} added to cart'),
                              backgroundColor: AppColors.primaryGreen,
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'View Cart',
                                textColor: Colors.white,
                                onPressed: () => context.push('/ngo/cart'),
                              ),
                            ),
                          );
                          context.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isClaiming)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          else
                            const Icon(Icons.add_shopping_cart, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isClaiming ? 'Adding...' : 'Add to Cart',
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
    );
  }
}


// View-only map viewer widget for NGO
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
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
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
                    color: AppColors.primaryGreen,
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
                  color: AppColors.primaryGreen,
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
                      color: AppColors.primaryGreen,
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
                                  color: AppColors.primaryGreen,
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
                    color: AppColors.primaryGreen,
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
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
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
