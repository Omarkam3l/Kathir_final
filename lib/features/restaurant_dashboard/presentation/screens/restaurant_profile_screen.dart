import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../widgets/restaurant_bottom_nav.dart';

/// Restaurant Profile Screen - View and edit restaurant details
class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _restaurantData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('restaurants')
          .select()
          .eq('profile_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _restaurantData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            border: Border.all(
                              color: AppColors.primaryGreen,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            size: 50,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _restaurantData?['name'] ?? user?.fullName ?? 'Restaurant',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Restaurant Info
                  _buildSectionTitle('Restaurant Information'),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    surface,
                    isDark,
                    [
                      _buildInfoRow(Icons.store, 'Name', _restaurantData?['name'] ?? 'N/A'),
                      _buildInfoRow(Icons.location_on, 'Address', _restaurantData?['address'] ?? 'N/A'),
                      _buildInfoRow(Icons.phone, 'Phone', _restaurantData?['phone'] ?? 'N/A'),
                      _buildInfoRow(Icons.star, 'Rating', '${_restaurantData?['rating'] ?? 0.0}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account Info
                  _buildSectionTitle('Account Information'),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    surface,
                    isDark,
                    [
                      _buildInfoRow(Icons.email, 'Email', user?.email ?? 'N/A'),
                      _buildInfoRow(Icons.badge, 'Role', 'Restaurant'),
                      _buildInfoRow(
                        Icons.verified,
                        'Status',
                        user?.isApproved == true ? 'Approved' : 'Pending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  _buildSectionTitle('Actions'),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'Edit Profile',
                    Icons.edit,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile coming soon')),
                      );
                    },
                    surface,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'Change Password',
                    Icons.lock,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change password coming soon')),
                      );
                    },
                    surface,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'Logout',
                    Icons.logout,
                    _logout,
                    surface,
                    isDark,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/restaurant-dashboard/meals');
              break;
            case 1:
              context.go('/restaurant-dashboard/meals');
              break;
            case 2:
              // TODO: Navigate to orders
              break;
            case 3:
              // Already on profile
              break;
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(Color surface, bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: children
            .expand((widget) => [widget, const Divider(height: 24)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    Color surface,
    bool isDark, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.3)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.primaryGreen,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDestructive ? AppColors.error : null,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
