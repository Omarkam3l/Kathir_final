import 'package:flutter/material.dart';
import 'package:kathir_final/core/utils/app_colors.dart';

class CustomInputField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final Color? fillColor;

  const CustomInputField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.isPassword = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOptional = hintText.toLowerCase().contains('optional');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = fillColor ??
        (isDark ? AppColors.inputFillDark : AppColors.inputFillLight);
    final border = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      validator: (v) {
        if (isOptional) return null;
        if ((v ?? '').trim().isEmpty) return 'Required';
        return null;
      },
      style: TextStyle(color: isDark ? AppColors.white : AppColors.darkText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}
