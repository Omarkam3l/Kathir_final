import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_map_viewmodel.dart';
import '../widgets/ngo_bottom_nav.dart';
import '../widgets/ngo_map_meal_card.dart';

/// NGO Map Screen - Interactive map showing meal locations
class NgoMapScreen extends StatefulWidget {
  const NgoMapScreen({super.key});

  @override
  State<NgoMapScreen> createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends State<NgoMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NgoMapViewModel>().loadMeals();
    });
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
                _buildHeader(isDark, viewModel),
                _buildSearchButton(isDark),
                if (viewModel.selectedMeal != null)
                  _buildMealCarousel(viewModel, isDark),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const NgoBottomNav(currentIndex: 2),
    );
  }

  Widget _buildMap(NgoMapViewModel viewModel, bool isDark) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: viewModel.currentLocation,
        initialZoom: 14.0,
        onTap: (_, __) => viewModel.clearSelection(),
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: viewModel.mealMarkers.map((mealLocation) {
            final isSelected = viewModel.selectedMeal?.id == mealLocation.meal.id;
            return Marker(
              point: mealLocation.location,
              width: isSelected ? 56 : 40,
              height: isSelected ? 56 : 40,
              child: GestureDetector(
                onTap: () => viewModel.selectMeal(mealLocation.meal),
                child: _buildMarker(isSelected, isDark),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMarker(bool isSelected, bool isDark) {
    return Column(
      children: [
        Container(
          width: isSelected ? 56 : 40,
          height: isSelected ? 56 : 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : (isDark ? Colors.white : Colors.black),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primaryGreen.withOpacity(0.4)
                    : Colors.black.withOpacity(0.2),
                blurRadius: isSelected ? 15 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant,
            color: isSelected ? Colors.black : (isDark ? Colors.black : Colors.white),
            size: isSelected ? 26 : 20,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 0,
            height: 0,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(width: 8, color: Colors.transparent),
                right: BorderSide(width: 8, color: Colors.transparent),
                top: BorderSide(width: 8, color: AppColors.primaryGreen),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, NgoMapViewModel viewModel) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6))
              .withOpacity(0.9),
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SEARCHING AREA',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      viewModel.locationName,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: const Icon(Icons.filter_list, size: 20),
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
                  child: const Icon(
                    Icons.handshake,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(bool isDark) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            // Implement search in this area
          },
          icon: const Icon(Icons.search, size: 20),
          label: const Text(
            'Search this area',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1A2E22) : Colors.white,
            foregroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            elevation: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildMealCarousel(NgoMapViewModel viewModel, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 170,
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.88),
          itemCount: viewModel.mealMarkers.length,
          onPageChanged: (index) {
            viewModel.selectMeal(viewModel.mealMarkers[index].meal);
            _mapController.move(
              viewModel.mealMarkers[index].location,
              14.0,
            );
          },
          itemBuilder: (context, index) {
            final mealLocation = viewModel.mealMarkers[index];
            final isSelected = viewModel.selectedMeal?.id == mealLocation.meal.id;
            return NgoMapMealCard(
              meal: mealLocation.meal,
              isDark: isDark,
              isSelected: isSelected,
              onClaim: () => viewModel.claimMeal(mealLocation.meal, context),
              onViewDetails: () {
                context.push('/ngo/meal/${mealLocation.meal.id}', extra: mealLocation.meal);
              },
            );
          },
        ),
      ),
    );
  }
}
