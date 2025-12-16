import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';

class CustomOtpInputs extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;
  const CustomOtpInputs({super.key, this.length = 6, required this.onCompleted});

  @override
  State<CustomOtpInputs> createState() => _CustomOtpInputsState();
}

class _CustomOtpInputsState extends State<CustomOtpInputs> {
  final TextEditingController _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.brandRed, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (val) {
        widget.onCompleted(val);
      },
    );
  }
}
