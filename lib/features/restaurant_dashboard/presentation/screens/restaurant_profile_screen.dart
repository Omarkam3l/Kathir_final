import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isUploadingImage = false;

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
                                '${(_restaurantData?['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
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
                                '${(_restaurantData?['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
                              ),
                            ],
                          ),
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
                            'Change Password',
                            Icons.lock,
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Change password coming soon'),
                                ),
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
                          const SizedBox(height: 80), // Space for bottom nav
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: RestaurantBottomNav(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/restaurant-dashboard');
              break;
            case 1:
              context.go('/restaurant-dashboard/meals');
              break;
            case 2:
              context.go('/restaurant-dashboard/orders');
              break;
            case 3:
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
}
