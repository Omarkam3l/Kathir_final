import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../authentication/presentation/blocs/auth_provider.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

class UserCategorySelectionScreen extends StatefulWidget {
  static const routeName = '/onboarding/categories';
  
  const UserCategorySelectionScreen({super.key});

  @override
  State<UserCategorySelectionScreen> createState() => _UserCategorySelectionScreenState();
}

class _UserCategorySelectionScreenState extends State<UserCategorySelectionScreen> {
  final _supabase = Supabase.instance.client;
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;

  // Available meal categories
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Meals',
      'description': 'Ready-to-eat meals',
      'icon': Icons.restaurant,
    },
    {
      'name': 'Bakery',
      'description': 'Fresh bread & pastries',
      'icon': Icons.bakery_dining,
    },
    {
      'name': 'Meat & Poultry',
      'description': 'Fresh meat products',
      'icon': Icons.set_meal,
    },
    {
      'name': 'Seafood',
      'description': 'Fresh fish & seafood',
      'icon': Icons.water,
    },
    {
      'name': 'Vegetables',
      'description': 'Fresh produce',
      'icon': Icons.eco,
    },
    {
      'name': 'Desserts',
      'description': 'Sweet treats',
      'icon': Icons.cake,
    },
    {
      'name': 'Groceries',
      'description': 'Pantry essentials',
      'icon': Icons.shopping_basket,
    },
  ];

  Future<void> _savePreferences() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('[CategorySelection] Error: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('[CategorySelection] Saving preferences for user: $userId');
      print('[CategorySelection] Selected categories: ${_selectedCategories.toList()}');

      // Delete existing preferences first to avoid duplicates
      try {
        await _supabase
            .from('user_category_preferences')
            .delete()
            .eq('user_id', userId);
        print('[CategorySelection] Cleared existing preferences');
      } catch (deleteError) {
        print('[CategorySelection] Warning: Could not clear existing preferences: $deleteError');
      }

      // Insert selected categories using upsert to handle duplicates
      for (final category in _selectedCategories) {
        try {
          await _supabase.from('user_category_preferences').upsert({
            'user_id': userId,
            'category': category,
            'notifications_enabled': true,
          }, onConflict: 'user_id,category');
          print('[CategorySelection] Saved preference: $category');
        } catch (categoryError) {
          print('[CategorySelection] Error saving category $category: $categoryError');
          // Continue with other categories even if one fails
        }
      }

      // Mark onboarding as completed
      try {
        await _supabase
            .from('profiles')
            .update({'is_onboarding_completed': true})
            .eq('id', userId);
        print('[CategorySelection] Marked onboarding as completed');
        
        // Refresh auth provider to update cached user profile
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshUser();
          print('[CategorySelection] Refreshed auth provider');
        }
      } catch (profileError) {
        print('[CategorySelection] Error updating profile: $profileError');
        rethrow;
      }

      if (mounted) {
        print('[CategorySelection] Navigating to home screen');
        // Navigate to home screen for regular users
        context.go('/home');
      }
    } catch (e) {
      print('[CategorySelection] Fatal error in _savePreferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save preferences. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _savePreferences,
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
                    'Choose Your Favorites',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveUtils.fontSize(context, 28),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Select meal categories you\'re interested in to get personalized notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    '${_selectedCategories.length} selected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Categories List (Horizontal Chips)
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.padding(context, horizontal: 24),
                child: Wrap(
                  spacing: ResponsiveUtils.spacing(context, 12),
                  runSpacing: ResponsiveUtils.spacing(context, 12),
                  children: _categories.map((category) {
                    final isSelected = _selectedCategories.contains(category['name']);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(category['name']);
                          } else {
                            _selectedCategories.add(category['name']);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category['icon'],
                              size: ResponsiveUtils.iconSize(context, 20),
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            Text(
                              category['name'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
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
                      onPressed: _isLoading ? null : _savePreferences,
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
                    onPressed: _isLoading
                        ? null
                        : () async {
                            print('[CategorySelection] Skip button pressed');
                            setState(() => _isLoading = true);
                            
                            // Skip onboarding
                            try {
                              final userId = _supabase.auth.currentUser?.id;
                              if (userId != null) {
                                print('[CategorySelection] Marking onboarding as completed for skip');
                                await _supabase
                                    .from('profiles')
                                    .update({'is_onboarding_completed': true})
                                    .eq('id', userId);
                                print('[CategorySelection] Onboarding marked as completed');
                                
                                // Refresh auth provider to update cached user profile
                                if (mounted) {
                                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                  await authProvider.refreshUser();
                                  print('[CategorySelection] Refreshed auth provider after skip');
                                }
                                
                                if (mounted) {
                                  print('[CategorySelection] Navigating to home after skip');
                                  context.go('/home');
                                }
                              } else {
                                print('[CategorySelection] Error: No user ID found for skip');
                              }
                            } catch (e) {
                              print('[CategorySelection] Error during skip: $e');
                              // Still navigate even if update fails
                              if (mounted) {
                                print('[CategorySelection] Navigating to home despite error');
                                context.go('/home');
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
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
