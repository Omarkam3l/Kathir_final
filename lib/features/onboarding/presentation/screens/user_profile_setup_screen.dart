import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

class UserProfileSetupScreen extends StatefulWidget {
  static const routeName = '/onboarding/profile';
  
  const UserProfileSetupScreen({super.key});

  @override
  State<UserProfileSetupScreen> createState() => _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState extends State<UserProfileSetupScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _avatarUrl;
  File? _avatarFile;
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddressLabel;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = user.userMetadata?['full_name'] ?? '';
        _phoneController.text = user.userMetadata?['phone_number'] ?? '';
      });

      // Load avatar from profile
      try {
        final profile = await _supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        
        if (profile != null && profile['avatar_url'] != null) {
          setState(() {
            _avatarUrl = profile['avatar_url'];
          });
        }
      } catch (e) {
        print('[ProfileSetup] Error loading avatar: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _avatarFile = File(image.path);
        });
      }
    } catch (e) {
      print('[ProfileSetup] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_avatarFile == null) return _avatarUrl;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileExt = _avatarFile!.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      print('[ProfileSetup] Uploading avatar to: $filePath');

      await _supabase.storage.from('avatars').upload(
        filePath,
        _avatarFile!,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      print('[ProfileSetup] Avatar uploaded: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('[ProfileSetup] Error uploading avatar: $e');
      return null;
    }
  }

  Future<void> _selectAddress() async {
    final result = await context.push('/onboarding/select-address');
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedAddressLabel = result['label'];
        _selectedAddress = result['address'];
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
      });
      print('[ProfileSetup] Address selected: $_selectedAddress');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('[ProfileSetup] Error: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('[ProfileSetup] Saving profile for user: $userId');

      // Upload avatar if selected
      String? avatarUrl = _avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _uploadAvatar();
      }

      // Update profile
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'is_profile_completed': true,
      }).eq('id', userId);

      print('[ProfileSetup] Profile updated');

      // Save address if selected
      if (_selectedAddress != null && _selectedLatitude != null && _selectedLongitude != null) {
        await _supabase.from('user_addresses').insert({
          'user_id': userId,
          'label': _selectedAddressLabel ?? 'Home',
          'address_text': _selectedAddress,
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
          'is_default': true,
        });
        print('[ProfileSetup] Address saved');
      }

      // Refresh auth provider
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshUser();
        print('[ProfileSetup] Refreshed auth provider');
      }

      if (mounted) {
        print('[ProfileSetup] Navigating to category selection');
        context.go('/onboarding/categories');
      }
    } catch (e) {
      print('[ProfileSetup] Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skip() async {
    print('[ProfileSetup] Skip button pressed');
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        print('[ProfileSetup] Marking profile as completed for skip');
        await _supabase
            .from('profiles')
            .update({'is_profile_completed': true})
            .eq('id', userId);
        print('[ProfileSetup] Profile marked as completed');

        // Refresh auth provider
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshUser();
          print('[ProfileSetup] Refreshed auth provider after skip');
        }

        if (mounted) {
          print('[ProfileSetup] Navigating to category selection after skip');
          context.go('/onboarding/categories');
        }
      }
    } catch (e) {
      print('[ProfileSetup] Error during skip: $e');
      if (mounted) {
        context.go('/onboarding/categories');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: ResponsiveUtils.padding(context, horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                  Text(
                    'Complete Your Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveUtils.fontSize(context, 28),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Add your details to personalize your experience',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.padding(context, horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                      
                      // Avatar
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: ResponsiveUtils.iconSize(context, 120),
                              height: ResponsiveUtils.iconSize(context, 120),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                image: _avatarFile != null
                                    ? DecorationImage(
                                        image: FileImage(_avatarFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : _avatarUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(_avatarUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: _avatarFile == null && _avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: ResponsiveUtils.iconSize(context, 60),
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number (Optional)',
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Address Selection
                      GestureDetector(
                        onTap: _selectAddress,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedAddress == null
                                          ? 'Add Default Address (Optional)'
                                          : _selectedAddressLabel ?? 'Address',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedAddress == null
                                            ? Colors.grey[600]
                                            : Colors.grey[900],
                                      ),
                                    ),
                                    if (_selectedAddress != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedAddress!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _skip,
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
