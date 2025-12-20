import 'package:flutter/material.dart';

/// Centralized color constants for the entire application
class AppColors {
  // Primary Color Palette
  static const Color richNavy = Color(0xFF08314A);
  static const Color deepTeal = Color(0xFF005F7B);
  static const Color tealAqua = Color(0xFF00A0A9);
  static const Color aquaCyan = Color(0xFF04E4D8);
  static const Color mintAqua = Color(0xFF7FEDD9);

  // Theme Specific Colors
  static const Color primary = Color(0xFF4DD0E1); // Sky Blue/Cyan
  static const Color primaryDark = Color(0xFF0099A6); // Darker cyan

  // Base Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAF9F6);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Background Colors
  static const Color backgroundLight = Color(0xFFF0F0F0);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceLight = white;

  // Input Fields
  static const Color inputFillLight = Color(0xFFF3F1EB); // Creamy
  static const Color inputFillDark = Color(0xFF2C2C2C);
  static const Color inputFillDarker = Color(0xFF1E1E1E);

  // Semantic Colors
  static const Color primaryAccent = tealAqua;
  static const Color secondaryAccent = deepTeal;
  static const Color darkText = richNavy;
  static const Color lightText = white;
  static const Color lightBackground = backgroundLight;

  // Status Colors
  static const Color error = Color(0xFFE53935); // Red 600
  static const Color success = Color(0xFF43A047); // Green 600
  static const Color warning = Color(0xFFFB8C00); // Orange 600
  static const Color info = Color(0xFF1E88E5); // Blue 600
  static const Color rating = Colors.amber;
  static const Color grey = Colors.grey;

  // Search Background
  static const Color searchBackground = Color(0xFFF3F4F6);

  // Brand Color
  static const Color brandRed = Color(0xFFE60023);

  // Divider
  static const Color dividerDark = Colors.white12;
  static const Color dividerLight = Colors.black12;
}
