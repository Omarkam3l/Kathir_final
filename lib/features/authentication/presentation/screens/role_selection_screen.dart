import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/core/utils/user_role.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/role_selection_viewmodel.dart';

class RoleSelectionScreen extends StatefulWidget {
  static const routeName = '/role';
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selected = UserRole.user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.white : AppColors.darkText;
    final textMuted = AppColors.grey;

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final roleVm = RoleSelectionViewModel(authViewModel: authVm);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        backgroundColor: bg,
        elevation: 0,
        title: Text('Select Role', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your role to continue.',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ...UserRole.values.where((r) => r != UserRole.admin).map((r) {
              final isSelected = _selected == r;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _selected = r),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.15) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(_iconForRole(r), color: isSelected ? AppColors.primary : textMuted, size: 24),
                          const SizedBox(width: 14),
                          Text(
                            r.name[0].toUpperCase() + r.name.substring(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  roleVm.selectRole(_selected);
                  GoRouter.of(context).go('/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Confirm', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForRole(UserRole r) {
    switch (r) {
      case UserRole.user:
        return Icons.person_outline;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.ngo:
        return Icons.handshake_outlined;
      case UserRole.restaurant:
        return Icons.restaurant_outlined;
    }
  }
}
