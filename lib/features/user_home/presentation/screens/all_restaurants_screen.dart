import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/restaurant.dart';

class AllRestaurantsScreen extends StatefulWidget {
  const AllRestaurantsScreen({super.key});

  @override
  State<AllRestaurantsScreen> createState() => _AllRestaurantsScreenState();
}

class _AllRestaurantsScreenState extends State<AllRestaurantsScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Restaurant> _all = [];
  List<Restaurant> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('restaurants')
          .select('profile_id, restaurant_name, rating, rating_count, address_text, profiles!inner(avatar_url)')
          .order('rating', ascending: false);

      final list = (res as List).map((j) => Restaurant(
        id: j['profile_id'],
        name: j['restaurant_name'] ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        logoUrl: j['profiles']?['avatar_url'],
        reviewsCount: j['rating_count'] ?? 0,
        addressText: j['address_text'],
      )).toList();

      if (mounted) setState(() { _all = list; _filtered = list; _loading = false; });
    } catch (e) {
      debugPrint('❌ Restaurants error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((r) =>
              r.name.toLowerCase().contains(query) ||
              (r.addressText?.toLowerCase().contains(query) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ⭐ Complex Background
          Positioned.fill(child: AppColors.buildComplexBackground()),
          
          // Content
          SafeArea(
            child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                      color: AppColors.textMain,
                    ),
                    Expanded(
                      child: Text('Restaurants',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: AppColors.textMain)),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.glassCardBgDark, // ← استخدام اللون من AppColors
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassCardBg), // ← استخدام اللون من AppColors
                          ),
                          child: Text('${_filtered.length} found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.glassCardBgLight, // ← استخدام اللون من AppColors
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassCardBorder), // ← استخدام اللون من AppColors
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _search,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, color: AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: 'Search restaurants...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── List ─────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront_rounded, size: 64,
                                  color: AppColors.primary.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text('No restaurants found',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _RestaurantCard(restaurant: _filtered[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/${restaurant.id}/meals', extra: restaurant),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.glassCardBgLight, // ← استخدام اللون من AppColors
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassCardBorder), // ← استخدام اللون من AppColors
              boxShadow: [BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56, height: 56,
                    color: AppColors.primary.withValues(alpha: 0.10),
                    child: restaurant.logoUrl != null && restaurant.logoUrl!.isNotEmpty
                        ? Image.network(restaurant.logoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _Initial(restaurant.name))
                        : _Initial(restaurant.name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(restaurant.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppColors.textMain),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (restaurant.verified)
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                      ]),
                      if (restaurant.addressText != null) ...[
                        const SizedBox(height: 3),
                        Text(restaurant.addressText!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.rating),
                        const SizedBox(width: 3),
                        Text(restaurant.rating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.textMain)),
                        const SizedBox(width: 4),
                        Text('(${restaurant.reviewsCount})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: AppColors.textMuted)),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String name;
  const _Initial(this.name);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 22, fontWeight: FontWeight.w800,
        color: AppColors.primary)),
  );
}
