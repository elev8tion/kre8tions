import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KRE8TIONS IDE - Futuristic Glass Morphism Theme
/// Inspired by advanced AI-powered development environments with vibrant KRE8TIONS branding

class Kre8tionsColors {
  // Linear-inspired Dark Theme - Professional & Futuristic

  // 🎨 Core Background Colors (true dark, no gradients)
  static const background = Color(0xFF0D0E11);        // Deep charcoal background
  static const surface = Color(0xFF16171B);           // Panel/card surface
  static const surfaceElevated = Color(0xFF1C1D22);   // Elevated panels
  static const border = Color(0xFF26272B);            // Subtle borders
  static const borderHover = Color(0xFF2E2F34);       // Hover state borders

  // 💬 Text Colors (high contrast, professional)
  static const textPrimary = Color(0xFFE6E7E9);       // Primary text
  static const textSecondary = Color(0xFF9AA0A6);     // Secondary text
  static const textTertiary = Color(0xFF6B7280);      // Tertiary text
  static const textDisabled = Color(0xFF4B5563);      // Disabled text

  // ✨ Neon Accent Colors (Linear-style bright accents)
  static const accentBlue = Color(0xFF5E9CFF);        // Primary action blue (kept as is - Linear's signature)
  static const accentPurple = Color(0xFFB57EFF);      // Bright purple accent
  static const accentCyan = Color(0xFF00E5D0);        // Neon cyan/teal
  static const accentPink = Color(0xFFFF4DA6);        // Neon pink
  static const accentGreen = Color(0xFF00F5A0);       // Neon green (new)

  // 🔮 Glass Morphism Colors
  static const glassPrimary = Color(0x1A5E9CFF);      // Glass effect with accent blue

  // 🎯 Semantic Colors
  static const success = Color(0xFF10B981);           // Success green
  static const warning = Color(0xFFF59E0B);           // Warning amber
  static const error = Color(0xFFEF4444);             // Error red
  static const info = Color(0xFF3B82F6);              // Info blue

  // 💻 Code Editor Colors (VS Code inspired)
  static const codeBackground = Color(0xFF0D0E11);    // Editor background
  static const codeSurface = Color(0xFF16171B);       // Panel surfaces
  static const codeSelection = Color(0xFF264F78);     // Selection highlight
  static const codeBorder = Color(0xFF26272B);        // Subtle borders
  static const codeLineNumbers = Color(0xFF6B7280);   // Line number gray
  static const codeComment = Color(0xFF6B7280);       // Comment color
  static const codeActiveLineBackground = Color(0xFF1C1D22); // Active line
}

class LightModeColors {
  // Linear-style light theme (for future support)
  static const lightPrimary = Kre8tionsColors.accentBlue;
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFF0F4FF);
  static const lightOnPrimaryContainer = Color(0xFF1E3A8A);
  static const lightSecondary = Kre8tionsColors.accentPurple;
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Kre8tionsColors.success;
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Kre8tionsColors.error;
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFEE2E2);
  static const lightOnErrorContainer = Color(0xFF991B1B);
  static const lightInversePrimary = Kre8tionsColors.accentBlue;
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF0F0F0F);
  static const lightAppBarBackground = Color(0xFFFFFFFF);
  static const lightCodeBackground = Color(0xFFFAFAFA);
  static const lightCodeBorder = Color(0xFFE5E7EB);
}

class DarkModeColors {
  // Linear-inspired dark theme - clean, professional, no gradients
  static const darkPrimary = Kre8tionsColors.accentBlue;
  static const darkOnPrimary = Kre8tionsColors.background;
  static const darkPrimaryContainer = Kre8tionsColors.surface;
  static const darkOnPrimaryContainer = Kre8tionsColors.accentBlue;
  static const darkSecondary = Kre8tionsColors.accentPurple;
  static const darkOnSecondary = Kre8tionsColors.background;
  static const darkTertiary = Kre8tionsColors.accentCyan;
  static const darkOnTertiary = Kre8tionsColors.background;
  static const darkError = Kre8tionsColors.error;
  static const darkOnError = Kre8tionsColors.textPrimary;
  static const darkErrorContainer = Color(0xFF2D1515);
  static const darkOnErrorContainer = Kre8tionsColors.error;
  static const darkInversePrimary = Kre8tionsColors.accentBlue;
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Kre8tionsColors.surface;
  static const darkOnSurface = Kre8tionsColors.textPrimary;
  static const darkAppBarBackground = Kre8tionsColors.background;
  static const darkCodeBackground = Kre8tionsColors.codeBackground;
  static const darkCodeBorder = Kre8tionsColors.codeBorder;
}

class LinearStyleHelper {
  /// Creates a Linear-style flat container (no gradients)
  static BoxDecoration flatContainer({
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Color? borderColor,
    List<BoxShadow>? shadows,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Kre8tionsColors.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      border: borderColor != null
        ? Border.all(color: borderColor, width: 1)
        : Border.all(color: Kre8tionsColors.border, width: 1),
      boxShadow: shadows ?? (elevated ? LinearStyleShadows.elevated : null),
    );
  }

