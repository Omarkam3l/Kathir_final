import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../../../_shared/widgets/location_selector_widget.dart';
import '../widgets/restaurant_bottom_nav.dart';
import '../../data/services/rush_hour_service.dart';
import '../../domain/entities/rush_hour_config.dart';

/// Restaurant Profile Screen - View and edit restaurant details
class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _supabase = Supabase.instance.client;
  late final RushHourService _rushHourService;
  
  Map<String, dynamic>? _restaurantData;
  RushHourConfig? _rushHourConfig;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isLoadingRushHour = true;

  @override
  void initState() {
    super.initState();
    _rushHourService = RushHourService(_supabase);
    _loadRestaurantData();
    _loadRushHourConfig();
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

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Read image as bytes (works on all platforms including web)
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last.toLowerCase();
      final fileName = 'avatar.$fileExt';
      final filePath = '$userId/$fileName';

      // Upload using uploadBinary (works on web)
      await _supabase.storage
          .from('profile-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(fileExt),
            ),
          );

      // Get public URL
      final imageUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      // Update profile with avatar URL
      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      setState(() => _isUploadingImage = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        // Refresh auth provider
        Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _showEditDialog() async {
    final nameController = TextEditingController(
      text: _restaurantData?['restaurant_name'] ?? '',
    );
    final addressController = TextEditingController(
      text: _restaurantData?['address'] ?? '',
    );
    final phoneController = TextEditingController(
      text: _restaurantData?['phone'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Restaurant Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _updateRestaurantData(
        nameController.text,
        addressController.text,
        phoneController.text,
      );
    }
  }

  Future<void> _updateRestaurantData(
    String name,
    String address,
    String phone,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('restaurants').upsert({
        'profile_id': userId,
        'restaurant_name': name,
        'address': address,
        'phone': phone,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        _loadRestaurantData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with avatar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryGreen,
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: user?.avatarUrl != null
                                      ? Image.network(
                                          user!.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _buildDefaultAvatar(),
                                        )
                                      : _buildDefaultAvatar(),
                                ),
                              ),
                              if (_isUploadingImage)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _restaurantData?['restaurant_name'] ?? 'Unnamed Restaurant',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (_restaurantData?['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Restaurant Information
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Restaurant Information'),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            surface,
                            isDark,
                            [
                              _buildInfoRow(
                                Icons.store,
                                'Name',
                                _restaurantData?['restaurant_name'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                Icons.location_on,
                                'Address',
                                _restaurantData?['address'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                Icons.phone,
                                'Phone',
                                _restaurantData?['phone'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                Icons.star,
                                'Rating',
                                (_restaurantData?['rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Rush Hour Settings
                          _buildSectionTitle('Rush Hour Settings'),
                          const SizedBox(height: 12),
                          _buildRushHourCard(surface, isDark),
                          const SizedBox(height: 24),

                          // Location
                          _buildSectionTitle('Location'),
                          const SizedBox(height: 12),
                          _buildLocationCard(surface, isDark),
                          const SizedBox(height: 24),

                          // Leaderboard
                          _buildSectionTitle('Leaderboard'),
                          const SizedBox(height: 12),
                          _buildLeaderboardCard(surface, isDark),
                          const SizedBox(height: 24),

                          // Account Information
                          _buildSectionTitle('Account Information'),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          _buildActionButton(
                            'Edit Profile',
                            Icons.edit,
                            _showEditDialog,
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
                          const SizedBox(height: 80), // Space for bottom nav
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: 4,
        onTap: (index) {
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
              context.go('/restaurant-dashboard/leaderboard');
              break;
            case 4:
              // Already on profile
              break;
          }
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primaryGreen.withValues(alpha: 0.2),
      child: const Icon(
        Icons.restaurant,
        size: 50,
        color: AppColors.primaryGreen,
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

  Future<void> _loadRushHourConfig() async {
    setState(() => _isLoadingRushHour = true);
    try {
      final config = await _rushHourService.getMyRushHour();
      if (mounted) {
        setState(() {
          _rushHourConfig = config;
          _isLoadingRushHour = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRushHour = false);
      }
    }
  }

  Widget _buildRushHourCard(Color surface, bool isDark) {
    if (_isLoadingRushHour) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isActive = _rushHourConfig?.isActive ?? false;
    final activeNow = _rushHourConfig?.activeNow ?? false;
    final discountPercentage = _rushHourConfig?.discountPercentage ?? 50;

    return InkWell(
      onTap: () async {
        await context.push('/restaurant-dashboard/surplus-settings');
        // Reload rush hour config when returning
        _loadRushHourConfig();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeNow
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: activeNow ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: activeNow
                        ? AppColors.primaryGreen.withValues(alpha: 0.1)
                        : (isDark
                            ? Colors.grey[800]
                            : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: activeNow
                        ? AppColors.primaryGreen
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Rush Hour',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryGreen.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? AppColors.primaryGreen
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? '$discountPercentage% discount during rush hours'
                            : 'Set up time-based discounts',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
            if (activeNow) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Rush Hour Active Now!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '$discountPercentage% OFF',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(Color surface, bool isDark) {
    return InkWell(
      onTap: () {
        context.push('/restaurant-dashboard/leaderboard');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.leaderboard,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restaurant Rankings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See how you rank among other restaurants',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildLocationCard(Color surface, bool isDark) {
    final hasLocation = _restaurantData?['latitude'] != null &&
        _restaurantData?['longitude'] != null;
    final addressText = _restaurantData?['address_text'] as String?;

    return InkWell(
      onTap: () => _showLocationSelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation
                ? AppColors.primaryGreen.withValues(alpha: 0.3)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: hasLocation ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasLocation
                    ? AppColors.primaryGreen.withValues(alpha: 0.1)
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: hasLocation
                    ? AppColors.primaryGreen
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restaurant Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasLocation
                        ? addressText ?? 'Location set'
                        : 'Set your restaurant location',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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

  Future<void> _showLocationSelector() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectorWidget(
          initialLatitude: _restaurantData?['latitude'] as double?,
          initialLongitude: _restaurantData?['longitude'] as double?,
          initialAddress: _restaurantData?['address_text'] as String?,
          onLocationSelected: _saveLocation,
        ),
      ),
    );
  }

  Future<void> _saveLocation(double lat, double lng, String address) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('restaurants').update({
        'latitude': lat,
        'longitude': lng,
        'address_text': address,
      }).eq('profile_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        _loadRestaurantData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
