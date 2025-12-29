import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_text_field.dart';
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
    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<ForgotPasswordViewModel>(),
      child: Consumer<ForgotPasswordViewModel>(
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
                  const Icon(Icons.lock_outline, color: AppColors.brandRed, size: 36),
                  const SizedBox(height: 12),
                  Text('Forgot Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  Text('Enter your registered email or phone.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 16),
                  CustomTextField(controller: _email, hint: 'Email or phone', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DiamondButton(
                      loading: vm.loading,
                      onTap: () async {
                        final value = _email.text.trim();
                        if (value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email must not be empty'), backgroundColor: AppColors.brandRed));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);
                        final ok = await vm.submit(value);
                        if (!mounted) return;
                        if (ok) {
                          messenger.showSnackBar(const SnackBar(content: Text('Verification code sent'), backgroundColor: Colors.green));
                          router.push(VerificationScreen.routeName, extra: value);
                        } else {
                          messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'Network error'), backgroundColor: AppColors.brandRed));
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
