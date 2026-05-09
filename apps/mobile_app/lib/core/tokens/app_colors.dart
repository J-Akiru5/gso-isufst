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

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_hod':
      case 'pending_gso':
      case 'submitted':
        return statusPending;
      case 'hod_approved':
      case 'gso_approved':
      case 'received_gso':
        return statusInProgress;
      case 'assigned':
      case 'in_progress':
      case 'released':
      case 'in_use':
        return secondary;
      case 'completed':
      case 'verified':
      case 'inspected':
      case 'returned':
        return statusCompleted;
      case 'hod_rejected':
      case 'gso_rejected':
      case 'cancelled':
        return statusRejected;
      case 'overdue':
        return statusUrgent;
      case 'closed':
        return statusClosed;
      default:
        return neutral500;
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          surface: AppColors.neutral50,
          onSurface: AppColors.neutral900,
          surfaceContainerHighest: AppColors.neutral100,
          error: AppColors.statusRejected,
        ),
        scaffoldBackgroundColor: AppColors.neutral100,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.neutral200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.neutral200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.neutral400,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          onPrimary: AppColors.primary,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          surface: AppColors.neutral900,
          onSurface: AppColors.neutral100,
          surfaceContainerHighest: AppColors.neutral800,
          error: AppColors.statusRejected,
        ),
        scaffoldBackgroundColor: AppColors.neutral950,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.neutral900,
          foregroundColor: AppColors.primaryLight,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryLight,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.neutral800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.neutral700, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.neutral800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.neutral700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.neutral700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          hintStyle: const TextStyle(color: AppColors.neutral500),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.neutral900,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.neutral500,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}
