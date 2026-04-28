import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/entities/meal_offer.dart';
import '../widgets/meal_card_grid.dart';

class RestaurantMealsScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantMealsScreen({super.key, required this.restaurant});

  @override
  State<RestaurantMealsScreen> createState() => _RestaurantMealsScreenState();
}

class _RestaurantMealsScreenState extends State<RestaurantMealsScreen> {
  final _supabase = Supabase.instance.client;
  List<MealOffer> _meals = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await _supabase
          .from('meals')
          .select('id, title, description, category, image_url, original_price, discounted_price, quantity_available, expiry_date, location, status, is_donation_available')
          .eq('restaurant_id', widget.restaurant.id)
          .eq('status', 'active')
          .gt('quantity_available', 0)
          .gt('expiry_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _meals = (res as List).map((j) => MealOffer(
            id: j['id'],
            title: j['title'] ?? '',
            description: j['description'] ?? '',
            category: j['category'] ?? 'Meals',
            imageUrl: j['image_url'] ?? '',
            originalPrice: (j['original_price'] as num?)?.toDouble() ?? 0,
            donationPrice: (j['discounted_price'] as num?)?.toDouble() ?? 0,
            quantity: j['quantity_available'] ?? 0,
            expiry: DateTime.parse(j['expiry_date']),
            location: j['location'] ?? '',
            restaurant: widget.restaurant,
          )).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

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
                        child: Text(r.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.textMain),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),

                // ── Restaurant info card ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.glassCardBgLight, // ← استخدام اللون من AppColors
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassCardBorder), // ← استخدام اللون من AppColors
                        boxShadow: [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          // Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 72, height: 72,
                              color: AppColors.primary.withValues(alpha: 0.10),
                              child: r.logoUrl != null && r.logoUrl!.isNotEmpty
                                  ? Image.network(r.logoUrl!, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _Initial(r.name))
                                  : _Initial(r.name),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(r.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16, fontWeight: FontWeight.w800,
                                      color: AppColors.textMain),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  if (r.verified)
                                    const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                                ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.rating),
                                  const SizedBox(width: 4),
                                  Text('${r.rating.toStringAsFixed(1)}  (${r.reviewsCount} reviews)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: AppColors.textMain)),
                                ]),
                                if (r.addressText != null) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 3),
                                    Expanded(child: Text(r.addressText!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11, color: AppColors.textMuted),
                                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Meals ─────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error.isNotEmpty
                        ? _ErrorState(onRetry: _load)
                        : _meals.isEmpty
                            ? const _EmptyState()
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: AppColors.primary,
                                child: CustomScrollView(
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                                      sliver: SliverToBoxAdapter(
                                        child: Text(
                                          'Available Meals (${_meals.length})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16, fontWeight: FontWeight.w700,
                                            color: AppColors.textMain),
                                        ),
                                      ),
                                    ),
                                    SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                                      sliver: SliverGrid(
                                        delegate: SliverChildBuilderDelegate(
                                          (_, i) => MealCardGrid(offer: _meals[i]),
                                          childCount: _meals.length,
                                        ),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.65,
                                        ),
                                      ),
                                    ),
                                  ],
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

// ── NGO Details Screen ────────────────────────────────────────────────────────

class NgoDetailsScreen extends StatefulWidget {
  final String ngoId;
  final String ngoName;
  final String? logoUrl;
  final String? address;

  const NgoDetailsScreen({
    super.key,
    required this.ngoId,
    required this.ngoName,
    this.logoUrl,
    this.address,
  });

  @override
  State<NgoDetailsScreen> createState() => _NgoDetailsScreenState();
}

class _NgoDetailsScreenState extends State<NgoDetailsScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _details;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _supabase
          .from('ngos')
          .select('organization_name, address_text, latitude, longitude, profiles!inner(avatar_url, full_name, phone_number)')
          .eq('profile_id', widget.ngoId)
          .maybeSingle();

      if (mounted) setState(() { _details = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _details?['organization_name'] ?? widget.ngoName;
    final address = _details?['address_text'] ?? widget.address ?? '';
    final logo = _details?['profiles']?['avatar_url'] ?? widget.logoUrl;
    final phone = _details?['profiles']?['phone_number'] ?? '';

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
                        child: Text(name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.textMain),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [
                          // ── NGO info card ─────────────────────────
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.glassCardBgLight, // ← استخدام اللون من AppColors
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.glassCardBorder), // ← استخدام اللون من AppColors
                                  boxShadow: [BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.06),
                                    blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Column(
                                  children: [
                                    // Logo + name
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            width: 80, height: 80,
                                            color: AppColors.success.withValues(alpha: 0.10),
                                            child: logo != null && logo.isNotEmpty
                                                ? Image.network(logo, fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => _Initial(name, color: AppColors.success))
                                                : _Initial(name, color: AppColors.success),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 18, fontWeight: FontWeight.w800,
                                                  color: AppColors.textMain)),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text('NGO Partner',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12, fontWeight: FontWeight.w600,
                                                    color: AppColors.success)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(height: 1),
                                    const SizedBox(height: 16),
                                    // Details
                                    if (address.isNotEmpty)
                                      _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: address),
                                    if (phone.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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

// ── Shared helpers ────────────────────────────────────────────────────────────

class _Initial extends StatelessWidget {
  final String name;
  final Color? color;
  const _Initial(this.name, {this.color});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: color ?? AppColors.primary)),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: AppColors.textMuted)),
            Text(value, style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
          ],
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.restaurant_menu_rounded, size: 64,
        color: AppColors.primary.withValues(alpha: 0.3)),
      const SizedBox(height: 12),
      Text('No meals available',
        style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.textMuted)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline_rounded, size: 64,
        color: AppColors.error.withValues(alpha: 0.5)),
      const SizedBox(height: 12),
      Text('Something went wrong',
        style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.textMuted)),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    ]),
  );
}
