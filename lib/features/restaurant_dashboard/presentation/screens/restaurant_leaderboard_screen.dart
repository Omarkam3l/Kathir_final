import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/services/leaderboard_service.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../widgets/restaurant_bottom_nav.dart';
import '../widgets/my_rank_card.dart';
import 'package:go_router/go_router.dart';

class RestaurantLeaderboardScreen extends StatefulWidget {
  const RestaurantLeaderboardScreen({super.key});

  @override
  State<RestaurantLeaderboardScreen> createState() =>
      _RestaurantLeaderboardScreenState();
}

class _RestaurantLeaderboardScreenState
    extends State<RestaurantLeaderboardScreen> {
  late final LeaderboardService _leaderboardService;
  
  String _selectedPeriod = 'week';
  List<LeaderboardEntry> _leaderboard = [];
  MyRestaurantRank? _myRank;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _leaderboardService = LeaderboardService(Supabase.instance.client);
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leaderboard = await _leaderboardService.fetchLeaderboard(
        _selectedPeriod,
        forceRefresh: forceRefresh,
      );
      final myRank = await _leaderboardService.fetchMyRank(_selectedPeriod);

      if (!mounted) return;
      
      setState(() {
        _leaderboard = leaderboard;
        _myRank = myRank;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    
    setState(() {
      _selectedPeriod = period;
    });
    _loadLeaderboard();
  }

  Future<void> _onRefresh() async {
    await _loadLeaderboard(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF221910) : const Color(0xFFF8F7F6),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(isDark),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error != null
                          ? _buildErrorState()
                          : _buildLeaderboardContent(isDark),
                ),
              ],
            ),
            
            // Sticky "Your Impact" card
            if (!_isLoading && _error == null)
              Positioned(
                bottom: 80, // Above bottom nav
                left: 0,
                right: 0,
                child: MyRankCard(
                  myRank: _myRank,
                  isDark: isDark,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: -1, // Not in bottom nav
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF221910).withOpacity(0.95)
            : const Color(0xFFF8F7F6).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF3D3027) : const Color(0xFFE7E5E4),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF1B140D),
            ),
            onPressed: () => context.go('/restaurant-dashboard'),
          ),
          const Expanded(
            child: Text(
              'Leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDark ? Colors.white : const Color(0xFF1B140D),
            ),
            onPressed: () {
              // Future: Add filter options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(bool isDark) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          // Period filter chips
          SliverToBoxAdapter(
            child: _buildPeriodFilters(isDark),
          ),
          
          // Podium for top 3
          if (_leaderboard.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildPodium(isDark),
            ),
          
          // Rest of the list
          if (_leaderboard.length > 3)
            SliverToBoxAdapter(
              child: _buildRestOfList(isDark),
            ),
          
          // Empty state
          if (_leaderboard.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(isDark),
            ),
          
          // Bottom padding for sticky card
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildPeriodChip('This Week', 'week', isDark),
            const SizedBox(width: 12),
            _buildPeriodChip('This Month', 'month', isDark),
            const SizedBox(width: 12),
            _buildPeriodChip('All Time', 'all', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, bool isDark) {
    final isSelected = _selectedPeriod == value;
    
    return GestureDetector(
      onTap: () => _onPeriodChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : isDark
                  ? const Color(0xFF2D241B)
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : isDark
                    ? const Color(0xFF4A3F33)
                    : const Color(0xFFE7E5E4),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : const Color(0xFF1B140D),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(bool isDark) {
    final top3 = _leaderboard.take(3).toList();
    
    // Arrange as: 2nd, 1st, 3rd
    final rank1 = top3.length > 0 ? top3[0] : null;
    final rank2 = top3.length > 1 ? top3[1] : null;
    final rank3 = top3.length > 2 ? top3[2] : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2
          if (rank2 != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPodiumItem(rank2, 2, isDark),
              ),
            ),
          
          // Rank 1
          if (rank1 != null)
            Expanded(
              child: _buildPodiumItem(rank1, 1, isDark),
            ),
          
          // Rank 3
          if (rank3 != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPodiumItem(rank3, 3, isDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int rank, bool isDark) {
    final colors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };
    
    final sizes = {
      1: 96.0,
      2: 80.0,
      3: 80.0,
    };
    
    final color = colors[rank]!;
    final size = sizes[rank]!;
    
    return Column(
      children: [
        // Crown for rank 1
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.emoji_events,
              color: Color(0xFFFFD700),
              size: 32,
            ),
          ),
        
        // Avatar with rank badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
                boxShadow: rank == 1
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipOval(
                child: entry.avatarUrl != null
                    ? Image.network(
                        entry.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(entry.name),
                      )
                    : _buildDefaultAvatar(entry.name),
              ),
            ),
            
            // Rank badge
            Positioned(
              bottom: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: rank == 1 ? 32 : 24,
                  height: rank == 1 ? 32 : 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF221910) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 2 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: rank == 1 ? 14 : 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Restaurant name
        Text(
          entry.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: rank == 1 ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1B140D),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Score
        Text(
          '${entry.score} meals',
          style: TextStyle(
            fontSize: rank == 1 ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        
        // Hero badge for rank 1
        if (rank == 1)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 12,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'HERO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRestOfList(bool isDark) {
    final remaining = _leaderboard.skip(3).toList();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D241B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'REST OF THE BEST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : const Color(0xFF9A734C),
                letterSpacing: 1.2,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: remaining.length,
            itemBuilder: (context, index) {
              return _buildListItem(remaining[index], isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(LeaderboardEntry entry, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF221910).withOpacity(0.5)
            : const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white54 : const Color(0xFF9A734C),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? Image.network(
                      entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(entry.name),
                    )
                  : _buildDefaultAvatar(entry.name),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Restaurant info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B140D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.score} meals distributed',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF9A734C),
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Text(
            '${entry.score}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: AppColors.primaryGreen.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load leaderboard',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1B140D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start selling meals to appear on the leaderboard!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF9A734C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/restaurant-dashboard');
        break;
      case 1:
        context.go('/restaurant-dashboard/orders');
        break;
      case 2:
        context.go('/restaurant-dashboard/meals');
        break;
      case 3:
        // Chats - coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chats feature coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 4:
        context.go('/restaurant-dashboard/profile');
        break;
    }
  }
}
