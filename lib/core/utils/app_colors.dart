// import 'package:flutter/material.dart';

// /// Centralized color constants for the entire application
// class AppColors {
//   // Primary Color Palette (RED-based as per design)
//   static const Color richNavy = Color(0xFF08314A);
//   static const Color deepTeal = Color(0xFF005F7B);
//   static const Color tealAqua = Color(0xFF00A0A9);
//   static const Color aquaCyan = Color(0xFF04E4D8);
//   static const Color mintAqua = Color(0xFF7FEDD9);

//   // Theme Specific Colors — RED primary and gradient (dark red / soft red)
//   static const Color primary = Color(0xFF2E7D32);
//   static const Color primaryDark = Color(0xFF1B5E20);
//   static const Color primarySoft = Color(0xFF66BB6A);
//   static const Color primaryGreen = primary;

//   // Base Colors
//   static const Color white = Color(0xFFFFFFFF);
//   static const Color offWhite = Color(0xFFFAF9F6);
//   static const Color black = Color(0xFF000000);
//   static const Color transparent = Colors.transparent;

//   // Background Colors
//   static const Color backgroundLight = Color(0xFFF0F0F0);
//   static const Color backgroundDark = Color(0xFF121212);
//   static const Color surfaceDark = Color(0xFF1E1E1E);
//   static const Color surfaceLight = white;

//   // Input Fields
//   static const Color inputFillLight = Color(0xFFF3F1EB); // Creamy
//   static const Color inputFillDark = Color(0xFF2C2C2C);
//   static const Color inputFillDarker = Color(0xFF1E1E1E);

//   // Semantic Colors (aligned with RED primary)
//   static const Color primaryAccent = primary;
//   static const Color secondaryAccent = primaryDark;
//   static const Color darkText = richNavy;
//   static const Color lightText = white;
//   static const Color lightBackground = backgroundLight;

//   // Status Colors
//   static const Color error = Color(0xFFE53935); // Red 600
//   static const Color success = Color(0xFF43A047); // Green 600
//   static const Color warning = Color(0xFFFB8C00); // Orange 600
//   static const Color info = Color(0xFF1E88E5); // Blue 600
//   static const Color rating = Colors.amber;
//   static const Color grey = Colors.grey;
//   static const Color red = Color(0xFFE53935);
//   static const Color orange = Color(0xFFFB8C00);
//   static const Color green = Color(0xFF43A047);

//   // Search Background
//   static const Color searchBackground = Color(0xFFF3F4F6);

//   // Brand Color (unified with primary red)
//   static const Color brandRed = primary;

//   // Divider
//   static const Color dividerDark = Colors.white12;
//   static const Color dividerLight = Colors.black12;
// }






import 'package:flutter/material.dart';

/// Centralized color constants for the entire application
/// Based on Kathir design system with vibrant lime green primary
class AppColors {
  // Primary Color Palette - Kathir Green Theme
  static const Color primary = Color(0xFF1B7E62);        // Vibrant lime green
  static const Color primaryDark = Color(0xFF0FB847);    // Darker green for pressed states
  static const Color primarySoft = Color(0xFF7FEDD9);    // Soft green for highlights
  static const Color primaryGreen = primary;

  // Legacy colors (kept for backward compatibility)
  static const Color richNavy = Color(0xFF08314A);
  static const Color deepTeal = Color(0xFF005F7B);
  static const Color tealAqua = Color(0xFF00A0A9);
  static const Color aquaCyan = Color(0xFF04E4D8);
  static const Color mintAqua = Color(0xFF7FEDD9);

  // Base Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF6F8F6);       // Kathir off-white
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Background Colors - Kathir Theme
  static const Color backgroundLight = Color(0xFFF6F8F6); // Kathir light background
  static const Color backgroundDark = Color(0xFF102216);  // Kathir dark background
  static const Color surfaceLight = white;
  static const Color surfaceDark = Color(0xFF1A2C20);     // Kathir dark surface

  // Card Colors
  static const Color cardLight = white;
  static const Color cardDark = Color(0xFF1A2C20);

  // Text Colors - Kathir Theme
  static const Color textMain = Color(0xFF0D1B12);        // Main text in light mode
  static const Color textMuted = Color(0xFF4C9A66);       // Muted/secondary text
  static const Color textMutedDark = Color(0xFF8ABFA0);   // Muted text in dark mode

  // Input Fields
  static const Color inputFillLight = Color(0xFFFFFFFF);
  static const Color inputFillDark = Color(0xFF1A2E22);
  static const Color inputFillDarker = Color(0xFF1E1E1E);
  static const Color inputBorderLight = Color(0xFFCFE7D7);
  static const Color inputBorderDark = Color(0xFF2A4535);

  // Semantic Colors
  static const Color primaryAccent = primary;
  static const Color secondaryAccent = primaryDark;
  static const Color darkText = textMain;
  static const Color lightText = white;
  static const Color lightBackground = backgroundLight;

  // Status Colors
  static const Color error = Color(0xFFE53935);           // Red 600
  static const Color success = Color(0xFF43A047);         // Green 600
  static const Color warning = Color(0xFFFB8C00);         // Orange 600
  static const Color info = Color(0xFF1E88E5);            // Blue 600
  static const Color rating = Colors.amber;
  static const Color grey = Colors.grey;

  // Search Background
  static const Color searchBackground = Color(0xFFF3F4F6);

  // Brand Color
  static const Color brandGreen = primary;
  static const Color brandRed = primary; // Legacy alias

  // Divider
  static const Color dividerDark = Colors.white12;
  static const Color dividerLight = Colors.black12;
}