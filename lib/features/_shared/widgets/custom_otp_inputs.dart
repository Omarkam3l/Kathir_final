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
  late List<TextEditingController> _controllers;
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 44,
          child: TextField(
            controller: _controllers[i],
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              counterText: '',
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
              if (val.isNotEmpty && i < widget.length - 1) {
                FocusScope.of(context).nextFocus();
              }
              final code = _controllers.map((c) => c.text).join();
              if (code.length == widget.length) widget.onCompleted(code);
            },
          ),
        );
      }),
    );
  }
}
