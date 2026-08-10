import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // --- LIGHT THEME PALETTE ---
  static const Color lightBackground = Color(0xFFF8FAFC); // Off-White Slate
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightTextPrimary = Color(0xFF0F172A); // Dark Slate
  static const Color lightTextSecondary = Color(0xFF64748B); // Muted Slate
  static const Color lightPrimaryAccent = Color(0xFF334155); // Soft Slate Navy (CTA, Header)
  static const Color lightSecondaryAccent = Color(0xFF94A3B8); // Subtle Blue-Grey (Border, Divider)

  // --- DARK THEME PALETTE ---
  static const Color darkBackground = Color(0xFF0F172A); // Deep Charcoal Slate
  static const Color darkSurface = Color(0xFF1E293B); // Elevator Charcoal
  static const Color darkSurfaceCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Soft White
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Dimmed Grey
  static const Color darkPrimaryAccent = Color(0xFF475569); // Soft Steel Blue
  static const Color darkBorderDivider = Color(0xFF334155); // Subtle Line Dark

  // Common Brand Aliases
  static const Color primary = Color(0xFF0284C7);
  static const Color secondary = Color(0xFF64748B);
  static const Color accent = Color(0xFF38BDF8);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color damageHighlight = Color(0xFFEF4444);

  // Status & Severity Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF334155);

  // Legacy Compatibility Aliases
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFF64748B);
  static const Color darkPrimary = Color(0xFF38BDF8);
  static const Color darkSecondary = Color(0xFF475569);

  static const Color neonCyan = Color(0xFF38BDF8);
  static const Color neonPink = Color(0xFFF43F5E);
  static const Color neonOrange = Color(0xFFFB923C);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonGreen = Color(0xFF34D399);
  static const Color neonYellow = Color(0xFFFACC15);
  static const Color vividAmber = Color(0xFFF59E0B);
  static const Color steelBlue = Color(0xFF38BDF8);
  static const Color deepNavy = Color(0xFF1E293B);
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color coralRed = Color(0xFFEF4444);
  static const Color coolGrey = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Brand Gradients
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
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
    colors: [Color(0xFF334155), Color(0xFF475569)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient steelBlueGradient = LinearGradient(
    colors: [Color(0xFF334155), Color(0xFF475569)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  // LIGHT THEME CONFIGURATION (Inter Font Family)
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: AppColors.lightPrimaryAccent,
      scaffoldBackgroundColor: AppColors.lightBackground, // Off-White Slate #F8FAFC
      cardColor: AppColors.lightSurface, // Pure White #FFFFFF
      dividerColor: AppColors.lightSecondaryAccent, // Subtle Blue-Grey #94A3B8
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimaryAccent, // Soft Slate Navy #334155
        secondary: AppColors.lightSecondaryAccent,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary, // Dark Slate #0F172A
        primaryContainer: Color(0xFFE2E8F0),
        secondaryContainer: Color(0xFFF1F5F9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightPrimaryAccent, // Soft Slate Navy Header
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface, // Pure White Card
        elevation: 1,
        shadowColor: Colors.black.withAlpha(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightSecondaryAccent, width: 0.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.lightSecondaryAccent, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightSecondaryAccent), // Subtle Blue-Grey
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightSecondaryAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightPrimaryAccent, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimaryAccent, // Soft Slate Navy CTA
          foregroundColor: Colors.white,
          elevation: 1,
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
        backgroundColor: AppColors.lightPrimaryAccent,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.lightPrimaryAccent.withAlpha(35),
        labelTextStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.lightPrimaryAccent);
          }
          return const IconThemeData(color: AppColors.lightSecondaryAccent);
        }),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: AppColors.lightTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: AppColors.lightTextPrimary),
        bodyMedium: GoogleFonts.inter(color: AppColors.lightTextPrimary),
        bodySmall: GoogleFonts.inter(color: AppColors.lightTextSecondary), // Muted Slate #64748B
      ),
    );
  }

  // DARK THEME CONFIGURATION (Inter Font Family)
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: AppColors.darkPrimaryAccent,
      scaffoldBackgroundColor: AppColors.darkBackground, // Deep Charcoal Slate #0F172A
      cardColor: AppColors.darkSurface, // Elevator Charcoal #1E293B
      dividerColor: AppColors.darkBorderDivider, // Subtle Line Dark #334155
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimaryAccent, // Soft Steel Blue #475569
        secondary: AppColors.darkTextSecondary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary, // Soft White #F1F5F9
        primaryContainer: Color(0xFF1E293B),
        secondaryContainer: Color(0xFF334155),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground, // Deep Charcoal Slate Header
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
        color: AppColors.darkSurface, // Elevator Charcoal #1E293B
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorderDivider, width: 1), // Subtle Line Dark #334155
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.darkBorderDivider, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
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
          borderSide: const BorderSide(color: AppColors.darkPrimaryAccent, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryAccent, // Soft Steel Blue #475569
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
        backgroundColor: AppColors.darkPrimaryAccent,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.darkPrimaryAccent.withAlpha(50),
        labelTextStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkTextPrimary);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary);
        }),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: AppColors.darkTextPrimary),
        bodyMedium: GoogleFonts.inter(color: AppColors.darkTextPrimary),
        bodySmall: GoogleFonts.inter(color: AppColors.darkTextSecondary), // Dimmed Grey #94A3B8
      ),
    );
  }
}
