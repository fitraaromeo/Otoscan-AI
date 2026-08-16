import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens — matched to OtoScan Web globals.css ──────────────────────
class AppColors {
  // --- DARK THEME PALETTE (primary — only theme used) ---
  // Backgrounds (--bg-*)
  static const Color darkBackground  = Color(0xFF070C18); // --bg-base
  static const Color darkSurface     = Color(0xFF0C1221); // --bg-surface
  static const Color darkSurfaceCard = Color(0xFF101929); // --bg-card
  static const Color darkCard2       = Color(0xFF16213D); // --bg-card-2
  static const Color darkElevated    = Color(0xFF1A2A47); // --bg-elevated
  static const Color darkSidebar     = Color(0xFF080E1C); // --bg-sidebar
  static const Color darkTopBar      = Color(0xFF080E1C); // --bg-topbar (opaque)

  // Borders
  static const Color darkBorderDivider = Color(0xFF12192B); // --border (rgba white 7% on bg-base)
  static const Color darkBorderLight   = Color(0xFF0C1221); // --border-light (rgba white 4%)
  static const Color darkBorderAccent  = Color(0xFF3D3FA0); // --border-accent (indigo 35%)

  // Accent — Indigo to Violet (--accent-*)
  static const Color darkPrimaryAccent = Color(0xFF6366F1); // --accent
  static const Color darkAccentLight   = Color(0xFF818CF8); // --accent-light
  static const Color darkAccentDark    = Color(0xFF4F46E5); // --accent-dark
  static const Color darkAccent2       = Color(0xFF8B5CF6); // --accent-2

  // Text (--text-*)
  static const Color darkTextPrimary   = Color(0xFFF0F4FF); // --text-1
  static const Color darkTextSecondary = Color(0xFF8896B3); // --text-2
  static const Color darkTextMuted     = Color(0xFF4D5F7C); // --text-3

  // Status & Severity Colors (unchanged — same in web & mobile)
  static const Color success   = Color(0xFF10B981); // --success
  static const Color warning   = Color(0xFFF59E0B); // --warning
  static const Color danger    = Color(0xFFEF4444); // --danger
  static const Color info      = Color(0xFF06B6D4); // --info

  static const Color darkStatusFailed = Color(0xFFEF4444);
  static const Color darkStatusSuccess = Color(0xFF10B981);

  static const Color successBg = Color(0x1F10B981); // --success-bg
  static const Color warningBg = Color(0x1FF59E0B); // --warning-bg
  static const Color dangerBg  = Color(0x1FEF4444); // --danger-bg
  static const Color infoBg    = Color(0x1F06B6D4); // --info-bg

  // --- LIGHT THEME PALETTE (kept for reference but not used) ---
  static const Color lightBackground      = Color(0xFFF8FAFC);
  static const Color lightSurface         = Color(0xFFFFFFFF);
  static const Color lightTextPrimary     = Color(0xFF0F172A);
  static const Color lightTextSecondary   = Color(0xFF64748B);
  static const Color lightPrimaryAccent   = Color(0xFF334155);
  static const Color lightSecondaryAccent = Color(0xFF94A3B8);

  // Common Brand Aliases (mapped to dark/web palette)
  static const Color primary        = Color(0xFF6366F1); // --accent
  static const Color secondary      = Color(0xFF8896B3); // --text-2
  static const Color accent         = Color(0xFF818CF8); // --accent-light
  static const Color background     = Color(0xFF070C18); // --bg-base
  static const Color surface        = Color(0xFF0C1221); // --bg-surface
  static const Color textPrimary    = Color(0xFFF0F4FF); // --text-1
  static const Color textSecondary  = Color(0xFF8896B3); // --text-2
  static const Color damageHighlight = Color(0xFFEF4444); // --danger

  // Legacy Compatibility Aliases
  static const Color lightPrimary   = Color(0xFF6366F1);
  static const Color lightSecondary = Color(0xFF8896B3);
  static const Color darkPrimary    = Color(0xFF818CF8); // --accent-light
  static const Color darkSecondary  = Color(0xFF4D5F7C); // --text-3

  // Extended Palette (aligned with web accent)
  static const Color neonCyan    = Color(0xFF06B6D4); // --info
  static const Color neonPink    = Color(0xFFF43F5E);
  static const Color neonOrange  = Color(0xFFFB923C);
  static const Color neonPurple  = Color(0xFF8B5CF6); // --accent-2
  static const Color neonGreen   = Color(0xFF10B981); // --success
  static const Color neonYellow  = Color(0xFFF59E0B); // --warning
  static const Color vividAmber  = Color(0xFFF59E0B); // --warning
  static const Color steelBlue   = Color(0xFF6366F1); // --accent
  static const Color deepNavy    = Color(0xFF0C1221); // --bg-surface
  static const Color electricBlue = Color(0xFF4F46E5); // --accent-dark
  static const Color coralRed    = Color(0xFFEF4444); // --danger
  static const Color coolGrey    = Color(0xFF16213D); // --bg-card-2
  static const Color pureWhite   = Color(0xFFFFFFFF);

  // Brand Gradients (Indigo → Violet, matching --gradient)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Kept for backward compatibility — now point to indigo/violet
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient steelBlueGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
class AppTheme {
  // Dark mode only — lightTheme removed


  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: AppColors.darkPrimaryAccent,
      scaffoldBackgroundColor: AppColors.darkBackground, // --bg-base #070C18
      cardColor: AppColors.darkSurfaceCard,              // --bg-card #101929
      dividerColor: AppColors.darkBorderDivider,         // --border rgba-white-7%
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimaryAccent,            // --accent #6366F1
        secondary: AppColors.darkAccent2,                // --accent-2 #8B5CF6
        surface: AppColors.darkSurface,                  // --bg-surface #0C1221
        onSurface: AppColors.darkTextPrimary,            // --text-1 #F0F4FF
        primaryContainer: AppColors.darkCard2,           // --bg-card-2 #16213D
        secondaryContainer: AppColors.darkElevated,      // --bg-elevated #1A2A47
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,       // --bg-base #070C18
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceCard,                // --bg-card #101929
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorderDivider, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard2,            // --bg-card-2 #16213D
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorderAccent, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,               // --bg-surface #0C1221
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorderDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorderDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkPrimaryAccent, width: 2), // --accent
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary),            // --text-2
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryAccent,  // --accent #6366F1
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimaryAccent,    // --accent #6366F1
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,          // --bg-surface #0C1221
        indicatorColor: AppColors.darkPrimaryAccent.withAlpha(50),
        labelTextStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkAccentLight); // --accent-light #818CF8
          }
          return const IconThemeData(color: AppColors.darkTextSecondary); // --text-2 #8896B3
        }),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge:  GoogleFonts.inter(color: AppColors.darkTextPrimary,   fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: AppColors.darkTextPrimary,   fontWeight: FontWeight.bold),
        headlineMedium:GoogleFonts.inter(color: AppColors.darkTextPrimary,   fontWeight: FontWeight.bold),
        titleLarge:    GoogleFonts.inter(color: AppColors.darkTextPrimary,   fontWeight: FontWeight.w600),
        titleMedium:   GoogleFonts.inter(color: AppColors.darkTextPrimary,   fontWeight: FontWeight.w600),
        bodyLarge:     GoogleFonts.inter(color: AppColors.darkTextPrimary),
        bodyMedium:    GoogleFonts.inter(color: AppColors.darkTextPrimary),
        bodySmall:     GoogleFonts.inter(color: AppColors.darkTextSecondary), // --text-2 #8896B3
      ),
    );
  }
}
