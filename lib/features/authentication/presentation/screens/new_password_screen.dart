import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/new_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../../core/utils/app_colors.dart';
import '../blocs/auth_provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class NewPasswordScreen extends StatefulWidget {
  static const routeName = '/new-password';
  final String email;
  const NewPasswordScreen({super.key, this.email = ''});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.white : AppColors.darkText;
    final textMuted = AppColors.grey;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<NewPasswordViewModel>(),
      child: Consumer<NewPasswordViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textPrimary, size: 24),
              onPressed: () => context.pop(),
            ),
            backgroundColor: bg,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_reset, size: 36, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create your new password',
                    style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a strong password with at least 8 characters.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  _buildField('Password', 'Enter new password', _pass, _obscurePass, () => setState(() => _obscurePass = !_obscurePass), textPrimary, textMuted, surface, border),
                  const SizedBox(height: 16),
                  _buildField('Confirm password', 'Confirm new password', _confirm, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm), textPrimary, textMuted, surface, border),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final p = _pass.text.trim();
                              final c = _confirm.text.trim();
                              if (p.length < 8) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: AppColors.error));
                                return;
                              }
                              if (p != c) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error));
                                return;
                              }
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);
                              final ok = await vm.submit(p);
                              if (!mounted) return;
                              if (ok) {
                                messenger.showSnackBar(const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.primary));
                                try {
                                  Provider.of<AuthProvider>(context, listen: false).endPasswordRecovery();
                                } catch (_) {}
                                try {
                                  Provider.of<AuthViewModel>(context, listen: false).setMode(true);
                                } catch (_) {}
                                router.go('/auth');
                              } else {
                                messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'Weak password'), backgroundColor: AppColors.error));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.darkText,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                        disabledForegroundColor: AppColors.darkText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: vm.loading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkText)))
                          : Text('Update Password', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController c, bool obscure, VoidCallback onToggle, Color textPrimary, Color textMuted, Color surface, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          obscureText: obscure,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: textMuted),
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.primary, size: 22),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
