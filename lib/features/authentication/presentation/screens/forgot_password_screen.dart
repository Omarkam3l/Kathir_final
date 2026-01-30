import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.white : AppColors.darkText;
    const textMuted = AppColors.grey;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<ForgotPasswordViewModel>(),
      child: Consumer<ForgotPasswordViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            leading: IconButton(
              icon:
                  Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 22),
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
                  Text(
                    'Forgot Password?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
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
