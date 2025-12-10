import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/verification_viewmodel.dart';
import '../../../../di/global_injection/app_locator.dart';
import '../../../_shared/widgets/custom_otp_inputs.dart';
import '../../../_shared/widgets/custom_red_button.dart';
import '../../../../core/utils/app_colors.dart';

class VerificationScreen extends StatefulWidget {
  static const routeName = '/verify-otp';
  final String email;
  const VerificationScreen({super.key, this.email = ''});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _otp = '';
  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    return ChangeNotifierProvider(
      create: (_) => AppLocator.I.get<VerificationViewModel>(),
      child: Consumer<VerificationViewModel>(
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
                const Icon(Icons.shield_outlined, color: AppColors.brandRed, size: 36),
                const SizedBox(height: 12),
                const Text('Enter your verification code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                CustomOtpInputs(onCompleted: (code) {
                  _otp = code;
                }),
                const SizedBox(height: 24),
                CustomRedButton(
                  onPressed: vm.loading
                      ? null
                      : () async {
                          if (_otp.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP must be 6 digits'), backgroundColor: AppColors.brandRed));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          final ok = await vm.submit(email, _otp);
                          if (!mounted) return;
                          if (ok) {
                            router.go('/new-password', extra: email);
                          } else {
                            final msg = vm.error ?? 'Wrong/Expired OTP';
                            messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.brandRed));
                          }
                        },
                  child: vm.loading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
