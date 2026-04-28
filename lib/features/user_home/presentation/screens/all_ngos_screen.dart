import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';

class AllNGOsScreen extends StatefulWidget {
  const AllNGOsScreen({super.key});

  @override
  State<AllNGOsScreen> createState() => _AllNGOsScreenState();
}

class _AllNGOsScreenState extends State<AllNGOsScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
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
      // ✅ Single query with JOIN - much faster!
      final res = await _supabase
          .from('ngos')
          .select('profile_id, organization_name, address_text, profiles!inner(avatar_url)')
          .order('organization_name');

      final list = (res as List).map((j) => {
        'id': j['profile_id'] ?? '',
        'name': j['organization_name'] ?? '',
        'address': j['address_text'] ?? '',
        'logo': j['profiles']?['avatar_url'],
      }).toList();

      if (mounted) setState(() { _all = list; _filtered = list; _loading = false; });
    } catch (e) {
      debugPrint('❌ NGOs error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((n) =>
              (n['name'] as String).toLowerCase().contains(query) ||
              (n['address'] as String).toLowerCase().contains(query)).toList();
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
                      child: Text('Top NGOs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: AppColors.textMain)),
                    ),
                    // Count badge
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
                          hintText: 'Search NGOs...',
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
                                Icon(Icons.volunteer_activism_rounded, size: 64,
                                  color: AppColors.primary.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text('No NGOs found',
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
                              itemBuilder: (_, i) => _NgoCard(ngo: _filtered[i]),
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

class _NgoCard extends StatelessWidget {
  final Map<String, dynamic> ngo;
  const _NgoCard({required this.ngo});

  @override
  Widget build(BuildContext context) {
    final logo    = ngo['logo'] as String?;
    final name    = ngo['name'] as String;
    final address = ngo['address'] as String;

    return GestureDetector(
      onTap: () => context.push('/ngo/${ngo['id']}', extra: ngo),
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
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56, height: 56,
                    color: AppColors.success.withValues(alpha: 0.10),
                    child: logo != null && logo.isNotEmpty
                        ? Image.network(logo, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _Initial(name))
                        : _Initial(name),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(address,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('NGO Partner',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                      ),
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
        color: AppColors.success)),
  );
}
