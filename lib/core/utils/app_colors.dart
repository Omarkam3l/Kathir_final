import 'package:flutter/material.dart';

/// Centralized color constants — Light background + Blue primary
class AppColors {
  // ── Primary — Blue ────────────────────────────────────────────
  /// ⭐ PRIMARY COLOR — Change this to change buttons, icons, selected states
  static const Color primary     = Color(0xFF1B70DF); // ← Change this color
  static const Color primaryDark = Color(0xFFFFF8F0); // Deeper blue
  static const Color primarySoft = Color(0xFF7AAAF9); // Light blue

  // Legacy aliases
  static const Color primaryGreen = primary;
  static const Color richNavy     = Color(0xFF1A3A6B);
  static const Color deepTeal     = Color(0xFF1E4D8C);
  static const Color tealAqua     = Color(0xFF2563EB);
  static const Color aquaCyan     = Color(0xFF3B7BF6);
  static const Color mintAqua     = Color(0xFFBFD7FF);

  // ── Base ─────────────────────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color offWhite    = Color(0xFFF4F6FA);
  static const Color black       = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ── Backgrounds — Light ───────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF0F4FF); // Very light blue-white
  static const Color backgroundDark  = Color(0xFFE8EEFF); // Slightly deeper
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color surfaceDark     = Color(0xFFEDF1FF);

  // ── Cards ────────────────────────────────────────────────────
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark  = Color(0xFFEDF1FF);

  // ── Glass / Nav ──────────────────────────────────────────────
  ///  GLASS CARD COLORS — Ultra transparent glassmorphism effect (شفاف تماماً)
  static final Color glassCardBg = Colors.white.withValues(alpha: 0.15); // ← خلفية شفافة جداً (كان 0.10)
  static final Color glassCardBorder = Colors.white.withValues(alpha: 0.20); // ← بوردر خفيف (كان 0.10)
  static final Color glassCardBgLight = Colors.white.withValues(alpha: 0.10); // ← خلفية أفتح شوية
  static final Color glassCardBgDark = Colors.white.withValues(alpha: 0.10); // ← خلفية أغمق شوية
  
  // Legacy glass colors (kept for compatibility)
  static const Color glassNavBg     = Color(0xFFFFFFFF);
  static const Color glassNavBorder = Color(0xFFDDE5FF);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textMain      = Color(0xFF0F1B3D); // Deep navy text
  static const Color textMuted     = Color(0xFF6B7A99); // Muted blue-gray
  static const Color textMutedDark = Color(0xFF9AAAC4);

  // ── Input Fields ─────────────────────────────────────────────
  static const Color inputFillLight   = Color(0xFFFFFFFF);
  static const Color inputFillDark    = Color(0xFFEDF1FF);
  static const Color inputFillDarker  = Color(0xFFE0E8FF);
  static const Color inputBorderLight = Color(0xFFD0DCFF);
  static const Color inputBorderDark  = Color(0xFFB8CAFF);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color primaryAccent   = primary;
  static const Color secondaryAccent = primaryDark;
  static const Color darkText        = textMain;
  static const Color lightText       = white;
  static const Color lightBackground = backgroundLight;

  // ── Status ───────────────────────────────────────────────────
  static const Color error   = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF3B7BF6);
  static const Color rating  = Color(0xFFF59E0B);
  static const Color grey    = Color(0xFF9AAAC4);

  // ── Misc ─────────────────────────────────────────────────────
  static const Color searchBackground = Color(0xFFF0F4FF);
  static const Color brandGreen       = primary;
  static const Color brandRed         = primary;
  static const Color dividerDark      = Color(0x1A3B7BF6);
  static const Color dividerLight     = Color(0x1A3B7BF6);

  // ── Gradients ────────────────────────────────────────────────
  /// Base gradient colors (main background)
  static const Color bgBaseColor1 = Color(0xFFFFFFFF); 
  static const Color bgBaseColor2 = Color(0xFFFFFFFF);
  
  /// Overlay 1 colors (radial glow effect)
  static const Color bgOverlay1Color = Color(0xFFFFFFFF); 
  static const double bgOverlay1Opacity = 0.5; 
  
  /// Overlay 2 colors (random scattered effect)
  static const Color bgOverlay2Color1 = Color(0xFFFFFFFF); 
  static const Color bgOverlay2Color2 = Color(0xFFFFFFFF);  
  static const double bgOverlay2Opacity1 = 0.15; // ← Light spots strength
  static const double bgOverlay2Opacity2 = 0.1; // ← Dark spots strength

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFade8f4), // ← TOP-LEFT color (change this)
      Color(0xFFcaf0f8), // ← BOTTOM-RIGHT color (change this)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// ⭐⭐⭐ COMPLEX BACKGROUND BUILDER — Simple 2-color gradient
  /// Returns a simple gradient background with 2 colors only
  static Widget buildComplexBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFCCECF6),    
            Color(0xFFFFFFFF),   
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4B2E2B), Color(0xFFC08552)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF3B7BF6), Color(0xFF1A5FD4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    colors: [Color(0xFF7AAAF9), Color(0xFF3B7BF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientSoft = LinearGradient(
    colors: [Color(0xFF3B7BF6), Color(0xFF7AAAF9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A3A6B), Color(0xFF1E4D8C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}