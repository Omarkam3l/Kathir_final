import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/new_password_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_input_field.dart';
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
                  const Icon(Icons.password, color: AppColors.brandRed, size: 36),
                  const SizedBox(height: 12),
                  Text('Create your new password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  CustomInputField(hintText: 'Password', controller: _pass, isPassword: true),
                  const SizedBox(height: 12),
                  CustomInputField(hintText: 'Confirm password', controller: _confirm, isPassword: true),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DiamondButton(
                      loading: vm.loading,
                      onTap: () async {
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
                          // Ensure recovery redirect flag is cleared and login mode is active
                          try {
                            Provider.of<AuthProvider>(context, listen: false).endPasswordRecovery();
                          } catch (_) {}
                          try {
                            Provider.of<AuthViewModel>(context, listen: false).setMode(true);
                          } catch (_) {}
                          router.go('/auth');
                        } else {
                          messenger.showSnackBar(SnackBar(content: Text(vm.error ?? 'Weak password'), backgroundColor: AppColors.brandRed));
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