  /// Creates a subtle accent glow (minimal)
  static List<BoxShadow> subtleGlow(Color color, {double intensity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.15 * intensity),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ];
  }

  /// Creates a flat panel decoration
  static BoxDecoration panelDecoration({
    bool isDark = true,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: isDark
        ? (elevated ? Kre8tionsColors.surfaceElevated : Kre8tionsColors.surface)
        : Colors.white,
      border: Border.all(
        color: isDark ? Kre8tionsColors.border : const Color(0xFFE5E7EB),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: elevated ? LinearStyleShadows.elevated : null,
    );
  }

  /// Creates a flat editor backdrop
  static BoxDecoration editorBackdrop({bool isDark = true}) {
    return BoxDecoration(
      color: isDark ? Kre8tionsColors.codeBackground : Colors.white,
      border: Border.all(
        color: isDark ? Kre8tionsColors.codeBorder : const Color(0xFFE5E7EB),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    );
  }
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Kre8tionsColors.accentBlue,
    brightness: Brightness.light,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    primary: LightModeColors.lightPrimary,
    error: LightModeColors.lightError,
  ),
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnPrimaryContainer,
    elevation: 0,
    shadowColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.white.withValues(alpha: 0.9),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: LightModeColors.lightPrimary,
      foregroundColor: Colors.white,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      color: LightModeColors.lightOnSurface,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    // Primary - use subtle gray, NOT blue
    primary: Color(0xFF9AA0A6),  // Muted gray for primary (Linear style)
    onPrimary: Color(0xFF0D0E11),
    primaryContainer: Color(0xFF26272B),
    onPrimaryContainer: Color(0xFFE6E7E9),
    // Secondary - neon purple accent
    secondary: Color(0xFFB57EFF),
    onSecondary: Color(0xFF0D0E11),
    secondaryContainer: Color(0xFF2D1F3D),
    onSecondaryContainer: Color(0xFFB57EFF),
    // Tertiary - neon cyan accent
    tertiary: Color(0xFF00E5D0),
    onTertiary: Color(0xFF0D0E11),
    tertiaryContainer: Color(0xFF1A2F2C),
    onTertiaryContainer: Color(0xFF00E5D0),
    // Error
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF2D1515),
    onErrorContainer: Color(0xFFEF4444),
    // Surface - true dark background
    surface: Color(0xFF16171B),
    onSurface: Color(0xFFE6E7E9),
    surfaceContainerHighest: Color(0xFF1C1D22),
    onSurfaceVariant: Color(0xFF9AA0A6),
    // Outline
    outline: Color(0xFF26272B),
    outlineVariant: Color(0xFF2E2F34),
    // Shadow & scrim
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    // Inverse
    inverseSurface: Color(0xFFE6E7E9),
    onInverseSurface: Color(0xFF0D0E11),
    inversePrimary: Color(0xFF5E9CFF),
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Kre8tionsColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: Kre8tionsColors.surface,
    foregroundColor: Kre8tionsColors.textPrimary,
    elevation: 0,
    shadowColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    color: Kre8tionsColors.surface,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Kre8tionsColors.surfaceElevated,  // Subtle elevated surface - not bright blue
      foregroundColor: Kre8tionsColors.textPrimary,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
      color: Kre8tionsColors.textPrimary,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
      color: Kre8tionsColors.textPrimary,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      color: Kre8tionsColors.textPrimary,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
      color: Kre8tionsColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
      color: Kre8tionsColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      color: Kre8tionsColors.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
      color: Kre8tionsColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: Kre8tionsColors.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: Kre8tionsColors.textPrimary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: Kre8tionsColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: Kre8tionsColors.textPrimary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: Kre8tionsColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      color: Kre8tionsColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      color: Kre8tionsColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      color: Kre8tionsColors.textPrimary,
    ),
  ),
);

/// Performance optimizations for theme data
extension ThemeDataOptimizations on ThemeData {
  /// Cached decoration for panels to avoid recreation
  static final Map<String, BoxDecoration> _decorationCache = {};

  BoxDecoration getCachedPanelDecoration({
    required String key,
    required bool isDark,
    bool elevated = false,
  }) {
    final cacheKey = '${key}_${isDark}_$elevated';
    return _decorationCache.putIfAbsent(cacheKey, () {
      return LinearStyleHelper.panelDecoration(
        isDark: isDark,
        elevated: elevated,
      );
    });
  }

  /// Clear decoration cache to prevent memory leaks
  static void clearDecorationCache() {
    _decorationCache.clear();
  }
}

/// Enhanced theme animations and transitions  
class Kre8tionsAnimations {
  static const Duration fastTransition = Duration(milliseconds: 150);
  static const Duration normalTransition = Duration(milliseconds: 250);
  static const Duration slowTransition = Duration(milliseconds: 400);
  
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  
  /// Optimized fade transition for panels
  static Widget fadeTransition(Widget child, bool visible) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: fastTransition,
      curve: easeInOutCubic,
      child: child,
    );
  }
  
  /// Smooth panel resize animation
  static Widget resizeTransition(Widget child, double width) {
    return AnimatedContainer(
      width: width,
      duration: normalTransition,
      curve: easeInOutCubic,
      child: child,
    );
  }
  
  /// Subtle focus animation effects
  static Widget focusAnimation(Widget child, bool focused) {
    return AnimatedContainer(
      duration: fastTransition,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focused
            ? Kre8tionsColors.accentBlue.withValues(alpha: 0.5)
            : Kre8tionsColors.border,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Linear-style shadow definitions (minimal, flat design)
class LinearStyleShadows {
  // Minimal elevation shadow for floating elements
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Subtle focus shadow
  static List<BoxShadow> focused(Color accentColor) => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: Offset(0, 0),
    ),
  ];

  // Hover state shadow
  static const List<BoxShadow> hover = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}