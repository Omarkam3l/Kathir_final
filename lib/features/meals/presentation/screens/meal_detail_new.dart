import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../user_home/domain/entities/meal_offer.dart';
import '../../../profile/presentation/providers/foodie_state.dart';
import '../../../user_home/presentation/viewmodels/favorites_viewmodel.dart';

class MealDetailScreen extends StatelessWidget {
  final MealOffer product;

  const MealDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image with Navigation
              _buildHeroSection(context, isDark),
              
              // Main Content
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
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
              ),
            ],
          ),
          
          // Sticky Bottom Bar
          _buildBottomBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: false,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
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
        Consumer<FavoritesViewModel>(
          builder: (context, favViewModel, _) {
            final isFav = favViewModel.isFavorite(product.id);
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.primaryGreen : Colors.white,
                    ),
                    onPressed: () async {
                      await favViewModel.toggleFavorite(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFav ? 'Removed from favorites' : 'Added to favorites',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
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
            Image.network(
              product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.restaurant, color: Colors.white54, size: 64),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            product.title,
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
              'EGP ${product.donationPrice.toStringAsFixed(2)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF139E4B),
              ),
            ),
            if (product.originalPrice > product.donationPrice)
              Text(
                'EGP ${product.originalPrice.toStringAsFixed(2)}',
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
              color: AppColors.primaryGreen.withOpacity(0.1),
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
                      product.restaurant.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${product.restaurant.rating} (120 reviews)',
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
          TextButton(
            onPressed: () {
              // TODO: Navigate to restaurant profile
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              foregroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'View Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    final pickupTime = DateFormat('h:mm a').format(product.expiry);
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF2D1F0D).withOpacity(0.3)
                  : const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF4A3319).withOpacity(0.3)
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
                  ? const Color(0xFF0D2D1F).withOpacity(0.3)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF1A4A33).withOpacity(0.3)
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
                  'Saves 0.5kg CO2',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF2D0D0D).withOpacity(0.3)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF4A1919).withOpacity(0.3)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Text(
            'Hurry! Only ${product.quantity} portions left.',
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
          'Freshly prepared biryani made with organic basmati rice and mixed garden vegetables. Saved from the lunch rush, this dish is packed with aromatic spices and flavors. Perfect for a hearty dinner.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.6,
            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsAllergens(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final allergenBg = isDark ? const Color(0xFF2D1F0D).withOpacity(0.3) : const Color(0xFFFFF4E6);
    final allergenBorder = isDark ? const Color(0xFF4A3319).withOpacity(0.3) : const Color(0xFFFFE4CC);
    final allergenText = isDark ? const Color(0xFFFFB366) : const Color(0xFFEA580C);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildIngredientChip('Basmati Rice', bgColor, borderColor, isDark),
            _buildIngredientChip('Carrots', bgColor, borderColor, isDark),
            _buildIngredientChip('Peas', bgColor, borderColor, isDark),
            _buildAllergenChip('Contains: Nuts', allergenBg, allergenBorder, allergenText),
            _buildAllergenChip('Contains: Dairy', allergenBg, allergenBorder, allergenText),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientChip(String label, Color bgColor, Color borderColor, bool isDark) {
    final textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildAllergenChip(String label, Color bgColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPickupLocation(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D1B12);
    // Cairo, Egypt coordinates
    const cairoLocation = LatLng(30.0444, 31.2357);
    
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 128,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: cairoLocation,
                initialZoom: 13.0,
                interactionOptions: InteractionOptions(
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
                      point: cairoLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cairo, Egypt',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final bgColor = isDark 
        ? const Color(0xFF1A2E22).withOpacity(0.9)
        : Colors.white.withOpacity(0.9);
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
                      'TOTAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'EGP ${product.donationPrice.toStringAsFixed(2)}',
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
                        context.read<FoodieState>().addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.title} added to cart'),
                            backgroundColor: AppColors.primaryGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: const Color(0xFF052E11),
                        elevation: 0,
                        shadowColor: AppColors.primaryGreen.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                              letterSpacing: 0.5,
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
