import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../viewmodels/verification_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_otp_inputs.dart';
import '../../../../core/utils/app_colors.dart';
import 'new_password_screen.dart';

class VerificationScreen extends StatefulWidget {
  static const routeName = '/verify-otp';
  final String email;
  const VerificationScreen({super.key, this.email = ''});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _otp = '';
  int _secondsLeft = 0;
  Timer? _timer;
  void _startCooldown([int seconds = 30]) {
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
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<VerificationViewModel>(),
      child: Consumer<VerificationViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.brandRed), onPressed: () => context.pop()),
            backgroundColor: Theme.of(context).cardColor,
            elevation: 0,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.brandRed, size: 36),
                  const SizedBox(height: 12),
                  Text('Enter your verification code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  CustomOtpInputs(onCompleted: (code) {
                    _otp = code;
                  }),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _secondsLeft > 0
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await s.Supabase.instance.client.auth.resend(
                                  type: s.OtpType.recovery,
                                  email: email,
                                  emailRedirectTo: kIsWeb
                                      ? Uri.base.toString()
                                      : 'io.supabase.flutter://login-callback/',
                                );
                                _startCooldown();
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('OTP resent'),
                                    backgroundColor: AppColors.primaryAccent));
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text('Resend failed: ${e.toString()}'),
                                    backgroundColor: AppColors.brandRed));
                              }
                            },
                      child: Text(
                        _secondsLeft > 0
                            ? 'Resend OTP (${_secondsLeft}s)'
                            : 'Resend OTP',
                        style: const TextStyle(color: Color(0xFF0099A6), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DiamondButton(
                      loading: vm.loading,
                      onTap: () async {
                        if (_otp.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP must be 6 digits'), backgroundColor: AppColors.brandRed));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);
                        final ok = await vm.submit(email, _otp);
                        if (!mounted) return;
                        if (ok) {
                          router.go(NewPasswordScreen.routeName, extra: email);
                        } else {
                          final msg = vm.error ?? 'Wrong/Expired OTP';
                          messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.brandRed));
                        }
                      },
                      icon: Icons.check,
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
}

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
            color: AppColors.brandRed,
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
