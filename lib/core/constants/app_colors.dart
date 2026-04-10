import 'package:flutter/material.dart';

/// App color palette matching the UI design system.
/// Light mode uses warm grays (#f9f9f7 base), dark mode uses surface-dim approach.
class AppColors {
  AppColors._();

  // ===========================================================================
  // Light Mode Colors
  // ===========================================================================

  // Surface tones (warm gray palette)
  static const Color surface = Color(0xFFf9f9f7);
  static const Color surfaceContainerLow = Color(0xFFf4f4f2);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color surfaceContainerHigh = Color(0xFFe8e8e6);
  static const Color surfaceContainerHighest = Color(0xFFe2e3e1);
  static const Color surfaceDim = Color(0xFFdadad8);
  static const Color surfaceVariant = Color(0xFFe2e3e1);

  // Primary (deep blue)
  static const Color primary = Color(0xFF00497d);
  static const Color primaryContainer = Color(0xFF0061a4);
  static const Color primaryFixed = Color(0xFFd1e4ff);
  static const Color primaryFixedDim = Color(0xFF9fcaff);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color onPrimaryFixed = Color(0xFF001d36);
  static const Color onPrimaryFixedVariant = Color(0xFF00497d);
  static const Color onPrimaryContainer = Color(0xFFc0dbff);
  static const Color surfaceTint = Color(0xFF0061a4);

  // Secondary (steel blue)
  static const Color secondary = Color(0xFF4a607c);
  static const Color secondaryFixed = Color(0xFFd1e4ff);
  static const Color secondaryFixedDim = Color(0xFFb1c8e8);
  static const Color secondaryContainer = Color(0xFFc8dfff);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color onSecondaryFixed = Color(0xFF021d35);
  static const Color onSecondaryFixedVariant = Color(0xFF324863);
  static const Color onSecondaryContainer = Color(0xFF4c627e);

  // Tertiary (burnt orange)
  static const Color tertiary = Color(0xFF713700);
  static const Color tertiaryFixed = Color(0xFFffdcc6);
  static const Color tertiaryFixedDim = Color(0xFFffb784);
  static const Color tertiaryContainer = Color(0xFF944a00);
  static const Color onTertiary = Color(0xFFffffff);
  static const Color onTertiaryFixed = Color(0xFF301400);
  static const Color onTertiaryFixedVariant = Color(0xFF713700);
  static const Color onTertiaryContainer = Color(0xFFffceaf);

  // Background & OnBackground
  static const Color background = Color(0xFFf9f9f7);
  static const Color onBackground = Color(0xFF1a1c1b);
  static const Color onSurface = Color(0xFF1a1c1b);
  static const Color onSurfaceVariant = Color(0xFF414750);

  // Outline
  static const Color outline = Color(0xFF717782);
  static const Color outlineVariant = Color(0xFFc1c7d2);

  // Error
  static const Color error = Color(0xFFba1a1a);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color onError = Color(0xFFffffff);
  static const Color onErrorContainer = Color(0xFF93000a);

  // Inverse
  static const Color inverseSurface = Color(0xFF2f3130);
  static const Color inverseOnSurface = Color(0xFFf1f1ef);
  static const Color inversePrimary = Color(0xFF9fcaff);

  // ===========================================================================
  // Dark Mode Colors
  // ===========================================================================

  // Surface tones - dark mode uses surface-dim approach (NOT pure black)
  static const Color darkSurface = Color(0xFF1a1c1b);
  static const Color darkSurfaceContainerLow = Color(0xFF2f3130);
  static const Color darkSurfaceContainerLowest = Color(0xFF3a3b3a);
  static const Color darkSurfaceContainerHigh = Color(0xFF4a4b4a);
  static const Color darkSurfaceDim = Color(0xFFdadad8); // Used as dimmed overlay

  // Primary (light blue for dark bg)
  static const Color darkPrimary = Color(0xFF9fcaff);
  static const Color darkPrimaryContainer = Color(0xFF00497d);
  static const Color darkOnPrimary = Color(0xFF003258);
  static const Color darkOnPrimaryContainer = Color(0xFFc0dbff);

  // Secondary
  static const Color darkSecondary = Color(0xFFb1c8e8);
  static const Color darkSecondaryContainer = Color(0xFF324863);
  static const Color darkOnSecondary = Color(0xFF324863);
  static const Color darkOnSecondaryContainer = Color(0xFFd1e4ff);

  // Tertiary
  static const Color darkTertiary = Color(0xFFffb784);
  static const Color darkTertiaryContainer = Color(0xFF5a2600);
  static const Color darkOnTertiary = Color(0xFF5a2600);
  static const Color darkOnTertiaryContainer = Color(0xFFffdcc6);

  // Background & OnBackground
  static const Color darkBackground = Color(0xFF1a1c1b);
  static const Color darkOnBackground = Color(0xFFe8e8e6);
  static const Color darkOnSurface = Color(0xFFe8e8e6);
  static const Color darkOnSurfaceVariant = Color(0xFFc4c6cf);

  // Outline
  static const Color darkOutline = Color(0xFF8d9199);
  static const Color darkOutlineVariant = Color(0xFF414750);

  // Error
  static const Color darkError = Color(0xFFffb4ab);
  static const Color darkErrorContainer = Color(0xFF690005);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkOnErrorContainer = Color(0xFFffdad6);

  // Inverse
  static const Color darkInverseSurface = Color(0xFFe8e8e6);
  static const Color darkInverseOnSurface = Color(0xFF2f3130);
  static const Color darkInversePrimary = Color(0xFF0061a4);
}
