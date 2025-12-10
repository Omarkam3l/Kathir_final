import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_text_field.dart';
import '../../../_shared/widgets/custom_red_button.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:go_router/go_router.dart';

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
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, color: AppColors.brandRed, size: 36),
                const SizedBox(height: 12),
                const Text('Forgot Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Enter your registered email or phone.'),
                const SizedBox(height: 16),
                CustomTextField(controller: _email, hint: 'Email or phone', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                CustomRedButton(
                  onPressed: vm.loading
                      ? null
                      : () async {
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
                            router.go('/verify', extra: value);
                          } else {
                            messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'Network error'), backgroundColor: AppColors.brandRed));
                          }
                        },
                  child: vm.loading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
