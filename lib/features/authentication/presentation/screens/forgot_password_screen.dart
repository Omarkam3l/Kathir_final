import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_text_field.dart';
=======
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../../core/utils/app_colors.dart';
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final l10n = AppLocalizations.of(context)!;
=======
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.white : AppColors.darkText;
    const textMuted = AppColors.grey;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;

>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<ForgotPasswordViewModel>(),
      child: Consumer<ForgotPasswordViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
<<<<<<< HEAD
            leading: IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary), onPressed: () => context.pop()),
            backgroundColor: Theme.of(context).cardColor,
=======
            leading: IconButton(
              icon:
                  Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 22),
              onPressed: () => context.pop(),
            ),
            backgroundColor: bg,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
<<<<<<< HEAD
                  Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 36),
                  const SizedBox(height: 12),
                  Text(l10n.forgotPasswordTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  Text(l10n.forgotPasswordSubtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 16),
                  CustomTextField(controller: _email, hint: l10n.emailLabel, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DiamondButton(
                      loading: vm.loading,
                      onTap: () async {
                        final value = _email.text.trim();
                        if (value.isEmpty || !value.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterValidEmail), backgroundColor: Theme.of(context).colorScheme.error));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);
                        final errorColor = Theme.of(context).colorScheme.error;
                        final ok = await vm.submit(value);
                        if (!mounted) return;
                        if (ok) {
                          try {
                            await Supabase.instance.client.auth.resend(
                              type: OtpType.recovery,
                              email: value,
                              emailRedirectTo: kIsWeb ? Uri.base.toString() : 'io.supabase.flutter://login-callback/',
                            );
                          } catch (_) {}
                          messenger.showSnackBar(SnackBar(content: Text(l10n.checkEmailForCode), backgroundColor: Colors.green));
                          router.go(VerificationScreen.routeName, extra: value);
                        } else {
                          messenger.showSnackBar(SnackBar(content: Text(vm.error ?? l10n.networkError), backgroundColor: errorColor));
                        }
                      },
                      icon: Icons.arrow_forward,
=======
                  const SizedBox(height: 16),
                  Text(
                    'Forgot Password?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Don't worry! It happens. Please enter the email address or phone number associated with your account.",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, color: textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Email Address',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'hello@example.com',
                      hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 15, color: textMuted),
                      prefixIcon: const Icon(Icons.mail_outline,
                          color: AppColors.primary, size: 22),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final value = _email.text.trim();
                              if (value.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Email must not be empty',
                                            style: TextStyle(
                                                color: AppColors.white)),
                                        backgroundColor: AppColors.error));
                                return;
                              }
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);
                              final ok = await vm.submit(value);
                              if (!mounted) return;
                              if (ok) {
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('Verification code sent',
                                        style:
                                            TextStyle(color: AppColors.white)),
                                    backgroundColor: AppColors.primary));
                                router.push(VerificationScreen.routeName,
                                    extra: value);
                              } else {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(vm.error ?? 'Network error',
                                        style: const TextStyle(
                                            color: AppColors.white)),
                                    backgroundColor: AppColors.error));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.6),
                        disabledForegroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: vm.loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white)))
                          : Text('Send Reset Link',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Remember password? ',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, color: textMuted)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text('Login',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco, size: 18, color: textMuted),
                      const SizedBox(width: 6),
                      Text('KATHIR',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textMuted,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
<<<<<<< HEAD

class _DiamondButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final IconData icon;
  const _DiamondButton({required this.loading, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: loading ? const Center(child: CircularProgressIndicator(color: Colors.white)) : Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
=======
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
