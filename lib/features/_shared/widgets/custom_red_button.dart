import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';

class CustomRedButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  const CustomRedButton({super.key, this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final fn = onPressed;
        if (fn != null) {
          fn();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandRed,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(56, 56),
      ),
      child: child,
    );
  }
}
