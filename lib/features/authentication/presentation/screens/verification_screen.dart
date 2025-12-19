import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../viewmodels/verification_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_otp_inputs.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<VerificationViewModel>(),
      child: Consumer<VerificationViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: () => context.pop()),
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
                   Icon(Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.primary, size: 36),
                  const SizedBox(height: 12),
                  Text(l10n.enterVerificationCode,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
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
                              final primaryColor = Theme.of(context).colorScheme.primary;
                              final errorColor = Theme.of(context).colorScheme.error;
                              try {
                                await s.Supabase.instance.client.auth.resend(
                                  type: widget.forSignup
                                      ? s.OtpType.signup
                                      : s.OtpType.recovery,
                                  email: email,
                                  emailRedirectTo: kIsWeb
                                      ? Uri.base.toString()
                                      : 'io.supabase.flutter://login-callback/',
                                );
                                _startCooldown();
                                messenger.showSnackBar(SnackBar(
                                    content: Text(l10n.otpResent),
                                    backgroundColor: primaryColor));
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(
                                    content:
                                        Text(l10n.resendFailed(e.toString())),
                                    backgroundColor: errorColor));
                              }
                            },
                      child: Text(
                        _secondsLeft > 0
                            ? l10n.resendOtpTimer(_secondsLeft)
                            : l10n.resendOtp,
                        style: const TextStyle(
                            color: Color(0xFF0099A6),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DiamondButton(
                      loading: vm.loading,
                      onTap: () async {
                        if (_otp.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(l10n.codeRequired),
                                  backgroundColor: Theme.of(context).colorScheme.error));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);
                        final errorColor = Theme.of(context).colorScheme.error;
                        
                        final ok = widget.forSignup
                            ? await vm.submitSignup(email, _otp)
                            : await vm.submitRecovery(email, _otp);
                        if (!mounted) return;
                        if (ok) {
                          if (widget.forSignup) {
                            router.go('/home');
                          } else {
                            router.go(NewPasswordScreen.routeName,
                                extra: email);
                          }
                        } else {
                          final msg = vm.error ?? l10n.wrongOtp;
                          messenger.showSnackBar(SnackBar(
                              content: Text(msg),
                              backgroundColor: errorColor));
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
  const _DiamondButton(
      {required this.loading, required this.onTap, required this.icon});

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
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
