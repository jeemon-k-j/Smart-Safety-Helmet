import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Safety-themed Material 3 palette.
abstract final class AppColors {
  static const Color brand = Color(0xFF0A2F4A);
  static const Color page = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color safe = Color(0xFF1B7A4A);
  static const Color safeSoft = Color(0xFFE6F5EE);
  static const Color warning = Color(0xFFC45C12);
  static const Color warningSoft = Color(0xFFFFF1E6);
  static const Color danger = Color(0xFFB71C1C);
  static const Color dangerSoft = Color(0xFFFDECEC);
  static const Color unknown = Color(0xFF5F6B7A);
  static const Color unknownSoft = Color(0xFFEEF1F4);
  static const Color accent = Color(0xFF0E6B8A);
}

abstract final class AppMetrics {
  static const double page = 20;
  static const double gap = 14;
  static const double radius = 20;
  static const double radiusSm = 14;
}

/// Visual severity for status surfaces (not connection telemetry).
enum SafetyTone { safe, warning, danger, unknown }

abstract final class AppTheme {
  static ThemeData get light {
    const seed = Color(0xFF0A2F4A);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: AppColors.brand,
      secondary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.surface,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.page,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brand.withValues(alpha: 0.12),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.brand : AppColors.unknown,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.brand : AppColors.unknown,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static Color toneColor(SafetyTone tone) => switch (tone) {
        SafetyTone.safe => AppColors.safe,
        SafetyTone.warning => AppColors.warning,
        SafetyTone.danger => AppColors.danger,
        SafetyTone.unknown => AppColors.unknown,
      };

  static Color toneSoft(SafetyTone tone) => switch (tone) {
        SafetyTone.safe => AppColors.safeSoft,
        SafetyTone.warning => AppColors.warningSoft,
        SafetyTone.danger => AppColors.dangerSoft,
        SafetyTone.unknown => AppColors.unknownSoft,
      };
}
