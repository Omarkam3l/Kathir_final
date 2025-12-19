import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_text_field.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<ForgotPasswordViewModel>(),
      child: Consumer<ForgotPasswordViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary), onPressed: () => context.pop()),
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
