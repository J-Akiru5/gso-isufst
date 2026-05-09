// Flutter Design Tokens — Auto-synced from tokens.json
// Import: import 'package:mobile_app/core/tokens/app_colors.dart';

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF003d62);
  static const Color primaryLight = Color(0xFFd0e7f5);
  static const Color primaryDark = Color(0xFF002744);
  static const Color secondary = Color(0xFF2a80af);
  static const Color secondaryDark = Color(0xFF1d6a94);
  static const Color institutional = Color(0xFF142d55);
  static const Color vivid = Color(0xFF0352bc);
  static const Color brandDark = Color(0xFF0f0d0e);

  // Status Colors
  static const Color statusPending = Color(0xFFf59e0b);
  static const Color statusInProgress = Color(0xFF2a80af);
  static const Color statusCompleted = Color(0xFF16a34a);
  static const Color statusRejected = Color(0xFFdc2626);
  static const Color statusUrgent = Color(0xFF9333ea);
  static const Color statusClosed = Color(0xFF64748b);

  // Neutral Palette
  static const Color neutral50 = Color(0xFFf8fafc);
  static const Color neutral100 = Color(0xFFf1f5f9);
  static const Color neutral200 = Color(0xFFe2e8f0);
  static const Color neutral300 = Color(0xFFcbd5e1);
  static const Color neutral400 = Color(0xFF94a3b8);
  static const Color neutral500 = Color(0xFF64748b);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1e293b);
  static const Color neutral900 = Color(0xFF0f172a);
  static const Color neutral950 = Color(0xFF020617);

  // Priority Colors
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return statusUrgent;
      case 'high':
        return statusRejected;
      case 'medium':
        return statusPending;
      case 'low':
        return statusCompleted;
      default:
        return neutral500;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.neutral50,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.neutral100,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          secondary: AppColors.secondary,
          surface: AppColors.neutral900,
          onPrimary: AppColors.primary,
          onSecondary: Colors.white,
        ),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.neutral950,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.neutral900,
          foregroundColor: AppColors.primaryLight,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: AppColors.neutral800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
