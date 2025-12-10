import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/new_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_input_field.dart';
import '../../../_shared/widgets/custom_red_button.dart';
import '../../../../core/utils/app_colors.dart';

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

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<NewPasswordViewModel>(),
      child: Consumer<NewPasswordViewModel>(
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
                const Icon(Icons.password, color: AppColors.brandRed, size: 36),
                const SizedBox(height: 12),
                const Text('Create your new password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                CustomInputField(hintText: 'Password', controller: _pass, isPassword: true),
                const SizedBox(height: 12),
                CustomInputField(hintText: 'Confirm password', controller: _confirm, isPassword: true),
                const SizedBox(height: 24),
                CustomRedButton(
                  onPressed: vm.loading
                      ? null
                      : () async {
                          final p = _pass.text.trim();
                          final c = _confirm.text.trim();
                          if (p.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: AppColors.brandRed));
                            return;
                          }
                          if (p != c) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.brandRed));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          final ok = await vm.submit(p);
                          if (!mounted) return;
                          if (ok) {
                            messenger.showSnackBar(const SnackBar(content: Text('Password updated'), backgroundColor: Colors.green));
                            router.go('/auth');
                          } else {
                            messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'Weak password'), backgroundColor: AppColors.brandRed));
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
