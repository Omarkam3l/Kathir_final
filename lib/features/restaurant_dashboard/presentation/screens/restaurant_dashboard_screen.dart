import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';

/// Restaurant Dashboard screen for adding meal listings
/// Matches the restaurant_home_page HTML design
class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Form state
  String _category = 'meals';
  int _quantity = 5;
  String _unit = 'portions';
  String _fulfillmentMethod = 'pickup';
  TimeOfDay? _pickupDeadline;
  DateTime? _bestBefore;
  bool _isDonationAvailable = true;
  bool _isLoading = false;

  // Stats
  int _activeListings = 0;
  int _mealsShared = 0;
  double _rating = 0.0;
  String? _restaurantId;
  String? _restaurantName;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Get restaurant linked to this user
      final restaurantRes = await _supabase
          .from('restaurants')
          .select('id, name, rating')
          .eq('id', userId)
          .maybeSingle();

      if (restaurantRes != null) {
        _restaurantId = restaurantRes['id'];
        _restaurantName = restaurantRes['name'];
        _rating = (restaurantRes['rating'] as num?)?.toDouble() ?? 0.0;
      }

      // Get stats
      final mealsRes = await _supabase
          .from('meals')
          .select('id, status')
          .eq('restaurant_id', _restaurantId ?? userId);

      _activeListings = (mealsRes as List).where((m) => m['status'] == 'active').length;
      _mealsShared = (mealsRes as List).where((m) => m['status'] == 'sold').length;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading restaurant data: $e');
    }
  }

  Future<void> _publishListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant not found. Please try again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Calculate pickup deadline datetime
      DateTime? pickupDeadline;
      if (_pickupDeadline != null) {
        final now = DateTime.now();
        pickupDeadline = DateTime(
          now.year, now.month, now.day,
          _pickupDeadline!.hour, _pickupDeadline!.minute,
        );
        // If time is before now, set to tomorrow
        if (pickupDeadline.isBefore(now)) {
          pickupDeadline = pickupDeadline.add(const Duration(days: 1));
        }
      }

      await _supabase.from('meals').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : 'Pickup at restaurant',
        'restaurant_id': _restaurantId,
        'category': _category,
        'quantity': _quantity,
        'unit': _unit,
        'fulfillment_method': _fulfillmentMethod,
        'is_donation_available': _isDonationAvailable,
        'status': 'active',
        'original_price': 0.0, // Set by restaurant later or default
        'donation_price': 0.0,
        'expiry': _bestBefore?.toIso8601String() ?? 
            DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
        'pickup_deadline': pickupDeadline?.toIso8601String(),
        'image_url': '', // TODO: Implement image upload
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing published successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _quantity = 5;
          _pickupDeadline = null;
          _bestBefore = null;
        });
        // Refresh stats
        _loadRestaurantData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark, user?.fullName ?? _restaurantName ?? 'Restaurant'),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Summary
                    _buildStatsSection(surface, isDark),
                    
                    // Form Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Surplus Listing',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share your extra food with the community.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Form
                    _buildMealForm(surface, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom publish button
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark, String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withOpacity(0.2),
              border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.restaurant, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Color surface, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('$_activeListings', 'Active Listings', AppColors.primaryGreen, surface, isDark),
          const SizedBox(width: 12),
          _buildStatCard('$_mealsShared', 'Meals Shared', null, surface, isDark),
          const SizedBox(width: 12),
          _buildStatCard(
            _rating.toStringAsFixed(1), 
            'Rating', 
            null, 
            surface, 
            isDark,
            trailing: const Icon(Icons.star, color: Colors.amber, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color? valueColor, Color surface, bool isDark, {Widget? trailing}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 4), trailing],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealForm(Color surface, bool isDark) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image upload placeholder
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4), width: 2),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primaryGreen.withOpacity(0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: const Icon(Icons.add_a_photo, size: 28, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to add food photos',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _buildLabel('Food Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('e.g. Grilled Chicken Salad', isDark),
              validator: (v) => v?.isEmpty == true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 20),

            // Description
            _buildLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _inputDecoration('Briefly describe ingredients and allergens...', isDark),
            ),
            const SizedBox(height: 20),

            // Category chips
            _buildLabel('Category'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('meals', 'Meals', Icons.restaurant),
                  _buildCategoryChip('bakery', 'Bakery', Icons.bakery_dining),
                  _buildCategoryChip('raw_ingredients', 'Raw Ingredients', Icons.eco),
                  _buildCategoryChip('vegan', 'Vegan', Icons.eco),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quantity & Unit
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Quantity'),
                      const SizedBox(height: 8),
                      _buildQuantitySelector(isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Unit'),
                      const SizedBox(height: 8),
                      _buildUnitDropdown(isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Pickup Deadline'),
                      const SizedBox(height: 8),
                      _buildTimePicker(isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Best Before'),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fulfillment method
            _buildLabel('Fulfillment Method'),
            const SizedBox(height: 8),
            _buildFulfillmentToggle(isDark),
            const SizedBox(height: 8),
            Text(
              'NGOs will be notified based on your selection.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Donation toggle
            SwitchListTile(
              value: _isDonationAvailable,
              onChanged: (v) => setState(() => _isDonationAvailable = v),
              title: const Text('Available for NGO Donation'),
              subtitle: const Text('Allow NGOs to claim this meal for free'),
              activeColor: AppColors.primaryGreen,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => setState(() => _category = value),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : null),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selectedColor: AppColors.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(1, 999)),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity = (_quantity + 1).clamp(1, 999)),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unit,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'portions', child: Text('Portions')),
            DropdownMenuItem(value: 'kilograms', child: Text('Kilograms')),
            DropdownMenuItem(value: 'items', child: Text('Items')),
            DropdownMenuItem(value: 'boxes', child: Text('Boxes')),
          ],
          onChanged: (v) => setState(() => _unit = v ?? 'portions'),
        ),
      ),
    );
  }

  Widget _buildTimePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _pickupDeadline ?? TimeOfDay.now(),
        );
        if (time != null) setState(() => _pickupDeadline = time);
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _pickupDeadline?.format(context) ?? 'Select time',
                style: TextStyle(
                  color: _pickupDeadline != null 
                      ? null 
                      : (isDark ? Colors.grey[500] : Colors.grey[400]),
                ),
              ),
            ),
            const Icon(Icons.access_time, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _bestBefore ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            setState(() {
              _bestBefore = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            });
          }
        }
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _bestBefore != null
                    ? '${_bestBefore!.month}/${_bestBefore!.day} ${_bestBefore!.hour}:${_bestBefore!.minute.toString().padLeft(2, '0')}'
                    : 'Select date & time',
                style: TextStyle(
                  color: _bestBefore != null 
                      ? null 
                      : (isDark ? Colors.grey[500] : Colors.grey[400]),
                ),
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFulfillmentToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption('pickup', 'Pickup Only', Icons.storefront, isDark),
          ),
          Expanded(
            child: _buildToggleOption('delivery', 'Delivery', Icons.local_shipping, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String value, String label, IconData icon, bool isDark) {
    final isSelected = _fulfillmentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _fulfillmentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primaryGreen : null),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : null,
                color: isSelected ? AppColors.primaryGreen : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _publishListing,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Publish Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
