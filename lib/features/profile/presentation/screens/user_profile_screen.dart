import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'add_card_screen.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';

class UserProfileScreen extends StatefulWidget {
  static const routeName = '/user-profile';
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    if (user != null && !_isEditing) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      if (user.addresses.isNotEmpty) {
        _addressController.text = user.addresses.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context);

    try {
      await auth.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (_addressController.text.trim().isNotEmpty &&
          !auth.user!.addresses.contains(_addressController.text.trim())) {
        await auth.addAddress(_addressController.text.trim());
      }

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.primaryAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addNewAddress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddressDialog(),
    );

    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      await auth.addAddress(result);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address added successfully'),
          backgroundColor: AppColors.primaryAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please log in to view your profile'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/home');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!_isEditing)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.deepTeal, AppColors.tealAqua],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_isEditing)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isEditing = false;
                    _nameController.text = user.name;
                    _emailController.text = user.email;
                    _phoneController.text = user.phone ?? '';
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
          child: Column(
            children: [
            // Profile Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deepTeal, AppColors.tealAqua],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.phone!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Personal Information Section
            _buildSection(
              title: 'Personal Information',
              icon: Icons.person_outline,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      enabled: false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Addresses Section
            _buildSection(
              title: 'My Addresses',
              icon: Icons.location_on_outlined,
              child: Column(
                children: [
                  if (user.addresses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No addresses added yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...user.addresses
                        .map((address) => _buildAddressCard(address)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _addNewAddress,
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryAccent,
                      side: const BorderSide(color: AppColors.primaryAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Payment Methods Section
            _buildSection(
              title: 'Payment Methods',
              icon: Icons.credit_card_outlined,
              child: Column(
                children: [
                  if (user.cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.credit_card_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No payment methods added',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...user.cards.map((card) => _buildCreditCard(card)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go(AddCardScreen.routeName);
                    },
                    icon: const Icon(Icons.add_card),
                    label: const Text('Add New Card'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryAccent,
                      side: const BorderSide(color: AppColors.primaryAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Account Actions
            _buildSection(
              title: 'Account',
              icon: Icons.settings_outlined,
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.history,
                    title: 'Order History',
                    onTap: () {
                      final ordersController =
                          Provider.of<OrdersController>(context, listen: false);
                      ordersController.setActiveTab(OrderStatus.completed);
                      Navigator.of(context).pushNamed(MyOrdersScreen.routeName);
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.favorite_outline,
                    title: 'Favorites',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Favorites coming soon')),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.local_offer_outlined,
                    title: 'Coupons & Promotions',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupons coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 32),
                  _buildActionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.red,
                    onTap: () async {
                      final router = GoRouter.of(context);
                      await auth.signOut();
                      router.go('/auth');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppColors.darkText,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryAccent),
        filled: true,
        fillColor: enabled ? AppColors.lightBackground : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _buildAddressCard(String address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkText,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // Note: You may need to add a removeAddress method to AuthProvider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address removal coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(Map<String, dynamic> card) {
    final number = (card['number'] ?? '').toString();
    final name = (card['name'] ?? '').toString();
    final expiry = (card['expiry'] ?? '').toString();
    final last4 =
        number.length >= 4 ? number.substring(number.length - 4) : number;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepTeal, AppColors.tealAqua],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Icon(
              Icons.credit_card,
              color: Colors.white.withOpacity(0.3),
              size: 32,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Text(
                      expiry,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '**** **** **** $last4',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  color: titleColor ?? AppColors.primaryAccent, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? AppColors.darkText,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressDialog extends StatefulWidget {
  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter your address',
                prefixIcon: const Icon(Icons.location_on,
                    color: AppColors.primaryAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primaryAccent, width: 2),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _controller.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
