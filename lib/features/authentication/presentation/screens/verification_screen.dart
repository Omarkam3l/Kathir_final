import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/verification_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../../core/utils/app_colors.dart';
import 'new_password_screen.dart';

class VerificationScreen extends StatefulWidget {
  static const routeName = '/verify-otp';
  final String email;
  final bool forSignup;
  const VerificationScreen(
      {super.key, this.email = '', this.forSignup = false});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const int _otpLength = 8;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());
  int _secondsLeft = 0;
  Timer? _timer;

  void _startCooldown([int seconds = 45]) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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
    final email = widget.email;

    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<VerificationViewModel>(),
      child: Consumer<VerificationViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textPrimary, size: 24),
              onPressed: () => context.pop(),
            ),
            backgroundColor: bg,
            elevation: 0,
            title: Text('Verification',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset,
                          size: 32, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify OTP',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the 8-digit code we sent to your registered email address.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: textMuted, height: 1.5),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _maskEmail(email),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_otpLength, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          width: 34,
                          height: 48,
                          child: TextFormField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2)),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (v) {
                              if (v.length == 1 && i < _otpLength - 1) {
                                _focusNodes[i + 1].requestFocus();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text("Didn't receive the code?",
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: textMuted)),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _secondsLeft > 0
                              ? null
                              : () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    await s.Supabase.instance.client.auth
                                        .resend(
                                      type: widget.forSignup
                                          ? s.OtpType.signup
                                          : s.OtpType.recovery,
                                      email: email,
                                      emailRedirectTo: kIsWeb
                                          ? Uri.base.toString()
                                          : 'io.supabase.flutter://login-callback/',
                                    );
                                    _startCooldown();
                                    messenger.showSnackBar(const SnackBar(
                                        content: Text('OTP resent',
                                            style: TextStyle(
                                                color: AppColors.white)),
                                        backgroundColor: AppColors.primary));
                                  } catch (e) {
                                    messenger.showSnackBar(SnackBar(
                                        content: Text(
                                            'Resend failed: ${e.toString()}',
                                            style: const TextStyle(
                                                color: AppColors.white)),
                                        backgroundColor: AppColors.error));
                                  }
                                },
                          icon: Icon(Icons.refresh,
                              size: 18,
                              color: _secondsLeft > 0
                                  ? textMuted
                                  : AppColors.primary),
                          label: Text(
                            _secondsLeft > 0
                                ? 'Resend in ${_secondsLeft}s'
                                : 'Resend Code',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    _secondsLeft > 0 ? textMuted : textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final code = _otp.trim();
                              if (code.length != _otpLength) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Code required'),
                                        backgroundColor: AppColors.error));
                                return;
                              }
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);
                              final ok = widget.forSignup
                                  ? await vm.submitSignup(email, code)
                                  : await vm.submitRecovery(email, code);
                              if (!mounted) return;
                              if (ok) {
                                if (widget.forSignup) {
                                  router.go('/home');
                                } else {
                                  router.go(NewPasswordScreen.routeName,
                                      extra: email);
                                }
                              } else {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        vm.error ?? 'Wrong/Expired OTP',
                                        style: const TextStyle(
                                            color: AppColors.white)),
                                    backgroundColor: AppColors.error));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
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
                          : Text('Verify',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Back to Sign In',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
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

  String _maskEmail(String e) {
    if (e.length < 5) return e;
    final i = e.indexOf('@');
    if (i < 0) return e;
    if (i <= 2) return '***@${e.substring(i + 1)}';
    return '${e.substring(0, 2)}****@${e.substring(i + 1)}';
  }
}
